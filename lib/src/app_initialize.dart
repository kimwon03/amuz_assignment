import 'dart:convert';

import 'package:amuz_assignment/src/core/common/services/base_socket_client.dart';
import 'package:amuz_assignment/src/core/constants/app_constant.dart';
import 'package:amuz_assignment/src/features/connection/initialize.dart'
    as Connection;
import 'package:amuz_assignment/src/features/monitoring/initialize.dart'
    as Monitoring;
import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';

Future<void> appInitialize() async {
  final String response = await rootBundle.loadString(
    "assets/REF_NEXT_DXI_3_1_5.json",
  );
  productSpecification = await json.decode(response);

  BaseSocketClient socketClient = BaseSocketClient();

  GetIt.I.registerLazySingleton<BaseSocketClient>(() => socketClient);

  Connection.initialize(socketClient);
  Monitoring.initialize(socketClient);
}
