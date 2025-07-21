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

  static List<RouteBase> routes = [connect, main];
}
