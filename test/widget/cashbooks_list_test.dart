import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kashly/domain/entities/cashbook.dart';
import 'package:kashly/core/di/providers.dart';
import 'package:kashly/features/cashbooks/list_page.dart';

void main() {
  testWidgets('shows empty state when no cashbooks', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cashbooksProvider.overrideWith((ref) async => []),
          filteredCashbooksProvider.overrideWith((ref) => const AsyncValue.data([])),
        ],
        child: MaterialApp.router(
          routerConfig: GoRouter(routes: [
            GoRoute(path: '/', builder: (_, __) => const CashbooksListPage()),
            GoRoute(
              path: '/cashbooks/:id',
              builder: (_, state) => Scaffold(body: Text(state.pathParameters['id']!)),
            ),
          ]),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('No cashbooks found'), findsOneWidget);
  });

  testWidgets('shows cashbook card when data present', (tester) async {
    final cb = Cashbook(
      id: 'cb-1',
      name: 'My Business',
      currency: 'USD',
      openingBalance: 5000,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      syncStatus: SyncStatus.synced,
      backupSettings: const BackupSettings(autoBackupEnabled: false, includeAttachments: false),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cashbooksProvider.overrideWith((ref) async => [cb]),
          filteredCashbooksProvider.overrideWith((ref) => AsyncValue.data([cb])),
          cashbookBalanceProvider.overrideWith((ref, id) async => 5000.0),
        ],
        child: MaterialApp.router(
          routerConfig: GoRouter(routes: [
            GoRoute(path: '/', builder: (_, __) => const CashbooksListPage()),
            GoRoute(
              path: '/cashbooks/:id',
              builder: (_, state) => Scaffold(body: Text(state.pathParameters['id']!)),
            ),
          ]),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('My Business'), findsOneWidget);
  });
}
