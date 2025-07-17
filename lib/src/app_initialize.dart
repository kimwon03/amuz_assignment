import 'package:amuz_assignment/src/data/data_sources/dxi_socket_client.dart';
import 'package:amuz_assignment/src/data/repositories/dxi_repository_impl.dart';
import 'package:amuz_assignment/src/domain/repositories/dxi_repository.dart';
import 'package:get_it/get_it.dart';

void appInitialize() {
  DxiSocketClient dxiSocketClient = DxiSocketClient();
  DxiRepository dxiRepository = DxiRepositoryImpl(client: dxiSocketClient);

  GetIt.I.registerLazySingleton(() => dxiRepository);
}
