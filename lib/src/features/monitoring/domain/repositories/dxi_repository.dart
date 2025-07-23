abstract interface class DxiRepository {
  void startMonitoring();
  Future<void> disconnect();
  Stream<Map<String, dynamic>> get monitoringDataStream;
}
