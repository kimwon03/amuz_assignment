const String host = String.fromEnvironment('dxi_host');
const int port = int.fromEnvironment('dxi_port');

const int maxSendCount = 3;

final Duration sendRequestDuration = Duration(seconds: 5);

final class Cmd {
  const Cmd._();

  static const String ping = 'ping';
  static const String set2wayCert = 'set2wayCert';
  static const String setDxiMode = 'setDxiMode';
  static const String sendDxiData = 'sendDxiData';
  static const String releaseDxiMode = 'releaseDxiMode';
  static const String pong = 'pong';
}

final class Type {
  const Type._();

  static const String request = 'request';
  static const String reponse = 'response';
  static const String dxi = 'dxi';
}
