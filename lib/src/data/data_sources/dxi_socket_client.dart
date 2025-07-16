import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

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
  }

  SecurityContext _getSecurityContext() {
    final SecurityContext securityContext = SecurityContext.defaultContext;

    final Uint8List privateKeyBytes = base64Decode(Keys.blackboxKey);

    securityContext.usePrivateKeyBytes(privateKeyBytes);

    return securityContext;
  }
}
