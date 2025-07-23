import 'dart:async';

import 'package:amuz_assignment/src/core/common/services/base_socket_client.dart';
import 'package:amuz_assignment/src/core/common/models/connect_state.dart'
    as common;
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

class ShellRoutePage extends HookWidget {
  final GoRouterState state;
  final StatefulNavigationShell navigationShell;

  const ShellRoutePage({
    super.key,
    required this.state,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context) {
    useEffect(() {
      StreamSubscription<common.ConnectionState> connectionStateStream =
          GetIt.I<BaseSocketClient>().connectionStateStream.listen((event) {
            switch (event) {
              case common.ConnectionState.disconnect:
                navigationShell.goBranch(0);
              case common.ConnectionState.connect:
                navigationShell.goBranch(1);
              case common.ConnectionState.waiting:
                navigationShell.goBranch(0);
            }
          });

      return () {
        connectionStateStream.cancel();
      };
    }, []);

    return navigationShell;
  }
}
