import 'package:finance_tracker_offline/core/router/scaffold_with_nav_bar.dart';
import 'package:finance_tracker_offline/features/accounts/accounts_screen.dart';
import 'package:finance_tracker_offline/features/add_transaction/add_transaction_screen.dart';
import 'package:finance_tracker_offline/features/dashboard/dashboard_screen.dart';
import 'package:finance_tracker_offline/features/settings/settings_screen.dart';
import 'package:finance_tracker_offline/features/stats/stats_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    routes: [
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return ScaffoldWithNavBar(child: child);
        },
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/stats',
            builder: (context, state) => const StatsScreen(),
          ),
          GoRoute(
            path: '/accounts',
            builder: (context, state) => const AccountsScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/add_transaction',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AddTransactionScreen(),
      ),
    ],
  );
});
