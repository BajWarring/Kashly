import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kashly/core/di/providers.dart';
import 'package:kashly/core/utils/icons.dart';
import 'package:kashly/core/utils/utils.dart';
import 'package:kashly/core/theme/app_theme.dart';
import 'package:kashly/domain/entities/cashbook.dart';
import 'package:kashly/domain/entities/transaction.dart';
import 'package:kashly/ux_and_ui_elements/dialogs.dart';

class CashbookDetailPage extends ConsumerStatefulWidget {
  final String id;
  const CashbookDetailPage({super.key, required this.id});

  @override
  ConsumerState<CashbookDetailPage> createState() => _CashbookDetailPageState();
}

class _CashbookDetailPageState extends ConsumerState<CashbookDetailPage> {
  String _searchQuery = '';
  int _pageSize = 30;
  int _loadedCount = 30;

  @override
  Widget build(BuildContext context) {
    final cashbookAsync = ref.watch(cashbookDetailProvider(widget.id));
    final transactionsAsync = ref.watch(transactionsProvider(widget.id));
    final balanceAsync = ref.watch(cashbookBalanceProvider(widget.id));
    final totalInAsync = ref.watch(cashbookTotalInProvider(widget.id));
    final totalOutAsync = ref.watch(cashbookTotalOutProvider(widget.id));

    return cashbookAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (cashbook) {
        if (cashbook == null) {
          return const Scaffold(body: Center(child: Text('Cashbook not found')));
        }
        return Scaffold(
          appBar: AppBar(
            title: Text(cashbook.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            actions: [
              IconButton(
                icon: const Icon(Icons.backup_outlined),
                tooltip: 'Backup Now',
                onPressed: () => ref.read(backupServiceProvider).manualBackup(context),
              ),
              PopupMenuButton<String>(
                onSelected: (v) => _handleAction(context, ref, cashbook, v),
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit_outlined), title: Text('Edit'), dense: true)),
                  const PopupMenuItem(value: 'archive', child: ListTile(leading: Icon(Icons.archive_outlined), title: Text('Archive'), dense: true)),
                  const PopupMenuItem(value: 'export', child: ListTile(leading: Icon(Icons.download_outlined), title: Text('Export CSV'), dense: true)),
                  const PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete_outline, color: Colors.red), title: Text('Delete', style: TextStyle(color: Colors.red)), dense: true)),
                ],
              ),
            ],
          ),
          body: Column(
            children: [
              // Summary cards
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(child: _SummaryCard(label: 'Balance', valueAsync: balanceAsync, currency: cashbook.currency, isMain: true)),
                    const SizedBox(width: 8),
                    Expanded(child: _SummaryCard(label: 'In', valueAsync: totalInAsync, currency: cashbook.currency, color: AppColors.cashIn)),
                    const SizedBox(width: 8),
                    Expanded(child: _SummaryCard(label: 'Out', valueAsync: totalOutAsync, currency: cashbook.currency, color: AppColors.cashOut)),
                  ],
                ),
              ),
              // Per cashbook backup toggle
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                child: SwitchListTile(
                  dense: true,
                  title: const Text('Auto Backup', style: TextStyle(fontSize: 14)),
                  subtitle: cashbook.backupSettings.lastBackupAt != null
                      ? Text('Last: ${formatDate(cashbook.backupSettings.lastBackupAt!)}', style: const TextStyle(fontSize: 12))
                      : const Text('Never backed up', style: TextStyle(fontSize: 12)),
                  secondary: getSyncStatusIcon(cashbook.syncStatus.name),
                  value: cashbook.backupSettings.autoBackupEnabled,
                  onChanged: (v) => _toggleAutoBackup(ref, cashbook, v),
                ),
              ),
              // Search bar
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search transactions...',
                    prefixIcon: Icon(Icons.search, size: 18),
                    isDense: true,
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
              ),
              const Divider(height: 12),
              // Transaction list
              Expanded(
                child: transactionsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Error: $e')),
                  data: (transactions) {
                    var filtered = transactions;
                    if (_searchQuery.isNotEmpty) {
                      final q = _searchQuery.toLowerCase();
                      filtered = transactions.where((t) =>
                        t.category.toLowerCase().contains(q) ||
                        t.remark.toLowerCase().contains(q) ||
                        t.method.toLowerCase().contains(q)
                      ).toList();
                    }

                    if (filtered.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey),
                            const SizedBox(height: 12),
                            const Text('No transactions yet', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      );
                    }

                    double runningBalance = cashbook.openingBalance;
                    final txsWithBalance = <Map<String, dynamic>>[];
                    // Build running balance (oldest first, display newest first)
                    final sorted = [...filtered]..sort((a, b) => a.date.compareTo(b.date));
                    for (final tx in sorted) {
                      if (tx.type == TransactionType.cashIn) {
                        runningBalance += tx.amount;
                      } else {
                        runningBalance -= tx.amount;
                      }
                      txsWithBalance.add({'tx': tx, 'balance': runningBalance});
                    }

                    final displayList = txsWithBalance.reversed.take(_loadedCount).toList();

                    return RefreshIndicator(
                      onRefresh: () async {
                        ref.invalidate(transactionsProvider(widget.id));
                        ref.invalidate(cashbookBalanceProvider(widget.id));
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: displayList.length + (txsWithBalance.length > _loadedCount ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == displayList.length) {
                            return TextButton(
                              onPressed: () => setState(() => _loadedCount += _pageSize),
                              child: const Text('Load more'),
                            );
                          }
                          final tx = displayList[index]['tx'] as Transaction;
                          final balance = displayList[index]['balance'] as double;
                          return _TransactionTile(
                            transaction: tx,
                            runningBalance: balance,
                            currency: cashbook.currency,
                            onTap: () => context.push('/transactions/${tx.id}'),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          floatingActionButton: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FloatingActionButton.small(
                heroTag: 'quick',
                onPressed: () => context.push('/transactions/entry', extra: {'cashbookId': widget.id}),
                backgroundColor: Colors.teal,
                child: const Icon(Icons.flash_on),
              ),
              const SizedBox(height: 8),
              FloatingActionButton.extended(
                heroTag: 'cashout',
                onPressed: () => context.push('/transactions/entry', extra: {'cashbookId': widget.id, 'type': 'cashOut'}),
                backgroundColor: AppColors.cashOut,
                icon: const Icon(Icons.arrow_upward),
                label: const Text('Out'),
              ),
              const SizedBox(height: 8),
              FloatingActionButton.extended(
                heroTag: 'cashin',
                onPressed: () => context.push('/transactions/entry', extra: {'cashbookId': widget.id, 'type': 'cashIn'}),
                backgroundColor: AppColors.cashIn,
                icon: const Icon(Icons.arrow_downward),
                label: const Text('In'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _handleAction(BuildContext context, WidgetRef ref, Cashbook cashbook, String action) async {
    switch (action) {
      case 'archive':
        await ref.read(cashbookRepositoryProvider).archiveCashbook(cashbook.id, !cashbook.isArchived);
        ref.invalidate(cashbookDetailProvider(cashbook.id));
        break;
      case 'delete':
        final confirmed = await showDeleteConfirmation(context, cashbook.name);
        if (confirmed == true && context.mounted) {
          await ref.read(cashbookRepositoryProvider).deleteCashbook(cashbook.id);
          ref.invalidate(cashbooksProvider);
          if (context.mounted) context.go('/cashbooks');
        }
        break;
    }
  }

  void _toggleAutoBackup(WidgetRef ref, Cashbook cashbook, bool value) async {
    final updated = cashbook.copyWith(
      backupSettings: cashbook.backupSettings.copyWith(autoBackupEnabled: value),
    );
    await ref.read(cashbookRepositoryProvider).updateCashbook(updated);
    ref.invalidate(cashbookDetailProvider(cashbook.id));
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final AsyncValue<double> valueAsync;
  final String currency;
  final bool isMain;
  final Color? color;

  const _SummaryCard({
    required this.label,
    required this.valueAsync,
    required this.currency,
    this.isMain = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isMain ? const Color(0xFF1A73E8).withOpacity(0.15) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 11, color: color ?? Colors.grey)),
            const SizedBox(height: 4),
            valueAsync.when(
              data: (v) => Text(
                formatCurrency(v, currency),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: color ?? (isMain ? const Color(0xFF1A73E8) : null),
                ),
                overflow: TextOverflow.ellipsis,
              ),
              loading: () => const SizedBox(height: 14, width: 40, child: LinearProgressIndicator()),
              error: (_, __) => const Text('--'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final Transaction transaction;
  final double runningBalance;
  final String currency;
  final VoidCallback onTap;

  const _TransactionTile({
    required this.transaction,
    required this.runningBalance,
    required this.currency,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isIn = transaction.type == TransactionType.cashIn;
    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: (isIn ? AppColors.cashIn : AppColors.cashOut).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isIn ? Icons.arrow_downward : Icons.arrow_upward,
                  size: 18,
                  color: isIn ? AppColors.cashIn : AppColors.cashOut,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.category.isNotEmpty ? transaction.category : 'Uncategorized',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    if (transaction.remark.isNotEmpty)
                      Text(transaction.remark, style: const TextStyle(fontSize: 11, color: Colors.grey), overflow: TextOverflow.ellipsis),
                    Text(formatDateShort(transaction.date), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${isIn ? '+' : '-'}${formatCurrency(transaction.amount, '')}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: isIn ? AppColors.cashIn : AppColors.cashOut,
                    ),
                  ),
                  Text(
                    formatCurrency(runningBalance, currency),
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (transaction.hasAttachment) const Icon(Icons.attach_file, size: 12, color: Colors.grey),
                      if (transaction.isReconciled) const Icon(Icons.check_circle, size: 12, color: Colors.teal),
                      getSyncStatusIcon(transaction.syncStatus.name, size: 12),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
