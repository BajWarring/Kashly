import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kashly/features/cashbooks/list_page.dart';
import 'package:kashly/features/cashbooks/detail_page.dart';
import 'package:kashly/features/transactions/entry_form.dart';
import 'package:kashly/features/transactions/detail_page.dart';
import 'package:kashly/features/backup_center/backup_center_screen.dart';
import 'package:kashly/features/settings/settings_screen.dart';
import 'package:kashly/features/auth/auth_screen.dart';
import 'package:kashly/features/dashboard/dashboard_screen.dart'; // For professional features

final goRouterProvider = Provider<GoRouter>((ref) => GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => const DashboardScreen()),
    GoRoute(path: '/auth', builder: (context, state) => const AuthScreen()),
    GoRoute(path: '/cashbooks', builder: (context, state) => const CashbooksListPage()),
    GoRoute(path: '/cashbooks/:id', builder: (context, state) => CashbookDetailPage(id: state.pathParameters['id']!)),
    GoRoute(path: '/transactions/entry', builder: (context, state) => const TransactionEntryForm()),
    GoRoute(path: '/transactions/:id', builder: (context, state) => TransactionDetailPage(id: state.pathParameters['id']!)),
    GoRoute(path: '/backup_center', builder: (context, state) => const BackupCenterScreen()),
    GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()),
  ],
));
