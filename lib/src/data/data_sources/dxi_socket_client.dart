import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:amuz_assignment/src/core/constants/app_constant.dart';
import 'package:amuz_assignment/src/core/constants/dxi_constant.dart';
import 'package:amuz_assignment/src/core/constants/keys.dart';
import 'package:amuz_assignment/src/core/utils/base_socket_client.dart';
import 'package:amuz_assignment/src/data/models/dxi_request_model.dart';

class DxiSocketClient {
  final BaseSocketClient _socketClient = BaseSocketClient();
  Timer? _sendSet2WayCertReqTimer;
  Timer? _sendSetDxiModeReqTimer;

  Future<void> connect() async {
    await serverAuthentication();
  }

  Future<void> serverAuthentication() async {
    final bool socketConnectResult = await _socketConnect(host, port);

    if (!socketConnectResult) return;

    final SecurityContext securityContext = _getSecurityContext(
      key: Keys.blackboxKey,
    );

    final bool updateSocketSecurity = await _updateSecurity(securityContext);

    if (!updateSocketSecurity) return;

    await _socketClient.addListener(_authenticationListener);

    await Future.delayed(Duration(seconds: 1));

    _sendSet2WayCertRequest();
  }

  Future<void> setupDxi() async {
    final bool socketConnectResult = await _socketClient.connect(host, port);

    if (!socketConnectResult) return;

    final SecurityContext securityContext = _getSecurityContext(
      key: Keys.appKey,
      rootCA: Keys.rootCert,
      serverCert: Keys.appCert,
    );

    final bool updateSocketSecurity = await _updateSecurity(securityContext);

    if (!updateSocketSecurity) return;

    _socketClient.addListener(_dxiListener);

    await Future.delayed(Duration(seconds: 1));

    _sendSetDxiRequest();
  }

  SecurityContext _getSecurityContext({
    required String key,
    String? rootCA,
    String? serverCert,
  }) {
    final SecurityContext securityContext = SecurityContext.defaultContext;

    final Uint8List privateKeyBytes = base64Decode(key);

    securityContext.usePrivateKeyBytes(privateKeyBytes);

    if (rootCA != null) {
      final Uint8List rootCABytes = base64Decode(rootCA);

      securityContext.setTrustedCertificatesBytes(rootCABytes);
    }

    if (serverCert != null) {
      final Uint8List serverCertBytes = base64Decode(serverCert);

      securityContext.setClientAuthoritiesBytes(serverCertBytes);
    }

    return securityContext;
  }

  Future<bool> _socketConnect(String host, int port) async {
    await _socketClient.disconnect();

    await Future.delayed(Duration(seconds: 1));

    return _socketClient.connect(host, port);
  }

  Future<bool> _updateSecurity(SecurityContext securityContext) {
    return _socketClient.addSecureOnSocket(
      onBadCertificate: (_) => true,
      context: securityContext,
    );
  }

  void _authenticationListener(Uint8List response) {
    final Map<String, dynamic> result = jsonDecode(
      String.fromCharCodes(response),
    );

    appLog.d('Get Socket Response : $result');

    final String? cmd = result['cmd'] as String?;

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

    appLog.d('Get Socket Response : $result');

    final String? cmd = result['cmd'] as String?;

    switch (cmd) {
      case Cmd.ping:
        _whenReceviedPing();
        break;
      case Cmd.sendDxiData:
        break;
      case Cmd.setDxiMode:
        _whenReceviedSetDxiMode();
        break;
    }
  }

  void _whenReceviedPing() {
    final DxiRequestModel dxiRequestModel = DxiRequestModel(
      type: 'request',
      cmd: Cmd.pong,
      data: {'constantConnect': 'Y'},
    );

    _sendRequest(dxiRequestModel);
  }

  void _whenReceviedSet2WayCert() async {
    _stopSendSet2WayCertReqTimer();

    await _socketClient.disconnect();

    await Future.delayed(Duration(seconds: 1));
  }

  void _whenReceviedSetDxiMode() async {
    _stopSendSetDxiModeReqTimer();
  }

  void _sendSet2WayCertRequest() {
    int sendCount = 0;

    _sendSet2WayCertReqTimer = Timer.periodic(sendRequestDuration, (timer) {
      if (sendCount >= maxSendCount) timer.cancel();

      final DxiRequestModel dxiRequestModel = DxiRequestModel(
        type: 'request',
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
        type: 'request',
        cmd: Cmd.setDxiMode,
        data: {"constantConnect": "Y"},
      );

      _sendRequest(dxiRequestModel);

      sendCount++;
    });
  }

  void _sendRequest(DxiRequestModel dxiRequestModel) {
    appLog.d('send message\n$dxiRequestModel');

    _socketClient.addMessage(jsonEncode(dxiRequestModel.toJson()));
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
      type: 'dxi',
      cmd: Cmd.releaseDxiMode,
      data: {'constantConnect': 'N', 'exitAP': exitAP ? 'Y' : 'N'},
    );

    _sendRequest(dxiRequestModel);
  }
}
