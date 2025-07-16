import 'dart:io';

import 'package:amuz_assignment/src/core/constants/app_constant.dart';

class BaseSocketClient {
  Socket? socket;

  Future<bool> connet(String ip, int port) async {
    try {
      socket = await Socket.connect(ip, port, timeout: Duration(seconds: 2));

      return true;
    } catch (e, stackTrace) {
      appLog.e(e, error: e, stackTrace: stackTrace);
      return false;
    }
  }

  Future<bool> addSecureOnSocket({
    bool Function(X509Certificate)? onBadCertificate,
    SecurityContext? context,
  }) async {
    if (socket == null) return false;

    try {
      socket = await SecureSocket.secure(
        socket!,
        onBadCertificate: onBadCertificate,
        context: context,
      );

      return true;
    } catch (e, stackTrace) {
      appLog.e(e, error: e, stackTrace: stackTrace);
      return false;
    }
  }

  Future<void> disconnect() {
    throw UnimplementedError();
  }
}
