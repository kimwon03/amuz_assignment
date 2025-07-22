import 'package:amuz_assignment/src/features/monitoring/data/services/dxi_service.dart';
import 'package:amuz_assignment/src/features/monitoring/domain/repositories/dxi_repository.dart';

class DxiRepositoryImpl implements DxiRepository {
  late final DxiService _dxiService;

  DxiRepositoryImpl({required DxiService dxiService})
    : _dxiService = dxiService;

  @override
  void startMonitoring() {
    _dxiService.startMonitoring();
  }
}
