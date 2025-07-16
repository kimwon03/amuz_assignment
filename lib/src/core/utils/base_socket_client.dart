import 'dart:io';

class BaseSocketClient {
  Socket? socket;

  Future<bool> connet(String ip, int port) {
    throw UnimplementedError();
  }
}