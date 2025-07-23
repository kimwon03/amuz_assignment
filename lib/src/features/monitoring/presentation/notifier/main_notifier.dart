import 'dart:async';

import 'package:amuz_assignment/src/features/monitoring/domain/repositories/dxi_repository.dart';
import 'package:get_it/get_it.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'main_notifier.g.dart';

@Riverpod(keepAlive: false)
class MainNotifier extends _$MainNotifier {
  late final DxiRepository _dxiRepository;
  StreamSubscription? _monitoringSubscription;

  MainNotifier() : _dxiRepository = GetIt.I<DxiRepository>();

  @override
  Map<String, dynamic> build() {
    return {};
  }

  void startMonitoring() {
    _dxiRepository.startMonitoring();

    _monitoringSubscription = _dxiRepository.monitoringDataStream.listen((
      data,
    ) {
      print(data);

      state = data;
    });
  }

  void disconnect() {
    _monitoringSubscription?.cancel();
    _monitoringSubscription = null;

    _dxiRepository.disconnect();
  }
}
