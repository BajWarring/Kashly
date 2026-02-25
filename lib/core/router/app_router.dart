import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kashly/features/cashbooks/list_page.dart';
import 'package:kashly/features/cashbooks/detail_page.dart';
import 'package:kashly/features/transactions/entry_form.dart';
import 'package:kashly/features/transactions/detail_page.dart';
import 'package:kashly/features/backup_center/backup_center_screen.dart';
import 'package:kashly/features/settings/settings_screen.dart';
import 'package:kashly/features/auth/auth_screen.dart';
import 'package:kashly/features/dashboard/dashboard_screen.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: false,
    routes: [
      ShellRoute(
        builder: (context, state, child) => _AppShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            pageBuilder: (context, state) => const NoTransitionPage(child: DashboardScreen()),
          ),
          GoRoute(
            path: '/cashbooks',
            pageBuilder: (context, state) => const NoTransitionPage(child: CashbooksListPage()),
          ),
          GoRoute(
            path: '/backup_center',
            pageBuilder: (context, state) => const NoTransitionPage(child: BackupCenterScreen()),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) => const NoTransitionPage(child: SettingsScreen()),
          ),
        ],
      ),
      GoRoute(
        path: '/auth',
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: '/cashbooks/:id',
        builder: (context, state) =>
            CashbookDetailPage(id: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/transactions/entry',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return TransactionEntryForm(
            cashbookId: extra?['cashbookId'] as String? ?? '',
            existingTransaction: extra?['transaction'],
          );
        },
      ),
      GoRoute(
        path: '/transactions/:id',
        builder: (context, state) =>
            TransactionDetailPage(id: state.pathParameters['id']!),
      ),
    ],
  );
});

class _AppShell extends StatefulWidget {
  final Widget child;
  const _AppShell({required this.child});

  @override
  State<_AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<_AppShell> {
  int _selectedIndex = 0;

  static const _routes = ['/', '/cashbooks', '/backup_center', '/settings'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
          context.go(_routes[index]);
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.book_outlined), selectedIcon: Icon(Icons.book), label: 'Cashbooks'),
          NavigationDestination(icon: Icon(Icons.backup_outlined), selectedIcon: Icon(Icons.backup), label: 'Backup'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
