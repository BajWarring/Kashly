// UI ONLY

import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../models/edit_log.dart';
import '../logic/cashbook_logic.dart';

class EntryDetailScreen extends StatelessWidget {
  final Transaction transaction;
  final String cashbookId;

  const EntryDetailScreen({
    super.key,
    required this.transaction,
    required this.cashbookId,
  });

  // Edit history is empty until a real edit layer is wired
  List<EditLog> get _editLogs => [];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isCashIn = transaction.isCashIn;
    final editLogs = _editLogs;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        scrolledUnderElevation: 2,
        title: const Text('Entry Details',
            style: TextStyle(fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share',
            onPressed: () => _showShareOptions(context, editLogs),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: colorScheme.error),
            tooltip: 'Delete',
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AmountHeroCard(
                transaction: transaction,
                isCashIn: isCashIn,
                colorScheme: colorScheme),
            const SizedBox(height: 16),
            _FullDetailCard(
                transaction: transaction, colorScheme: colorScheme),
            const SizedBox(height: 24),

            _SectionHeader(
              icon: Icons.add_circle_outline_rounded,
              label: 'Created',
              color: colorScheme.primary,
            ),
            const SizedBox(height: 8),
            _TimelineCard(
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline,
                      size: 16, color: colorScheme.primary),
                  const SizedBox(width: 10),
                  Text(
                    'Entry created on ${_formatFullDate(transaction.dateTime)}',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: colorScheme.onSurface),
                  ),
                ],
              ),
              colorScheme: colorScheme,
            ),
            const SizedBox(height: 20),

            _SectionHeader(
              icon: Icons.history_rounded,
              label: 'Edit History',
              color: colorScheme.tertiary,
              trailing: editLogs.isEmpty
                  ? null
                  : Text(
                      '${editLogs.length} edit${editLogs.length == 1 ? '' : 's'}',
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
            ),
            const SizedBox(height: 8),

            if (editLogs.isEmpty)
              _TimelineCard(
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 16, color: colorScheme.onSurfaceVariant),
                    const SizedBox(width: 10),
                    Text('No edits made to this entry',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: colorScheme.onSurfaceVariant)),
                  ],
                ),
                colorScheme: colorScheme,
              )
            else
              ...editLogs.asMap().entries.map(
                    (e) => _EditLogTile(
                      log: e.value,
                      index: e.key + 1,
                      isLast: e.key == editLogs.length - 1,
                      colorScheme: colorScheme,
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  void _showShareOptions(BuildContext context, List<EditLog> logs) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant
                    .withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text('Share Entry',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w600)),
            ),
            ListTile(
              leading: const Icon(Icons.share_outlined),
              title: const Text('Share entry (without edit logs)'),
              subtitle: const Text('Default — clean summary only'),
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        icon: Icon(Icons.delete_forever_rounded,
            color: Theme.of(context).colorScheme.error, size: 32),
        title: const Text('Delete Entry?'),
        content: const Text(
            'This transaction will be permanently removed.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor:
                    Theme.of(context).colorScheme.error),
            onPressed: () async {
              Navigator.pop(context);
              await CashbookLogic.deleteTransaction(
                  transaction.id, cashbookId);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _formatFullDate(DateTime dt) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final hour =
        dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final min = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}, $hour:$min $period';
  }
}

// ── Amount hero card ────────────────────────────────────────────────────────

class _AmountHeroCard extends StatelessWidget {
  final Transaction transaction;
  final bool isCashIn;
  final ColorScheme colorScheme;

  const _AmountHeroCard(
      {required this.transaction,
      required this.isCashIn,
      required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isCashIn
              ? [const Color(0xFF0E6027), const Color(0xFF1B8A3A)]
              : [colorScheme.error.withValues(alpha: 0.85), colorScheme.error],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (isCashIn ? const Color(0xFF1B8A3A) : colorScheme.error)
                .withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isCashIn
                      ? Icons.arrow_downward_rounded
                      : Icons.arrow_upward_rounded,
                  color: Colors.white,
                  size: 15,
                ),
                const SizedBox(width: 6),
                Text(
                  isCashIn ? 'Cash In' : 'Cash Out',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            '${isCashIn ? '+' : '−'} ₹${transaction.amount.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 38,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _formatFullDate(transaction.dateTime),
            style:
                TextStyle(color: Colors.white.withValues(alpha: 0.82), fontSize: 13),
          ),
        ],
      ),
    );
  }

  String _formatFullDate(DateTime dt) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final hour = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final min = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '${days[dt.weekday - 1]}, ${dt.day} ${months[dt.month - 1]} ${dt.year} · $hour:$min $period';
  }
}

// ── Full detail card ─────────────────────────────────────────────────────────

class _FullDetailCard extends StatelessWidget {
  final Transaction transaction;
  final ColorScheme colorScheme;

  const _FullDetailCard(
      {required this.transaction, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    final rows = <_DetailRow>[
      _DetailRow(icon: Icons.tag_rounded, label: 'Category', value: transaction.category),
      _DetailRow(icon: Icons.payment_rounded, label: 'Payment', value: transaction.paymentMethod),
      _DetailRow(icon: Icons.calendar_today_outlined, label: 'Date', value: _fmtDate(transaction.dateTime)),
      _DetailRow(icon: Icons.access_time_rounded, label: 'Time', value: _fmtTime(transaction.dateTime)),
      if (transaction.remarks?.isNotEmpty == true)
        _DetailRow(icon: Icons.notes_rounded, label: 'Remarks', value: transaction.remarks!, isMultiline: true),
      _DetailRow(icon: Icons.numbers_rounded, label: 'Entry ID', value: transaction.id, isMono: true),
      _DetailRow(
        icon: transaction.isCashIn ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
        label: 'Entry Type',
        value: transaction.isCashIn ? 'Cash In' : 'Cash Out',
      ),
    ];

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Column(
        children: rows.asMap().entries.map((e) {
          final isLast = e.key == rows.length - 1;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                child: Row(
                  crossAxisAlignment: e.value.isMultiline
                      ? CrossAxisAlignment.start
                      : CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Icon(e.value.icon, size: 16, color: colorScheme.primary),
                    ),
                    const SizedBox(width: 14),
                    SizedBox(
                      width: 80,
                      child: Text(e.value.label,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              )),
                    ),
                    Expanded(
                      child: Text(
                        e.value.value,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              fontFamily: e.value.isMono ? 'monospace' : null,
                            ),
                        maxLines: e.value.isMultiline ? null : 1,
                        overflow: e.value.isMultiline
                            ? TextOverflow.visible
                            : TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Divider(height: 1, indent: 18, endIndent: 18,
                    color: colorScheme.outlineVariant.withValues(alpha: 0.6)),
            ],
          );
        }).toList(),
      ),
    );
  }

  String _fmtDate(DateTime dt) {
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${dt.day} ${m[dt.month - 1]}, ${dt.year}';
  }

  String _fmtTime(DateTime dt) {
    final h = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final min = dt.minute.toString().padLeft(2, '0');
    return '$h:$min ${dt.hour >= 12 ? 'PM' : 'AM'}';
  }
}

class _DetailRow {
  final IconData icon;
  final String label;
  final String value;
  final bool isMultiline;
  final bool isMono;
  const _DetailRow(
      {required this.icon,
      required this.label,
      required this.value,
      this.isMultiline = false,
      this.isMono = false});
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Widget? trailing;

  const _SectionHeader(
      {required this.icon,
      required this.label,
      required this.color,
      this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 7),
        Text(label,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: color,
                )),
        if (trailing != null) ...[const Spacer(), trailing!],
      ],
    );
  }
}

// ── Timeline card ─────────────────────────────────────────────────────────────

class _TimelineCard extends StatelessWidget {
  final Widget child;
  final ColorScheme colorScheme;

  const _TimelineCard({required this.child, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: child,
    );
  }
}

// ── Edit log tile ─────────────────────────────────────────────────────────────

class _EditLogTile extends StatelessWidget {
  final EditLog log;
  final int index;
  final bool isLast;
  final ColorScheme colorScheme;

  const _EditLogTile({
    required this.log,
    required this.index,
    required this.isLast,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colorScheme.tertiaryContainer),
        ),
        color: colorScheme.tertiaryContainer.withValues(alpha: 0.3),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: colorScheme.tertiaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('Edit #$index',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onTertiaryContainer,
                        )),
                  ),
                  const Spacer(),
                  Icon(Icons.history_rounded, size: 13, color: colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(_formatEditDate(log.editedAt),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          )),
                ],
              ),
              const SizedBox(height: 10),
              ...log.changes.map((change) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _FieldChangeTile(
                        change: change, colorScheme: colorScheme),
                  )),
            ],
          ),
        ),
      ),
    );
  }

  String _formatEditDate(DateTime dt) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final h = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}, $h:$m ${dt.hour >= 12 ? 'PM' : 'AM'}';
  }
}

class _FieldChangeTile extends StatelessWidget {
  final FieldChange change;
  final ColorScheme colorScheme;

  const _FieldChangeTile(
      {required this.change, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(change.fieldName,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.tertiary,
                  )),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Before',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            )),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: colorScheme.errorContainer.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(change.before,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: colorScheme.error,
                                fontWeight: FontWeight.w600,
                              )),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.arrow_forward_rounded,
                    size: 16, color: colorScheme.onSurfaceVariant),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('After',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            )),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B8A3A).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(change.after,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: const Color(0xFF1B8A3A),
                                fontWeight: FontWeight.w600,
                              )),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
