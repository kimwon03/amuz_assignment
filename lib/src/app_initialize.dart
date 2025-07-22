import 'dart:convert';

import 'package:amuz_assignment/src/core/constants/app_constant.dart';
import 'package:amuz_assignment/src/features/connection/data/repositories/dxi_repository_impl.dart';
import 'package:amuz_assignment/src/features/connection/data/services/dxi_service.dart';
import 'package:amuz_assignment/src/features/connection/domain/repositories/dxi_repository.dart';
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';

Future<void> appInitialize() async {
  final String response = await rootBundle.loadString(
    "assets/REF_NEXT_DXI_3_1_5.json",
  );
  productSpecification = await json.decode(response);

  DxiSocketClient dxiSocketClient = DxiSocketClient();

  dxiSocketClient.initialize();

  DxiRepository dxiRepository = DxiRepositoryImpl(client: dxiSocketClient);

  GetIt.I.registerLazySingleton<DxiRepository>(() => dxiRepository);
}
