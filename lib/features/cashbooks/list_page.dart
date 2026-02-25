import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:kashly/core/di/providers.dart';
import 'package:kashly/core/utils/icons.dart';
import 'package:kashly/core/utils/utils.dart';
import 'package:kashly/domain/entities/cashbook.dart';
import 'package:kashly/ux_and_ui_elements/dialogs.dart';

class CashbooksListPage extends ConsumerWidget {
  const CashbooksListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredAsync = ref.watch(filteredCashbooksProvider);
    final filter = ref.watch(cashbookFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cashbooks', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (v) => ref.read(cashbookFilterProvider.notifier).update(
              (s) => s.copyWith(sortBy: v),
            ),
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'name', child: Text('Sort by Name')),
              const PopupMenuItem(value: 'updated_at', child: Text('Sort by Last Updated')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search cashbooks...',
                prefixIcon: Icon(Icons.search),
                isDense: true,
              ),
              onChanged: (v) => ref.read(cashbookFilterProvider.notifier).update(
                (s) => s.copyWith(searchQuery: v),
              ),
            ),
          ),
          // Filter chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final f in ['active', 'archived', 'synced', 'unsynced'])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(f[0].toUpperCase() + f.substring(1)),
                        selected: filter.activeFilters.contains(f),
                        onSelected: (selected) {
                          final filters = Set<String>.from(filter.activeFilters);
                          selected ? filters.add(f) : filters.remove(f);
                          ref.read(cashbookFilterProvider.notifier).update(
                            (s) => s.copyWith(activeFilters: filters),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          // List
          Expanded(
            child: filteredAsync.when(
              data: (cashbooks) => cashbooks.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.book_outlined, size: 48, color: Colors.grey),
                          const SizedBox(height: 12),
                          const Text('No cashbooks found', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () async => ref.invalidate(cashbooksProvider),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: cashbooks.length,
                        itemBuilder: (context, index) => _CashbookCard(
                          cashbook: cashbooks[index],
                          onTap: () => context.go('/cashbooks/${cashbooks[index].id}'),
                          onArchive: () => _archiveCashbook(context, ref, cashbooks[index]),
                          onDelete: () => _deleteCashbook(context, ref, cashbooks[index]),
                          onBackupNow: () => _backupNow(context, ref, cashbooks[index]),
                        ),
                      ),
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createCashbook(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('New Cashbook'),
      ),
    );
  }

  Future<void> _createCashbook(BuildContext context, WidgetRef ref) async {
    final result = await showCreateCashbookDialog(context);
    if (result == null) return;

    try {
      final cashbook = Cashbook(
        id: const Uuid().v4(),
        name: result['name'] as String,
        currency: result['currency'] as String,
        openingBalance: result['openingBalance'] as double,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        syncStatus: SyncStatus.pending,
        backupSettings: const BackupSettings(
          autoBackupEnabled: false,
          includeAttachments: false,
        ),
      );
      await ref.read(cashbookRepositoryProvider).createCashbook(cashbook);
      ref.invalidate(cashbooksProvider);
      if (context.mounted) showSuccessSnackbar(context, 'Cashbook created');
    } catch (e) {
      if (context.mounted) showErrorSnackbar(context, 'Failed to create: $e');
    }
  }

  Future<void> _archiveCashbook(
    BuildContext context,
    WidgetRef ref,
    Cashbook cashbook,
  ) async {
    await ref.read(cashbookRepositoryProvider).archiveCashbook(cashbook.id, !cashbook.isArchived);
    ref.invalidate(cashbooksProvider);
    if (context.mounted) {
      showSuccessSnackbar(context, cashbook.isArchived ? 'Cashbook unarchived' : 'Cashbook archived');
    }
  }

  Future<void> _deleteCashbook(
    BuildContext context,
    WidgetRef ref,
    Cashbook cashbook,
  ) async {
    final confirmed = await showDeleteConfirmation(context, cashbook.name);
    if (confirmed != true) return;
    await ref.read(cashbookRepositoryProvider).deleteCashbook(cashbook.id);
    ref.invalidate(cashbooksProvider);
    if (context.mounted) showSuccessSnackbar(context, 'Cashbook deleted');
  }

  Future<void> _backupNow(
    BuildContext context,
    WidgetRef ref,
    Cashbook cashbook,
  ) async {
    await ref.read(backupServiceProvider).manualBackup(context);
    ref.invalidate(cashbooksProvider);
  }
}

class _CashbookCard extends ConsumerWidget {
  final Cashbook cashbook;
  final VoidCallback onTap;
  final VoidCallback onArchive;
  final VoidCallback onDelete;
  final VoidCallback onBackupNow;

  const _CashbookCard({
    required this.cashbook,
    required this.onTap,
    required this.onArchive,
    required this.onDelete,
    required this.onBackupNow,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balanceAsync = ref.watch(cashbookBalanceProvider(cashbook.id));

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: cashbook.isArchived ? Colors.grey.withOpacity(0.2) : const Color(0xFF1A73E8).withOpacity(0.15),
                child: Text(
                  cashbook.name.substring(0, 1).toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: cashbook.isArchived ? Colors.grey : const Color(0xFF1A73E8),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            cashbook.name,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (cashbook.isArchived)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('Archived', style: TextStyle(fontSize: 10, color: Colors.grey)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    balanceAsync.when(
                      data: (balance) => Text(
                        formatCurrency(balance, cashbook.currency),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: balance >= 0 ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      loading: () => const Text('...'),
                      error: (_, __) => Text(cashbook.currency),
                    ),
                    Text(
                      'Updated ${_timeAgo(cashbook.updatedAt)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                    ),
                  ],
                ),
              ),
              getCashbookSyncIcon(cashbook.syncStatus),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 18),
                onSelected: (v) {
                  switch (v) {
                    case 'archive': onArchive(); break;
                    case 'delete': onDelete(); break;
                    case 'backup': onBackupNow(); break;
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'archive',
                    child: ListTile(
                      leading: Icon(cashbook.isArchived ? Icons.unarchive_outlined : Icons.archive_outlined),
                      title: Text(cashbook.isArchived ? 'Unarchive' : 'Archive'),
                      dense: true,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'backup',
                    child: ListTile(
                      leading: Icon(Icons.backup_outlined),
                      title: Text('Backup Now'),
                      dense: true,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(Icons.delete_outline, color: Colors.red),
                      title: Text('Delete', style: TextStyle(color: Colors.red)),
                      dense: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 30) return '${diff.inDays}d ago';
    return formatDate(dt);
  }
}
