import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'connect_notifier.g.dart';

@Riverpod(keepAlive: false)
class ConnectNotifier extends _$ConnectNotifier {
  @override
  bool build() {
    return false;
  }
}