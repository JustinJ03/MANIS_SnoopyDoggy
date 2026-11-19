import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../features/auth/auth_controller.dart';
import '../features/auth/login_screen.dart';
import '../features/inventory/inventory_screen.dart';
import '../features/more/more_screen.dart';
import '../features/placeholders/placeholder_screen.dart';
import '../features/requests/requests_screen.dart';
import '../features/schedule/schedule_screen.dart';
import '../features/services/service_form_screen.dart';
import '../features/services/services_screen.dart';
import 'adaptive_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final signedIn = ValueNotifier(ref.read(authControllerProvider));
  ref.listen(authControllerProvider, (_, v) => signedIn.value = v);

  GoRoute page(
    String path,
    Widget child, [
    List<RouteBase> routes = const [],
  ]) => GoRoute(path: path, builder: (_, _) => child, routes: routes);
  StatefulShellBranch branch(GoRoute route) =>
      StatefulShellBranch(routes: [route]);

  final router = GoRouter(
    initialLocation: '/schedule',
    refreshListenable: signedIn,
    redirect: (_, state) {
      final atLogin = state.matchedLocation == '/login';
      if (!signedIn.value) return atLogin ? null : '/login';
      return atLogin ? '/schedule' : null;
    },
    routes: [
      page('/login', const LoginScreen()),
      // UI-04 is M3; tapping a schedule card lands here.
      page('/appointments/:id', const PlaceholderScreen('Appointment details')),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => AdaptiveShell(shell: shell),
        branches: [
          branch(page('/schedule', const ScheduleScreen())),
          branch(page('/requests', const RequestsScreen())),
          branch(page('/inventory', const InventoryScreen())),
          branch(
            page(
              '/customers',
              const PlaceholderScreen('Customers', tabRoot: true),
            ),
          ),
          branch(
            page('/more', const MoreScreen(), [
              page('services', const ServicesScreen(), [
                page('new', const ServiceFormScreen()),
                GoRoute(
                  path: ':id',
                  builder: (_, s) =>
                      ServiceFormScreen(serviceId: s.pathParameters['id']),
                ),
              ]),
              page('help', const PlaceholderScreen('Help')),
            ]),
          ),
        ],
      ),
    ],
  );
  ref.onDispose(() {
    router.dispose();
    signedIn.dispose();
  });
  return router;
});
