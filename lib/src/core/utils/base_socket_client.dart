import 'dart:io';

class BaseSocketClient {
  Socket? socket;

  Future<bool> connet(String ip, String port) {
    throw UnimplementedError();
  }
}