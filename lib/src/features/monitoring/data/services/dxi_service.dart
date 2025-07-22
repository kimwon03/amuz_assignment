import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:amuz_assignment/src/core/common/models/monitoring_parser_info_model.dart';
import 'package:amuz_assignment/src/core/constants/app_constant.dart';
import 'package:amuz_assignment/src/core/constants/dxi_constant.dart';
import 'package:amuz_assignment/src/core/common/services/base_socket_client.dart';
import 'package:amuz_assignment/src/core/common/utils/data_parser.dart';
import 'package:amuz_assignment/src/core/common/models/dxi_request_model.dart';
import 'package:amuz_assignment/src/features/connection/data/models/dxi_send_data_model.dart';
import 'package:rxdart/subjects.dart';

class DxiSocketClient {
  bool _initialize = false;

  final BaseSocketClient _socketClient = BaseSocketClient();

  late final Map<String, dynamic> _monitoringRules;
  late final Map<String, dynamic> _monitoringDataInfos;

  final BehaviorSubject<Map<String, dynamic>> _monitoringDataSubject =
      BehaviorSubject.seeded({});

  set _updateMonitoringData(Map<String, dynamic> newData) =>
      _monitoringDataSubject.sink.add(newData);

  Stream<Map<String, dynamic>> get monitoringDataStream =>
      _monitoringDataSubject.stream;

  void initialize() {
    _initialize = true;

    _monitoringRules =
        productSpecification['productDesc']['product_setting']['monitoring'] ??
        {};

    _monitoringDataInfos =
        productSpecification['productDesc']['monitoring'] ?? {};
  }

  void startMonitoring() {
    if (!_initialize) return;

    _socketClient.addListener(_dxiListener);
  }

  void _dxiListener(Uint8List response) {
    final Map<String, dynamic> result = jsonDecode(
      String.fromCharCodes(response),
    );

    final String? cmd = result['cmd'] as String?;

    if (!_isCommmndPingOrPong(cmd ?? '')) {
      appLog.d('Get Socket Response : $result');
    }

    switch (cmd) {
      case Cmd.ping:
        _whenReceviedPing();
        break;
      case Cmd.sendDxiData:
        Map<String, dynamic> data = result['data'];

        _whenReceviedSendDxiData(data);
        break;
    }
  }

  void _whenReceviedPing() {
    final DxiRequestModel dxiRequestModel = DxiRequestModel(
      type: Type.reponse,
      cmd: Cmd.pong,
      data: DxiSendDataModel(),
    );

    _sendRequest(dxiRequestModel);
  }

  void _whenReceviedSendDxiData(Map<String, dynamic> data) {
    String hexString = data['bytes'];

    // if (!_verityCrc(hexString)) return;

    if (hexString.substring(2, 4) == 'FF') {
      _responseMonitoring(hexString);
    }
  }

  void _responseMonitoring(String hexString) {
    Map<String, dynamic> monitoringMap = hexStringToMap(hexString);

    monitoringMap.forEach(
      (key, value) => _setMonitoringData(key, (value as List).cast()),
    );
  }

  void _setMonitoringData(String key, List<String> value) {
    Map<String, dynamic> monitoringData = {};

    List<String> elements = ((_monitoringRules[key]['elements'] ?? []) as List)
        .cast<String>();

    int offset = 0;

    for (String element in elements) {
      Map<String, dynamic> dataInfo = _monitoringDataInfos[element];

      MonitoringParserInfoModel monitoringParserInfo =
          MonitoringParserInfoModel.fromJson(dataInfo);

      List<String> sublist = value.sublist(
        offset,
        offset + monitoringParserInfo.length,
      );

      int parsingValue = hexListToInt(sublist.reversed.toList());

      if (monitoringParserInfo.sign ?? false) {
        parsingValue = parsingValue.toSigned(sublist.length * 4 * 2);
      }

      String result = _generateDataByType(monitoringParserInfo, parsingValue);

      monitoringData['name'] = result;

      offset += monitoringParserInfo.length;
    }

    _updateMonitoringData = monitoringData;
  }

  String _generateDataByType(MonitoringParserInfoModel parser, int data) {
    switch (parser.type) {
      case 'int':
        return parser.deco != null
            ? _calculateByDeco(data, parser.deco!)
            : data.toString();
      case 'bool':
      case 'enum':
        return _convertDataUsingMap(parser.map ?? {}, data);
      case 'various':
        return _convertDataUsingVarious(parser, data);
      default:
        return '';
    }
  }

  String _calculateByDeco(int value, String deco) {
    String decoString = utf8.decode(base64Decode(deco));
    Map<String, dynamic> convertMap = jsonDecode(decoString);
    String calc = convertMap['calc'];

    String operator = calc.substring(1, 2);
    double calValue = double.parse(calc.substring(2));

    if (operator == '*') {
      return (value * calValue).toStringAsFixed(1);
    } else if (operator == '/') {
      return (value / calValue).toStringAsFixed(1);
    } else {
      return value.toString();
    }
  }

  String _convertDataUsingMap(Map<String, dynamic> map, int value) {
    return map[value.toString()];
  }

  String _convertDataUsingVarious(MonitoringParserInfoModel parser, int value) {
    Map<String, dynamic> result = {};

    String valueBinary = value.toRadixString(2).padLeft(parser.length * 8, '0');

    Map<String, dynamic> elements = parser.elements ?? {};

    elements.forEach((key, value) {
      int offset = int.parse(key);

      int reversedOffset = elements.keys.length - 1 - offset;

      if (reversedOffset < 0) return;

      String targetValue = valueBinary[reversedOffset];

      if (targetValue == '1') {
        result.addAll({value['name']: value['map'][targetValue]});
      }
    });

    return jsonEncode(result);
  }

  void _sendRequest(DxiRequestModel dxiRequestModel) {
    if (!_isCommmndPingOrPong(dxiRequestModel.cmd)) {
      appLog.i('send message\n$dxiRequestModel');
    }

    _socketClient.addMessage(
      Message(
        message: jsonEncode(dxiRequestModel.toJson()),
        showLog: !_isCommmndPingOrPong(dxiRequestModel.cmd),
      ),
    );
  }

  bool _verityCrc(String hexString) {
    List<String> hexList = hexStringTohexList(hexString);
    List<int> bytes = hexListToIntList(hexList);

    int originCRC = bytes[bytes.length - 2];
    int recvCRC = generateCrc8Bit(bytes.sublist(0, bytes.length - 2));

    return originCRC == recvCRC;
  }

  bool _isCommmndPingOrPong(String cmd) {
    return cmd == Cmd.ping || cmd == Cmd.pong;
  }
}
