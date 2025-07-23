import 'package:amuz_assignment/src/core/common/pages/shell_route_page/shell_route_page.dart';
import 'package:amuz_assignment/src/features/connection/presentation/pages/connect_page/connect_page.dart';
import 'package:amuz_assignment/src/features/monitoring/presentation/pages/main_page/main_page.dart';
import 'package:go_router/go_router.dart';

final class AppRoutes {
  const AppRoutes._();

  static GoRoute connect = GoRoute(
    path: '/connect',
    name: 'connect',
    builder: (context, state) => ConnectPage(),
  );

  static GoRoute main = GoRoute(
    path: '/main',
    name: 'main',
    builder: (context, state) => MainPage(),
  );

  static StatefulShellRoute shellRoute = StatefulShellRoute.indexedStack(
    branches: [
      StatefulShellBranch(routes: [connect]),
      StatefulShellBranch(routes: [main]),
    ],
    builder: (context, state, navigationShell) =>
        ShellRoutePage(state: state, navigationShell: navigationShell),
  );

  static List<RouteBase> routes = [shellRoute];
}
