import 'package:amuz_assignment/src/features/monitoring/presentation/notifier/main_notifier.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class DataListview extends ConsumerWidget {
  const DataListview({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Map<String, dynamic> dataMap = ref.watch(mainNotifierProvider);

    return ExpansionPanelList(children: []);
  }
}
