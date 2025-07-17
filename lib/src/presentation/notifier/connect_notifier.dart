import 'package:amuz_assignment/src/domain/repositories/dxi_repository.dart';
import 'package:get_it/get_it.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'connect_notifier.g.dart';

@Riverpod(keepAlive: false)
class ConnectNotifier extends _$ConnectNotifier {
  late final DxiRepository _dxiRepository;

  ConnectNotifier() : _dxiRepository = GetIt.I<DxiRepository>();

  @override
  bool build() {
    return false;
  }
}