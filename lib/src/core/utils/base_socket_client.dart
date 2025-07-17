import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:amuz_assignment/src/core/constants/app_constant.dart';

class BaseSocketClient {
  Socket? socket;
  bool isConnected = false;
  StreamSubscription<Uint8List>? _socketSubscription;
  final List<Object?> _messageQueue = [];

  Future<bool> connect(String ip, int port) async {
    try {
      socket = await Socket.connect(ip, port, timeout: Duration(seconds: 2));

      isConnected = true;

      _sendMessageOnQueue();

      appLog.i('Connect Socket ip : $ip, port $port');

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
      await removeListener();
      
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

  Future<void> addListener(
    void Function(Uint8List)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) async {
    if (socket == null || !isConnected) return;

    await removeListener();

    _socketSubscription = socket?.listen(
      onData,
      onDone: onDone,
      onError: onError,
      cancelOnError: cancelOnError,
    );
  }

  Future<void> removeListener() async {
    await _socketSubscription?.cancel();
    _socketSubscription = null;
  }

  void addMessage(Object object) {
    _messageQueue.add(object);
  }

  void _sendMessageOnQueue() {
    Future.doWhile(() async {
      Future.delayed(Duration(milliseconds: 500));

      if(_messageQueue.isNotEmpty) {
        Object? object = _messageQueue.removeAt(0);

        _write(object);
      }

      return isConnected;
    });
  }

  void _write(Object? object) {
    socket!.write(object);
  }
}
