import 'dart:convert';

import 'package:amuz_assignment/src/core/constants/app_constant.dart';
import 'package:amuz_assignment/src/data/data_sources/dxi_socket_client.dart';
import 'package:amuz_assignment/src/data/repositories/dxi_repository_impl.dart';
import 'package:amuz_assignment/src/domain/repositories/dxi_repository.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';

Future<void> appInitialize() async {
  final String response = await rootBundle.loadString("assets/REF_NEXT_DXI_3_1_5.json");
  productSpecification = await json.decode(response);

  DxiSocketClient dxiSocketClient = DxiSocketClient();
  DxiRepository dxiRepository = DxiRepositoryImpl(client: dxiSocketClient);

  GetIt.I.registerLazySingleton<DxiRepository>(() => dxiRepository);
}
