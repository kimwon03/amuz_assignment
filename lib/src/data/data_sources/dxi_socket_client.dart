import 'package:amuz_assignment/src/core/constants/dxi_constant.dart';
import 'package:amuz_assignment/src/core/utils/base_socket_client.dart';

class DxiSocketClient {
  final BaseSocketClient _socketClient = BaseSocketClient();

  Future<void> connect() async {
    _socketClient.disconnect();

    bool socketConnectResult = await _socketClient.connect(host, port);

    if (!socketConnectResult) false;
  }
}
