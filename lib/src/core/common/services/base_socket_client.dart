import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:amuz_assignment/src/core/common/models/connect_state.dart';
import 'package:amuz_assignment/src/core/constants/app_constant.dart';
import 'package:rxdart/subjects.dart';

class Message {
  final Object? message;
  final bool showLog;

  const Message({required this.message, this.showLog = true});

  @override
  String toString() {
    return 'Message(message: $message, showLog: $showLog)';
  }
}

class BaseSocketClient {
  Socket? socket;
  Stream<Uint8List>? _broadcaseSocketStream;
  bool _isSocketConnected = false;
  StreamSubscription<Uint8List>? _socketSubscription;
  final List<Message> _messageQueue = [];
  final BehaviorSubject<ConnectionState> _connectionState =
      BehaviorSubject.seeded(ConnectionState.disconnect);

  set updateConnectionState(ConnectionState newState) =>
      _connectionState.sink.add(newState);

  Stream<ConnectionState> get connectionStateStream => _connectionState.stream;

  Future<bool> connect(
    String ip,
    int port, {
    bool Function(X509Certificate)? onBadCertificate,
    SecurityContext? context,
  }) async {
    try {
      if (context != null) {
        appLog.d('SecureSocket connecting...');

        socket = await SecureSocket.connect(
          ip,
          port,
          timeout: Duration(seconds: 2),
          context: context,
          onBadCertificate: onBadCertificate,
        );
      } else {
        appLog.d('Socket connecting...');

        socket = await Socket.connect(ip, port, timeout: Duration(seconds: 2));
      }

      _isSocketConnected = true;

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

      _broadcaseSocketStream = null;

      await socket?.close();

      socket?.done.then((_) {
        _isSocketConnected = false;
      });
    } catch (e, stackTrace) {
      appLog.e(e, error: e, stackTrace: stackTrace);
      appLog.d('강제 연결해제 시작');

      socket?.destroy();
      _isSocketConnected = false;
    }
  }

  Future<void> addListener(
    void Function(Uint8List)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) async {
    if (socket == null || !_isSocketConnected) return;

    await removeListener();

    _broadcaseSocketStream ??= socket!.asBroadcastStream();

    _socketSubscription = _broadcaseSocketStream!.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  Future<void> removeListener() async {
    await _socketSubscription?.cancel();
    _socketSubscription = null;
  }

  void addMessage(Message message) {
    _messageQueue.add(message);
  }

  void _sendMessageOnQueue() {
    Future.doWhile(() async {
      await Future.delayed(Duration(milliseconds: 500));

      if (_messageQueue.isNotEmpty) {
        Message message = _messageQueue.removeAt(0);

        if (message.showLog) {
          appLog.i('Socket Write message : $message');
        }

        _write(message);
      }

      return _isSocketConnected;
    });
  }

  void _write(Object? object) {
    if (socket == null || !_isSocketConnected) return;

    socket!.write(object);
  }
}
