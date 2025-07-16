const String host = String.fromEnvironment('dxi_host');
const int port = int.fromEnvironment('dxi_port');

const int maxSendCount = 3;

final class Cmd {
  const Cmd._();

  static const String ping = 'ping';
  static const String set2wayCert = 'set2wayCert';
}
