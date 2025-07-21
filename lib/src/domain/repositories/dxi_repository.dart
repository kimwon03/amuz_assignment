import 'package:amuz_assignment/src/core/utils/connect_state.dart';

abstract interface class DxiRepository {
  Future<void> connect();
  Future<void> disconnect();

  Stream<ConnectionState> get connectionStateStream;
}
