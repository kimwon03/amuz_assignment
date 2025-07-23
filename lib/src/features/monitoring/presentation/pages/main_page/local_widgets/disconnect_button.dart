import 'package:amuz_assignment/src/features/monitoring/presentation/notifier/main_notifier.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class DisconnectButton extends ConsumerWidget {
  const DisconnectButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TextButton(onPressed: () {
      ref.read(mainNotifierProvider.notifier).disconnect();
    }, child: Text('연결 해지'));
  }
}
