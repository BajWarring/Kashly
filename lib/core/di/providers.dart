import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kashly/data/datasources/local_datasource.dart';
import 'package:kashly/data/repositories/cashbook_repository_impl.dart';
import 'package:kashly/data/repositories/transaction_repository_impl.dart';
import 'package:kashly/data/repositories/backup_repository_impl.dart';
import 'package:kashly/domain/repositories/cashbook_repository.dart';
import 'package:kashly/domain/repositories/transaction_repository.dart';
import 'package:kashly/domain/repositories/backup_repository.dart';
import 'package:kashly/domain/entities/cashbook.dart';
import 'package:kashly/domain/entities/transaction.dart';
import 'package:kashly/domain/entities/backup_record.dart';
import 'package:kashly/domain/entities/backup_settings.dart';
import 'package:kashly/features/auth/auth_provider.dart';
import 'package:kashly/services/backup/backup_service.dart';
import 'package:kashly/services/sync_engine/sync_service.dart';
import 'package:kashly/services/notification/notification_service.dart';

// ─── Infrastructure ───────────────────────────────────────────────────────────

final localDatasourceProvider = Provider<LocalDatasource>((ref) => LocalDatasource());

// ─── Repositories ─────────────────────────────────────────────────────────────

final cashbookRepositoryProvider = Provider<CashbookRepository>(
  (ref) => CashbookRepositoryImpl(ref.watch(localDatasourceProvider)),
);

final transactionRepositoryProvider = Provider<TransactionRepository>(
  (ref) => TransactionRepositoryImpl(ref.watch(localDatasourceProvider)),
);

final backupRepositoryProvider = Provider<BackupRepository>(
  (ref) => BackupRepositoryImpl(ref.watch(localDatasourceProvider)),
);

// ─── Services ─────────────────────────────────────────────────────────────────

final backupServiceProvider = Provider<BackupService>((ref) => BackupService(
  datasource: ref.watch(localDatasourceProvider),
  getAuthHeaders: () => ref.read(authProvider.notifier).getAuthHeaders(),
));

final syncServiceProvider = Provider<SyncService>(
  (ref) => SyncService(ref.watch(backupServiceProvider)),
);

final notificationServiceProvider = Provider<NotificationService>(
  (ref) => NotificationService(),
);

// ─── Auth ─────────────────────────────────────────────────────────────────────

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(),
);

// ─── Cashbooks ────────────────────────────────────────────────────────────────

final cashbooksProvider = FutureProvider<List<Cashbook>>((ref) async {
  return ref.watch(cashbookRepositoryProvider).getCashbooks();
});

final cashbookDetailProvider = FutureProvider.family<Cashbook?, String>((ref, id) async {
  return ref.watch(cashbookRepositoryProvider).getCashbookById(id);
});

final cashbookBalanceProvider = FutureProvider.family<double, String>((ref, id) async {
  return ref.watch(cashbookRepositoryProvider).getBalance(id);
});

final cashbookTotalInProvider = FutureProvider.family<double, String>((ref, id) async {
  return ref.watch(cashbookRepositoryProvider).getTotalIn(id);
});

final cashbookTotalOutProvider = FutureProvider.family<double, String>((ref, id) async {
  return ref.watch(cashbookRepositoryProvider).getTotalOut(id);
});

// ─── Transactions ─────────────────────────────────────────────────────────────

final transactionsProvider = FutureProvider.family<List<Transaction>, String>((ref, cashbookId) async {
  return ref.watch(transactionRepositoryProvider).getTransactions(cashbookId);
});

final transactionDetailProvider = FutureProvider.family<Transaction?, String>((ref, id) async {
  return ref.watch(transactionRepositoryProvider).getTransactionById(id);
});

final nonUploadedTransactionsProvider = FutureProvider<List<Transaction>>((ref) async {
  return ref.watch(transactionRepositoryProvider).getNonUploadedTransactions();
});

final conflictTransactionsProvider = FutureProvider<List<Transaction>>((ref) async {
  return ref.watch(transactionRepositoryProvider).getPendingConflicts();
});

// ─── Backup ───────────────────────────────────────────────────────────────────

final backupHistoryProvider = FutureProvider<List<BackupRecord>>((ref) async {
  return ref.watch(backupRepositoryProvider).getBackupHistory();
});

final backupSettingsProvider = FutureProvider<AppBackupSettings>((ref) async {
  return ref.watch(backupRepositoryProvider).getSettings();
});

// ─── Cashbook Filter/Sort ─────────────────────────────────────────────────────

class CashbookFilterState {
  final String searchQuery;
  final String sortBy;
  final Set<String> activeFilters;

  const CashbookFilterState({
    this.searchQuery = '',
    this.sortBy = 'updated_at',
    this.activeFilters = const {},
  });

  CashbookFilterState copyWith({
    String? searchQuery,
    String? sortBy,
    Set<String>? activeFilters,
  }) =>
      CashbookFilterState(
        searchQuery: searchQuery ?? this.searchQuery,
        sortBy: sortBy ?? this.sortBy,
        activeFilters: activeFilters ?? this.activeFilters,
      );
}

final cashbookFilterProvider = StateProvider<CashbookFilterState>(
  (ref) => const CashbookFilterState(),
);

final filteredCashbooksProvider = Provider<AsyncValue<List<Cashbook>>>((ref) {
  final cashbooksAsync = ref.watch(cashbooksProvider);
  final filter = ref.watch(cashbookFilterProvider);

  return cashbooksAsync.whenData((cashbooks) {
    var list = cashbooks.where((cb) {
      if (filter.searchQuery.isNotEmpty &&
          !cb.name.toLowerCase().contains(filter.searchQuery.toLowerCase())) {
        return false;
      }
      if (filter.activeFilters.contains('archived') && !cb.isArchived) return false;
      if (filter.activeFilters.contains('active') && cb.isArchived) return false;
      if (filter.activeFilters.contains('synced') &&
          cb.syncStatus != SyncStatus.synced) return false;
      if (filter.activeFilters.contains('unsynced') &&
          cb.syncStatus == SyncStatus.synced) return false;
      return true;
    }).toList();

    list.sort((a, b) {
      switch (filter.sortBy) {
        case 'name':
          return a.name.compareTo(b.name);
        default:
          return b.updatedAt.compareTo(a.updatedAt);
      }
    });

    return list;
  });
});
