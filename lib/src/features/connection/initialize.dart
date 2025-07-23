import 'package:amuz_assignment/src/core/common/services/base_socket_client.dart';
import 'package:amuz_assignment/src/features/connection/data/repositories/dxi_repository_impl.dart';
import 'package:amuz_assignment/src/features/connection/data/services/dxi_service.dart';
import 'package:amuz_assignment/src/features/connection/domain/repositories/dxi_repository.dart';
import 'package:get_it/get_it.dart';

void initialize(BaseSocketClient socketClient) {
  DxiSocketClient dxiSocketClient = DxiSocketClient(socketClient);

  dxiSocketClient.initialize(); 

  DxiRepository dxiRepository = DxiRepositoryImpl(client: dxiSocketClient);

  GetIt.I.registerLazySingleton<DxiRepository>(() => dxiRepository);
}
