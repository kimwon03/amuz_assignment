import 'dart:io';

class BaseSocketClient {
  Socket? socket;

  Future<bool> connet(String ip, int port) async {
    try {
      socket = await Socket.connect(ip, port, timeout: Duration(seconds: 2));

      return true;
    } catch(e) {
      return false;
    }
  }
}