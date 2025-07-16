import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:amuz_assignment/src/core/constants/app_constant.dart';
import 'package:amuz_assignment/src/core/constants/dxi_constant.dart';
import 'package:amuz_assignment/src/core/constants/keys.dart';
import 'package:amuz_assignment/src/core/utils/base_socket_client.dart';

class DxiSocketClient {
  final BaseSocketClient _socketClient = BaseSocketClient();

  Future<void> connect() async {
    await serverAuthentication();
  }

  Future<void> serverAuthentication() async {
    final SecurityContext securityContext = _getSecurityContext();

    final bool socketConnectResult = await _socketConnect(host, port);

    if (!socketConnectResult) return;

    final bool updateSocketSecurity = await _updateSecurity(securityContext);

    if (!updateSocketSecurity) return;

    _socketClient.addListener(_listener);
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
  }
}
