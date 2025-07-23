import 'package:amuz_assignment/src/core/common/models/connect_state.dart'
    as utils;
import 'package:amuz_assignment/src/features/connection/presentation/notifier/connect_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'local_widgets/index.dart';

class ConnectPage extends HookConsumerWidget {
  const ConnectPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final utils.ConnectionState state = ref.watch(connectNotifierProvider);

    useEffect(() {
      return () async {
        await ref.read(connectNotifierProvider.notifier).dispose();
      };
    }, []);

    return Scaffold(
      body: Center(
        child: switch (state) {
          utils.ConnectionState.connect => DisconnectButton(),
          utils.ConnectionState.waiting => Text('연결 중'),
          utils.ConnectionState.disconnect => ConnectButton(),
        },
      ),
    );
  }
}
