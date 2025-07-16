import 'dart:io';

import 'package:amuz_assignment/src/core/constants/app_constant.dart';

class BaseSocketClient {
  Socket? socket;
  bool isConnected = false;

  Future<bool> connect(String ip, int port) async {
    try {
      socket = await Socket.connect(ip, port, timeout: Duration(seconds: 2));

      isConnected = true;

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

      disconnect();

      return false;
    }
  }

  Future<void> disconnect() async {
    try {
      await socket?.close();

      socket?.done.then((_) {
        isConnected = false;
      });
    } catch (e, stackTrace) {
      appLog.e(e, error: e, stackTrace: stackTrace);
      appLog.d('강제 연결해제 시작');

      socket?.destroy();
      isConnected = false;
    }
  }

  Future<void> addListener() async {
    if (!isConnected) return;
  }
}
