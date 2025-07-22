import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:amuz_assignment/src/core/common/models/monitoring_parser_info_model.dart';
import 'package:amuz_assignment/src/core/constants/app_constant.dart';
import 'package:amuz_assignment/src/core/constants/dxi_constant.dart';
import 'package:amuz_assignment/src/core/constants/keys.dart';
import 'package:amuz_assignment/src/core/common/services/base_socket_client.dart';
import 'package:amuz_assignment/src/core/common/models/connect_state.dart';
import 'package:amuz_assignment/src/core/common/utils/data_parser.dart';
import 'package:amuz_assignment/src/core/common/models/dxi_request_model.dart';
import 'package:amuz_assignment/src/core/common/models/dxi_send_data_model.dart';
import 'package:amuz_assignment/src/core/common/models/product_information_model.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:rxdart/subjects.dart';

class DxiSocketClient {
  bool _initialize = false;

  final BaseSocketClient _socketClient = BaseSocketClient();
  Timer? _sendSet2WayCertReqTimer;
  Timer? _sendSetDxiModeReqTimer;

  final List<String> _productRules = [];
  late final Map<String, dynamic> _monitoringRules;
  late final Map<String, dynamic> _monitoringDataInfos;
  int _sendProductRuleIndex = 0;

  final BehaviorSubject<ConnectionState> _connectionStateSubject =
      BehaviorSubject.seeded(ConnectionState.disconnect);

  set _updateConnectionState(ConnectionState state) =>
      _connectionStateSubject.sink.add(state);

  Stream<ConnectionState> get connectionStateStream =>
      _connectionStateSubject.stream;

  void initialize() {
    _initialize = true;

    Map<String, dynamic> settings =
        productSpecification['productDesc']['product_setting']['setting'];

    settings.forEach((key, value) {
      _productRules.addAll((value as List).cast<String>());
    });

    _monitoringRules =
        productSpecification['productDesc']['product_setting']['monitoring'] ??
        {};

    _monitoringDataInfos =
        productSpecification['productDesc']['monitoring'] ?? {};
  }

  Future<void> connect() async {
    if (!_initialize) return;

    _updateConnectionState = ConnectionState.waiting;

    await serverAuthentication();
  }

  Future<void> serverAuthentication() async {
    await disconnect(releaseDxi: false);

    final bool socketConnectResult = await _socketConnect(
      host,
      port,
      context: _getSecurityContext(
        key: Keys.blackboxKey,
        password: Keys.blackboxPassword,
      ),
    );

    if (!socketConnectResult) return;

    await _socketClient.addListener(_authenticationListener);

    await Future.delayed(Duration(seconds: 1));

    _releaseDxiMode();

    await Future.delayed(Duration(seconds: 1));

    _sendSet2WayCertRequest();
  }

  Future<void> setupDxi() async {
    await disconnect(releaseDxi: false);

    final bool socketConnectResult = await _socketConnect(
      host,
      port,
      context: _getSecurityContext(
        key: Keys.appKey,
        password: Keys.appPassword,
        rootCA: Keys.rootCert,
        serverCert: Keys.appCert,
      ),
    );

    if (!socketConnectResult) return;

    _socketClient.addListener(_dxiListener);

    await Future.delayed(Duration(seconds: 1));

    _sendSetDxiRequest();
  }

  Future<void> disconnect({bool releaseDxi = true, bool exitAP = true}) async {
    _stopSendSet2WayCertReqTimer();
    _stopSendSetDxiModeReqTimer();

    if (releaseDxi) {
      _releaseDxiMode(exitAP: exitAP);
    }

    await _socketClient.disconnect();
  }

  SecurityContext _getSecurityContext({
    required String key,
    String? password,
    String? rootCA,
    String? serverCert,
  }) {
    final SecurityContext securityContext = rootCA != null
        ? SecurityContext(withTrustedRoots: true)
        : SecurityContext.defaultContext;

    final Uint8List privateKeyBytes = base64Decode(key);

    securityContext.usePrivateKeyBytes(privateKeyBytes, password: password);

    if (rootCA != null) {
      final Uint8List rootCABytes = base64Decode(rootCA);

      securityContext.setTrustedCertificatesBytes(rootCABytes);
    }

    if (serverCert != null) {
      final Uint8List serverCertBytes = base64Decode(serverCert);

      securityContext.useCertificateChainBytes(serverCertBytes);
    }

    return securityContext;
  }

  Future<bool> _socketConnect(
    String host,
    int port, {
    SecurityContext? context,
  }) async {
    return _socketClient.connect(
      host,
      port,
      context: context,
      onBadCertificate: (_) => true,
    );
  }

  void _authenticationListener(Uint8List response) {
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
      case Cmd.set2wayCert:
        _whenReceviedSet2WayCert();
        break;
    }
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
      case Cmd.setDxiMode:
        Map<String, dynamic> data = result['data'];

        _whenReceviedSetDxiMode(data);
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

  void _whenReceviedSet2WayCert() async {
    _stopSendSet2WayCertReqTimer();

    await disconnect(releaseDxi: false);

    await Future.delayed(Duration(seconds: 1));

    await setupDxi();
  }

  void _whenReceviedSendDxiData(Map<String, dynamic> data) {
    String hexString = data['bytes'];

    // if (!_verityCrc(hexString)) return;

    if (hexString.contains('AA0810B403')) {
      _responseSpecVersion(hexString);
    } else if (hexString.contains('AA0910B405')) {
      _responseSettingResult(hexString);
    } else if (hexString.contains('AA1310B407')) {
      _responseCompleteResult(hexString);
    } else if (hexString.substring(2, 4) == 'FF') {
      _responseMonitoring(hexString);
    }
  }

  void _whenReceviedSetDxiMode(Map<String, dynamic> data) async {
    _stopSendSetDxiModeReqTimer();

    final ProductInformationModel productInformationModel =
        ProductInformationModel.fromJson(data);

    appLog.i('Get DXi Information : $productInformationModel');

    _sendSpecVersion();
  }

  void _sendSet2WayCertRequest() {
    int sendCount = 0;

    _sendSet2WayCertReqTimer = Timer.periodic(sendRequestDuration, (timer) {
      if (sendCount >= maxSendCount) timer.cancel();

      final DxiRequestModel dxiRequestModel = DxiRequestModel(
        type: Type.request,
        cmd: Cmd.set2wayCert,
        data: DxiSendDataModel(constantConnect: 'N'),
      );

      _sendRequest(dxiRequestModel);

      sendCount++;
    });
  }

  void _sendSetDxiRequest() {
    int sendCount = 0;

    _sendSetDxiModeReqTimer = Timer.periodic(sendRequestDuration, (timer) {
      if (sendCount >= maxSendCount) timer.cancel();

      final DxiRequestModel dxiRequestModel = DxiRequestModel(
        type: Type.request,
        cmd: Cmd.setDxiMode,
        data: DxiSendDataModel(),
      );

      _sendRequest(dxiRequestModel);

      sendCount++;
    });
  }

  void _sendSpecVersion() {
    List<int> data = [0xAA, 0x12, 0xE0, 0xB7, 0x02];

    String? version = productSpecification['specVer'];

    if (version == null) return;

    List<int> versionList = version
        .split('.')
        .map((e) => int.parse(e))
        .toList();

    // 제품 UID
    data.addAll(toHexList(versionList[0], 4));
    // 명세서 Major
    data.addAll(toHexList(versionList[1], 2));
    // 명세서 Minor
    data.addAll(toHexList(versionList[2], 2));
    // 명세서 항목 크기
    data.addAll(toHexList(0, 2));

    // 이전 상태로 모니터링 유지
    data.add(0xF0);

    data.add(generateCrc8Bit(data));

    data.add(0xBB);

    final DxiRequestModel dxiRequestModel = DxiRequestModel(
      type: Type.dxi,
      cmd: Cmd.sendDxiData,
      data: DxiSendDataModel(bytes: listToHexString(data)),
    );

    _sendRequest(dxiRequestModel);
  }

  void _sendProductRule() {
    DxiRequestModel dxiRequestModel = DxiRequestModel(
      type: Type.dxi,
      cmd: Cmd.sendDxiData,
      data: DxiSendDataModel(bytes: _productRules[_sendProductRuleIndex]),
    );

    _sendRequest(dxiRequestModel);
  }

  void _sendComplete() {
    List<int> data = [0xAA, 0x07, 0xE0, 0xB7, 0x06];

    data.add(generateCrc8Bit(data));

    data.add(0xBB);

    final DxiRequestModel dxiRequestModel = DxiRequestModel(
      type: Type.dxi,
      cmd: Cmd.sendDxiData,
      data: DxiSendDataModel(bytes: listToHexString(data)),
    );

    _sendRequest(dxiRequestModel);
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

  void _stopSendSet2WayCertReqTimer() {
    _sendSet2WayCertReqTimer?.cancel();
    _sendSet2WayCertReqTimer = null;
  }

  void _stopSendSetDxiModeReqTimer() {
    _sendSetDxiModeReqTimer?.cancel();
    _sendSetDxiModeReqTimer = null;
  }

  void _releaseDxiMode({final bool exitAP = false}) {
    final DxiRequestModel dxiRequestModel = DxiRequestModel(
      type: Type.dxi,
      cmd: Cmd.releaseDxiMode,
      data: DxiSendDataModel(constantConnect: 'N', exitAP: exitAP ? 'Y' : 'N'),
    );

    _sendRequest(dxiRequestModel);

    if (exitAP) {
      _updateConnectionState = ConnectionState.disconnect;
    }
  }

  void _responseSpecVersion(String hexString) {
    List<String> hexList = hexStringTohexList(hexString);
    List<int> byteList = hexListToIntList(hexList);

    int code = byteList[5];

    // Todo: 예외처리 추가
    switch (code) {
      case 0xE1:
      case 0xE3:
        _sendComplete();
        break;
      case 0xF0:
        _sendProductRuleIndex = 0;

        _sendProductRule();
        break;
    }
  }

  void _responseSettingResult(String hexString) {
    List<String> hexList = hexStringTohexList(hexString);
    List<int> byteList = hexListToIntList(hexList);

    if (byteList[5] == 0xE0) {
      _sendProductRule();
    }

    // Todo: 오류 종료 처리 추가
    switch (byteList[5]) {
      case 0xE0:
        _sendProductRule();
        break;
      case 0xF0:
        _sendProductRuleIndex++;

        if (_sendProductRuleIndex >= _productRules.length) {
          _sendComplete();

          return;
        }

        _sendProductRule();
    }
  }

  void _responseCompleteResult(String hexString) {
    List<String> hexList = hexStringTohexList(hexString);

    List<String> uidList = hexList.sublist(9, 12 + 1).reversed.toList();
    List<String> majorList = hexList.sublist(13, 14 + 1).reversed.toList();
    List<String> minorList = hexList.sublist(15, 16 + 1).reversed.toList();

    int uid = hexListToInt(uidList);
    int major = hexListToInt(majorList);
    int minor = hexListToInt(minorList);

    appLog.d('Get Version From Response : ${uid}.${major}.${minor}');

    if (uid == 0 && major == 0 && minor == 0) {
      appLog.d('Resend Product Rule');

      _sendProductRuleIndex = 0;

      _sendProductRule();

      return;
    }

    _updateConnectionState = ConnectionState.connect;
  }

  void _responseMonitoring(String hexString) {
    Map<String, dynamic> monitoringMap = hexStringToMap(hexString);

    monitoringMap.forEach(
      (key, value) => _updateMonitoringData(key, (value as List).cast()),
    );
  }

  void _updateMonitoringData(String key, List<String> value) {
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

      print('${monitoringParserInfo.name} : $result');

      offset += monitoringParserInfo.length;
    }
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
