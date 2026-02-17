// UI ONLY

import 'package:flutter/material.dart';
import '../models/transaction.dart';

class EntryDetailScreen extends StatelessWidget {
  final Transaction transaction;

  const EntryDetailScreen({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isCashIn = transaction.isCashIn;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Entry Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Edit entry — coming soon')),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: colorScheme.error),
            tooltip: 'Delete',
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Amount Hero Card
            _AmountHeroCard(
              transaction: transaction,
              isCashIn: isCashIn,
              colorScheme: colorScheme,
            ),
            const SizedBox(height: 16),

            // Detail Fields Card
            _DetailCard(
              transaction: transaction,
              colorScheme: colorScheme,
            ),

            const SizedBox(height: 16),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.share_outlined),
                    label: const Text('Share'),
                    onPressed: () {},
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.tonalIcon(
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit Entry'),
                    onPressed: () {},
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        icon: Icon(Icons.delete_forever,
            color: Theme.of(context).colorScheme.error),
        title: const Text('Delete Entry?'),
        content: const Text('This transaction will be permanently deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _AmountHeroCard extends StatelessWidget {
  final Transaction transaction;
  final bool isCashIn;
  final ColorScheme colorScheme;

  const _AmountHeroCard({
    required this.transaction,
    required this.isCashIn,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isCashIn
              ? [const Color(0xFF1B8A3A), const Color(0xFF34C261)]
              : [colorScheme.error, colorScheme.error.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
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
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  isCashIn ? 'Cash In' : 'Cash Out',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '${isCashIn ? '+' : '-'} ₹${transaction.amount.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 36,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _formatFullDate(transaction.dateTime),
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontSize: 14,
            ),
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
    const days = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
    ];
    final hour = dt.hour > 12 ? dt.hour - 12 : dt.hour;
    final min = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '${days[dt.weekday - 1]}, ${dt.day} ${months[dt.month - 1]} ${dt.year} · $hour:$min $period';
  }
}

class _DetailCard extends StatelessWidget {
  final Transaction transaction;
  final ColorScheme colorScheme;

  const _DetailCard({
    required this.transaction,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          _DetailRow(
            icon: Icons.tag,
            label: 'Category',
            value: transaction.category,
            colorScheme: colorScheme,
          ),
          Divider(height: 1, color: colorScheme.outlineVariant),
          _DetailRow(
            icon: Icons.payment,
            label: 'Payment Method',
            value: transaction.paymentMethod,
            colorScheme: colorScheme,
          ),
          Divider(height: 1, color: colorScheme.outlineVariant),
          _DetailRow(
            icon: Icons.calendar_today_outlined,
            label: 'Date',
            value: _formatDate(transaction.dateTime),
            colorScheme: colorScheme,
          ),
          Divider(height: 1, color: colorScheme.outlineVariant),
          _DetailRow(
            icon: Icons.access_time,
            label: 'Time',
            value: _formatTime(transaction.dateTime),
            colorScheme: colorScheme,
          ),
          if (transaction.remarks?.isNotEmpty == true) ...[
            Divider(height: 1, color: colorScheme.outlineVariant),
            _DetailRow(
              icon: Icons.notes,
              label: 'Remarks',
              value: transaction.remarks!,
              colorScheme: colorScheme,
              isMultiline: true,
            ),
          ],
          Divider(height: 1, color: colorScheme.outlineVariant),
          _DetailRow(
            icon: Icons.tag,
            label: 'Entry ID',
            value: transaction.id,
            colorScheme: colorScheme,
            isMonospace: true,
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${dt.day} ${months[dt.month - 1]}, ${dt.year}';
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : dt.hour;
    final min = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$min $period';
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final ColorScheme colorScheme;
  final bool isMultiline;
  final bool isMonospace;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.colorScheme,
    this.isMultiline = false,
    this.isMonospace = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment:
            isMultiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: colorScheme.primary),
          const SizedBox(width: 12),
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontFamily: isMonospace ? 'monospace' : null,
                    color: colorScheme.onSurface,
                  ),
              maxLines: isMultiline ? 5 : 1,
              overflow: isMultiline ? TextOverflow.visible : TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
