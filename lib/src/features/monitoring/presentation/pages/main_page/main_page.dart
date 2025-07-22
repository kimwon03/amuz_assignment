import 'package:amuz_assignment/src/features/monitoring/presentation/notifier/main_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class MainPage extends HookConsumerWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useEffect(() {
      ref.read(mainNotifierProvider.notifier).startMonitoring();
    }, []);

    return Scaffold(body: Center(child: Text('Main Page')));
  }
}
