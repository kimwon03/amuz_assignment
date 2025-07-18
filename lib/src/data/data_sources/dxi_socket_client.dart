import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:amuz_assignment/src/core/constants/app_constant.dart';
import 'package:amuz_assignment/src/core/constants/dxi_constant.dart';
import 'package:amuz_assignment/src/core/constants/keys.dart';
import 'package:amuz_assignment/src/core/utils/base_socket_client.dart';
import 'package:amuz_assignment/src/core/utils/data_parser.dart';
import 'package:amuz_assignment/src/data/models/dxi_request_model.dart';
import 'package:amuz_assignment/src/data/models/product_information_model.dart';

class DxiSocketClient {
  bool _initialize = false;

  final BaseSocketClient _socketClient = BaseSocketClient();
  Timer? _sendSet2WayCertReqTimer;
  Timer? _sendSetDxiModeReqTimer;

  late final List<String> _productRules;
  int _sendProductRuleIndex = 0;

  void initialize() {
    _initialize = false;

    _productRules =
        productSpecification['productDesc']['product_setting']['setting']['monitoring_rule'];
  }

  Future<void> connect() async {
    if (!_initialize) return;

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
      data: {'constantConnect': 'Y'},
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

    if (hexString.contains('AA0810B403')) {
      _responseSpecVersion(hexString);
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
        data: {"constantConnect": "N"},
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
        data: {"constantConnect": "Y"},
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

    // 모니터링 중지
    data.add(0xE0);

    data.add(generateCrc8Bit(data));

    data.add(0xBB);

    final DxiRequestModel dxiRequestModel = DxiRequestModel(
      type: Type.dxi,
      cmd: Cmd.sendDxiData,
      data: {'bytes': listToHexString(data), 'constantConnect': 'Y'},
    );

    _sendRequest(dxiRequestModel);
  }

  void _sendProductRule() {
    DxiRequestModel dxiRequestModel = DxiRequestModel(
      type: Type.dxi,
      cmd: Cmd.sendDxiData,
      data: {
        'bytes': _productRules[_sendProductRuleIndex++],
        'constantConnect': 'Y',
      },
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
      data: {'constantConnect': 'N', 'exitAP': exitAP ? 'Y' : 'N'},
    );

    _sendRequest(dxiRequestModel);
  }

  void _responseSpecVersion(String hexString) {
    List<String> hexList = hexStringTohexList(hexString);
    List<int> byteList = hexListToIntList(hexList);

    if (!_verityCrc(
      byteList.sublist(0, byteList.length - 2),
      byteList[byteList.length - 2],
    )) {
      return;
    }

    // Todo: 수신 종료 처리 추가
    if (byteList[5] != 0xF0) return;
  }

  bool _verityCrc(List<int> revData, int originCrc) {
    int revCrc = generateCrc8Bit(revData);

    return revCrc == originCrc;
  }

  bool _isCommmndPingOrPong(String cmd) {
    return cmd == Cmd.ping || cmd == Cmd.pong;
  }
}
