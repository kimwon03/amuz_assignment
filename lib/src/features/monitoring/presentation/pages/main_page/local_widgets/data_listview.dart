import 'package:amuz_assignment/src/features/monitoring/presentation/notifier/main_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class DataListview extends HookConsumerWidget {
  const DataListview({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Map<String, dynamic> dataMap = ref.watch(mainNotifierProvider);
    final Iterable<MapEntry<String, dynamic>> dataEnties = dataMap.entries;

    return ListView.builder(
      itemBuilder: (context, index) {
        MapEntry<String, dynamic> data = dataEnties.elementAt(index);

        return Column(
          children: [
            Text(data.key, style: TextStyle(fontWeight: FontWeight.bold)),
            Text(data.value),
          ],
        );
      },
      itemCount: dataEnties.length,
    );
  }
}
