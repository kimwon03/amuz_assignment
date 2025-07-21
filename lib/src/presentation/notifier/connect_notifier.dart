import 'package:amuz_assignment/src/core/utils/connect_state.dart';
import 'package:amuz_assignment/src/domain/repositories/dxi_repository.dart';
import 'package:get_it/get_it.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'connect_notifier.g.dart';

@Riverpod(keepAlive: false)
class ConnectNotifier extends _$ConnectNotifier {
  late final DxiRepository _dxiRepository;

  ConnectNotifier() : _dxiRepository = GetIt.I<DxiRepository>();

  @override
  ConnectionState build() {
    _dxiRepository.connectionStateStream.listen((event) {
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
}
