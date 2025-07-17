abstract interface class DxiRepository {
  Future<void> connect();
  Future<void> disconnect();
}