import 'package:amuz_assignment/src/core/utils/connect_state.dart' as Utils;
import 'package:amuz_assignment/src/presentation/notifier/connect_notifier.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'local_widgets/index.dart';

class ConnectPage extends StatelessWidget {
  const ConnectPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Consumer(
          builder: (_, ref, ___) {
            Utils.ConnectionState state = ref.watch(
              connectNotifierProvider,
            );

            return switch (state) {
              Utils.ConnectionState.connect => DisconnectButton(),
              Utils.ConnectionState.waiting => Text('연결 중'),
              Utils.ConnectionState.disconnect => ConnectButton(),
            };
          },
        ),
      ),
    );
  }
}
