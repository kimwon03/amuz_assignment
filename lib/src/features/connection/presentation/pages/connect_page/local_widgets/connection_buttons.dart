import 'package:amuz_assignment/src/features/connection/presentation/notifier/connect_notifier.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class ConnectButton extends ConsumerWidget {
  const ConnectButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () {
        ref.read(connectNotifierProvider.notifier).connect();
      },
      child: Text('연결'),
    );
  }
}


class DisconnectButton extends ConsumerWidget {
  const DisconnectButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () {
        ref.read(connectNotifierProvider.notifier).disconnect();
      },
      child: Text('연결 해지'),
    );
  }
}
