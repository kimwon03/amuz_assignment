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
  Timer? _sendSet2WayCertReqTimer = null;

  Future<void> connect() async {
    await serverAuthentication();
  }

  Future<void> serverAuthentication() async {
    final SecurityContext securityContext = _getSecurityContext();

    final bool socketConnectResult = await _socketConnect(host, port);

    if (!socketConnectResult) return;

    final bool updateSocketSecurity = await _updateSecurity(securityContext);

    if (!updateSocketSecurity) return;

    await _socketClient.addListener(_listener);

    await Future.delayed(Duration(seconds: 1));

    _sendSet2WayCertRequest();
  }

  SecurityContext _getSecurityContext() {
    final SecurityContext securityContext = SecurityContext.defaultContext;

    final Uint8List privateKeyBytes = base64Decode(Keys.blackboxKey);

    securityContext.usePrivateKeyBytes(privateKeyBytes);

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

  void _listener(Uint8List response) {
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

  void _whenReceviedPing() {
    final DxiRequestModel dxiRequestModel = DxiRequestModel(
      type: 'request',
      cmd: 'pong',
      data: {'constantConnect': 'Y'},
    );

    _sendRequest(dxiRequestModel);
  }

  void _whenReceviedSet2WayCert() {
    _stopSendSet2WayCertReqTimer();
  }

  void _sendSet2WayCertRequest() {
    int sendCount = 0;

    _sendSet2WayCertReqTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      if (sendCount >= maxSendCount) timer.cancel();

      final DxiRequestModel dxiRequestModel = DxiRequestModel(
        type: 'request',
        cmd: 'set2wayCert',
        data: {"constantConnect": "N"},
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
}
