import 'dart:async';

import 'package:amuz_assignment/src/core/utils/connect_state.dart';
import 'package:amuz_assignment/src/domain/repositories/dxi_repository.dart';
import 'package:get_it/get_it.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'connect_notifier.g.dart';

/// Notifier 사용 중단 시 dispose 필수
///
/// dispose를 하지 않으면 connectionStateStream Listener가 종료 되지 않음!!!
@Riverpod(keepAlive: false)
class ConnectNotifier extends _$ConnectNotifier {
  late final DxiRepository _dxiRepository;
  StreamSubscription? _subscription;

  ConnectNotifier() : _dxiRepository = GetIt.I<DxiRepository>();

  @override
  ConnectionState build() {
    _subscription?.cancel();
    _subscription = _dxiRepository.connectionStateStream.listen((event) {
      state = event;
    });

    return ConnectionState.disconnect;
  }

  void connect() {
    _dxiRepository.connect();
  }

  void disconnect() {
    _dxiRepository.disconnect();
  }

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }
}
