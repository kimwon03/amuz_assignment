import 'package:amuz_assignment/src/data/data_sources/dxi_socket_client.dart';
import 'package:amuz_assignment/src/domain/repositories/dxi_repository.dart';

class DxiRepositoryImpl implements DxiRepository {
  late final DxiSocketClient _client;

  DxiRepositoryImpl({required DxiSocketClient client}) : _client = client;

  @override
  Future<void> connect() async {
    await _client.connect();
  }

  @override
  Future<void> disconnect() async {
    await _client.disconnect();
  }
}
