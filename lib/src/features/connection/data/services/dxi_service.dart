import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:amuz_assignment/src/core/constants/app_constant.dart';
import 'package:amuz_assignment/src/core/constants/dxi_constant.dart';
import 'package:amuz_assignment/src/core/constants/keys.dart';
import 'package:amuz_assignment/src/core/common/services/base_socket_client.dart';
import 'package:amuz_assignment/src/core/common/models/connect_state.dart';
import 'package:amuz_assignment/src/core/common/utils/data_parser.dart';
import 'package:amuz_assignment/src/core/common/models/dxi_request_model.dart';
import 'package:amuz_assignment/src/features/connection/data/models/dxi_send_data_model.dart';
import 'package:amuz_assignment/src/features/connection/data/models/product_information_model.dart';

class DxiSocketClient {
  bool _initialize = false;

  late final BaseSocketClient _socketClient;
  Timer? _sendSet2WayCertReqTimer;
  Timer? _sendSetDxiModeReqTimer;

  final List<String> _productRules = [];
  int _sendProductRuleIndex = 0;

  Stream<ConnectionState> get connectionStateStream =>
      _socketClient.connectionStateStream;

  DxiSocketClient(BaseSocketClient socketClient) : _socketClient = socketClient;

  void initialize() {
    _initialize = true;

    Map<String, dynamic> settings =
        productSpecification['productDesc']['product_setting']['setting'];

    settings.forEach((key, value) {
      _productRules.addAll((value as List).cast<String>());
    });
  }

  Future<void> connect() async {
    if (!_initialize) return;

    _socketClient.updateConnectionState = ConnectionState.waiting;

    await serverAuthentication();
  }

  Future<void> serverAuthentication() async {
    await disconnect(releaseDxi: false);

    final bool socketConnectResult = await _socketConnect(
      host,
      port,
      context: _getSecurityContext(
        key: Keys.blackboxKey,
        password: blackboxPassword,
      ),
    );

    if (!socketConnectResult) {
      _socketClient.updateConnectionState = ConnectionState.disconnect;

      return;
    }

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
        password: appPassword,
        rootCA: Keys.rootCert,
        serverCert: Keys.appCert,
      ),
    );

    if (!socketConnectResult) {
      _socketClient.updateConnectionState = ConnectionState.disconnect;

      return;
    }

    _socketClient.addListener(_dxiListener);

    await Future.delayed(Duration(seconds: 1));

    _sendSetDxiRequest();
  }

  Future<void> disconnect({bool releaseDxi = true, bool exitAP = true}) async {
    disposeListener();

    if (releaseDxi) {
      _releaseDxiMode(exitAP: exitAP);
    }

    await _socketClient.disconnect();
  }

  Future<void> disposeListener() async {
    _stopSendSetDxiModeReqTimer();
    _stopSendSetDxiModeReqTimer();

    await _socketClient.removeListener();
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
      if (sendCount >= maxSendCount) {
        disconnect(exitAP: false);
      }

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
      if (sendCount >= maxSendCount) {
        timer.cancel();

        disconnect(exitAP: false);
      }

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
      _socketClient.updateConnectionState = ConnectionState.disconnect;
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

    appLog.d('Get Version From Response : $uid.$major.$minor');

    if (uid == 0 && major == 0 && minor == 0) {
      appLog.d('Resend Product Rule');

      _sendProductRuleIndex = 0;

      _sendProductRule();

      return;
    }

    _socketClient.updateConnectionState = ConnectionState.connect;
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
