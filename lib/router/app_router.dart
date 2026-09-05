import 'package:go_router/go_router.dart';

import '../data/models/category.dart';
import '../data/models/transaction.dart';
import '../features/categories/categories_page.dart';
import '../features/categories/category_edit_page.dart';
import '../features/home/home_page.dart';
import '../features/import_bill/import_page.dart';
import '../features/record/record_page.dart';
import '../features/settings/settings_page.dart';
import '../features/stats/stats_page.dart';
import 'main_shell.dart';

/// 编辑账目载荷（区分新增 / 编辑）。
class EditPayload {
  const EditPayload({this.transaction});
  final Transaction? transaction;
}

final appRouter = GoRouter(
  initialLocation: '/home',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          MainShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/home',
            name: 'home',
            builder: (context, state) => const HomePage(),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/stats',
            name: 'stats',
            builder: (context, state) => const StatsPage(),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/categories',
            name: 'categories',
            builder: (context, state) => const CategoriesPage(),
          ),
        ]),
      ],
    ),
    GoRoute(
      path: '/record',
      name: 'record',
      builder: (context, state) {
        final payload = state.extra;
        return RecordPage(
          editing: payload is EditPayload ? payload.transaction : null,
        );
      },
    ),
    GoRoute(
      path: '/category_edit',
      name: 'category_edit',
      builder: (context, state) {
        final extra = state.extra;
        return CategoryEditPage(
          editing: extra is Category ? extra : null,
        );
      },
    ),
    GoRoute(
      path: '/import',
      name: 'import',
      builder: (context, state) => const ImportPage(),
    ),
    GoRoute(
      path: '/settings',
      name: 'settings',
      builder: (context, state) => const SettingsPage(),
    ),
  ],
);
