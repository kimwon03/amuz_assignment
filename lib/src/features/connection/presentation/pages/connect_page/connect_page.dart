import 'package:amuz_assignment/src/core/common/models/connect_state.dart'
    as Utils;
import 'package:amuz_assignment/src/features/connection/presentation/notifier/connect_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'local_widgets/index.dart';

class ConnectPage extends HookConsumerWidget {
  const ConnectPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Utils.ConnectionState state = ref.watch(connectNotifierProvider);

    useEffect(() {
      return () async {
        await ref.read(connectNotifierProvider.notifier).dispose();
      };
    }, []);

    return Scaffold(
      body: Center(
        child: switch (state) {
          Utils.ConnectionState.connect => DisconnectButton(),
          Utils.ConnectionState.waiting => Text('연결 중'),
          Utils.ConnectionState.disconnect => ConnectButton(),
        },
      ),
    );
  }
}
