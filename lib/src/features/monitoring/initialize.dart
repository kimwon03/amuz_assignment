import 'package:amuz_assignment/src/core/common/services/base_socket_client.dart';
import 'package:amuz_assignment/src/features/monitoring/data/repositories/dxi_repository_impl.dart';
import 'package:amuz_assignment/src/features/monitoring/data/services/dxi_service.dart';
import 'package:amuz_assignment/src/features/monitoring/domain/repositories/dxi_repository.dart';
import 'package:get_it/get_it.dart';

void initialize(BaseSocketClient socketClient) {
  DxiService dxiService = DxiService(socketClient);

  dxiService.initialize();

  DxiRepository dxiRepository = DxiRepositoryImpl(dxiService: dxiService);

  GetIt.I.registerLazySingleton<DxiRepository>(() => dxiRepository);
}
