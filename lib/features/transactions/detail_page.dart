import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kashly/core/di/providers.dart';
import 'package:kashly/core/utils/icons.dart';
import 'package:kashly/core/utils/utils.dart';
import 'package:kashly/core/theme/app_theme.dart';
import 'package:kashly/domain/entities/transaction.dart';
import 'package:kashly/domain/entities/transaction_history.dart';
import 'package:kashly/ux_and_ui_elements/dialogs.dart';
import 'package:kashly/services/sync_engine/sync_service.dart';

class TransactionDetailPage extends ConsumerWidget {
  final String id;
  const TransactionDetailPage({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txAsync = ref.watch(transactionDetailProvider(id));

    return txAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (tx) {
        if (tx == null) {
          return const Scaffold(body: Center(child: Text('Transaction not found')));
        }
        return Scaffold(
          appBar: AppBar(
            title: const Text('Transaction Detail'),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => context.push('/transactions/entry', extra: {'cashbookId': tx.cashbookId, 'transaction': tx}),
              ),
              PopupMenuButton<String>(
                onSelected: (v) => _handleAction(context, ref, tx, v),
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'reconcile',
                    child: ListTile(
                      leading: Icon(tx.isReconciled ? Icons.check_circle : Icons.check_circle_outline),
                      title: Text(tx.isReconciled ? 'Unreconcile' : 'Mark Reconciled'),
                      dense: true,
                    ),
                  ),
                  const PopupMenuItem(value: 'sync', child: ListTile(leading: Icon(Icons.sync), title: Text('Sync Now'), dense: true)),
                  const PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete_outline, color: Colors.red), title: Text('Delete', style: TextStyle(color: Colors.red)), dense: true)),
                ],
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Amount card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            tx.type == TransactionType.cashIn ? Icons.arrow_downward : Icons.arrow_upward,
                            color: tx.type == TransactionType.cashIn ? AppColors.cashIn : AppColors.cashOut,
                            size: 28,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${tx.type == TransactionType.cashIn ? '+' : '-'}${formatCurrency(tx.amount, '')}',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: tx.type == TransactionType.cashIn ? AppColors.cashIn : AppColors.cashOut,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(tx.category, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                      if (tx.remark.isNotEmpty) Text(tx.remark, style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Details
              Card(
                child: Column(
                  children: [
                    _DetailRow(icon: Icons.calendar_today_outlined, label: 'Date', value: formatDate(tx.date)),
                    const Divider(height: 1),
                    _DetailRow(icon: Icons.payment_outlined, label: 'Method', value: tx.method),
                    const Divider(height: 1),
                    _DetailRow(icon: Icons.access_time_outlined, label: 'Created', value: formatDateTime(tx.createdAt)),
                    const Divider(height: 1),
                    _DetailRow(icon: Icons.update_outlined, label: 'Updated', value: formatDateTime(tx.updatedAt)),
                    if (tx.isReconciled) ...[
                      const Divider(height: 1),
                      const _DetailRow(icon: Icons.check_circle, label: 'Status', value: 'Reconciled', iconColor: Colors.teal),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Sync status
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Sync Status', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          getSyncStatusIconFromEnum(tx.syncStatus),
                          const SizedBox(width: 8),
                          Text(tx.syncStatus.name.toUpperCase(), style: TextStyle(color: getSyncStatusColor(tx.syncStatus.name))),
                        ],
                      ),
                      if (tx.driveMeta.fileId != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            getDriveFileIcon('drive_ok'),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(tx.driveMeta.driveFileName ?? 'Drive file', style: const TextStyle(fontSize: 12)),
                                  if (tx.driveMeta.lastSyncedAt != null)
                                    Text('Synced: ${formatDateTime(tx.driveMeta.lastSyncedAt!)}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                  if (tx.driveMeta.md5Checksum != null)
                                    Text('MD5: ${tx.driveMeta.md5Checksum!.substring(0, 8)}...', style: const TextStyle(fontSize: 10, color: Colors.grey, fontFamily: 'monospace')),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (tx.driveMeta.isModifiedSinceUpload) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('Modified since last upload', style: TextStyle(fontSize: 12, color: Colors.amber)),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Edit history
              _HistorySection(transactionId: tx.id),
            ],
          ),
        );
      },
    );
  }

  void _handleAction(BuildContext context, WidgetRef ref, Transaction tx, String action) async {
    switch (action) {
      case 'reconcile':
        await ref.read(transactionRepositoryProvider).reconcileTransaction(tx.id, !tx.isReconciled);
        ref.invalidate(transactionDetailProvider(tx.id));
        if (context.mounted) showSuccessSnackbar(context, tx.isReconciled ? 'Unreconciled' : 'Marked as reconciled');
        break;
      case 'sync':
        await ref.read(syncServiceProvider).triggerSync(SyncTrigger.manual);
        ref.invalidate(transactionDetailProvider(tx.id));
        if (context.mounted) showSuccessSnackbar(context, 'Sync triggered');
        break;
      case 'delete':
        final confirmed = await showDeleteConfirmation(context, 'this transaction');
        if (confirmed == true) {
          await ref.read(transactionRepositoryProvider).deleteTransaction(tx.id);
          ref.invalidate(transactionsProvider(tx.cashbookId));
          ref.invalidate(cashbookBalanceProvider(tx.cashbookId));
          ref.invalidate(nonUploadedTransactionsProvider);
          if (context.mounted) {
            showSuccessSnackbar(context, 'Transaction deleted');
            context.pop();
          }
        }
        break;
    }
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? iconColor;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: Icon(icon, size: 18, color: iconColor),
      title: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      trailing: Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
    );
  }
}

class _HistorySection extends ConsumerWidget {
  final String transactionId;
  const _HistorySection({required this.transactionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Using a simple FutureBuilder-style provider
    return FutureBuilder<List<TransactionHistory>>(
      future: ref.read(transactionRepositoryProvider).getHistory(transactionId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }
        final history = snapshot.data!;
        return Card(
          child: ExpansionTile(
            title: Text('Edit History (${history.length})', style: const TextStyle(fontWeight: FontWeight.w600)),
            leading: const Icon(Icons.history_outlined),
            children: history.map((h) => ListTile(
              dense: true,
              title: RichText(
                text: TextSpan(
                  style: DefaultTextStyle.of(context).style.copyWith(fontSize: 13),
                  children: [
                    TextSpan(text: h.fieldName, style: const TextStyle(fontWeight: FontWeight.w600)),
                    const TextSpan(text: ': '),
                    TextSpan(text: h.oldValue, style: const TextStyle(color: Colors.red, decoration: TextDecoration.lineThrough)),
                    const TextSpan(text: ' → '),
                    TextSpan(text: h.newValue, style: const TextStyle(color: Colors.green)),
                  ],
                ),
              ),
              subtitle: Text('${h.changedBy} · ${formatDateTime(h.changedAt)}', style: const TextStyle(fontSize: 11)),
            )).toList(),
          ),
        );
      },
    );
  }
}
