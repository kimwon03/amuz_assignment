import 'package:amuz_assignment/src/core/common/models/connect_state.dart';
import 'package:amuz_assignment/src/features/connection/data/services/dxi_service.dart';
import 'package:amuz_assignment/src/features/connection/domain/repositories/dxi_repository.dart';

class DxiRepositoryImpl implements DxiRepository {
  late final DxiService _client;

  DxiRepositoryImpl({required DxiService client}) : _client = client;

  @override
  Future<void> connect() async {
    await _client.connect();
  }

  @override
  Future<void> disconnect() async {
    await _client.disconnect();
  }

  @override
  Stream<ConnectionState> get connectionStateStream =>
      _client.connectionStateStream;

  @override
  void disposeListener() {
    _client.disposeListener();
  }
}
