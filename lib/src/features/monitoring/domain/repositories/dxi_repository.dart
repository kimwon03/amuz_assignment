abstract interface class DxiRepository {
  void startMonitoring();
  Stream<Map<String, dynamic>> get monitoringDataStream;
}
