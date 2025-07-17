import 'package:amuz_assignment/src/presentation/pages/connect_page/connect_page.dart';
import 'package:go_router/go_router.dart';

final class AppRoutes {
  const AppRoutes._();

  static GoRoute connect = GoRoute(
    path: '/connect',
    name: 'connect',
    builder: (context, state) => ConnectPage(),
  );

  static List<RouteBase> routes = [connect];
}
