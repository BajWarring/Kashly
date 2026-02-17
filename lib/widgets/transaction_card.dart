import 'package:flutter/material.dart';
import '../models/transaction.dart';

class TransactionCard extends StatelessWidget {
  final Transaction transaction;
  final double? runningBalance;
  final VoidCallback onTap;
  const TransactionCard({super.key, required this.transaction, required this.onTap, this.runningBalance});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isCashIn = transaction.isCashIn;
    final hasRemarks = transaction.remarks?.isNotEmpty == true;
    final hasEdits = transaction.editHistory.isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 8), elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.6))),
      color: cs.surface,
      child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(16), child: Padding(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 44, height: 44, margin: const EdgeInsets.only(top: 2), decoration: BoxDecoration(color: isCashIn ? const Color(0xFF1B8A3A).withValues(alpha: 0.1) : cs.errorContainer.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(12)), child: Icon(isCashIn ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded, color: isCashIn ? const Color(0xFF1B8A3A) : cs.error, size: 20)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(hasRemarks ? transaction.remarks! : transaction.category, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: cs.onSurface), maxLines: 1, overflow: TextOverflow.ellipsis)),
            if (hasEdits) Padding(padding: const EdgeInsets.only(left: 4), child: Icon(Icons.edit_rounded, size: 12, color: cs.tertiary)),
          ]),
          const SizedBox(height: 5),
          Wrap(spacing: 6, runSpacing: 4, children: [
            _Chip(icon: Icons.category_outlined, label: transaction.category, cs: cs),
            _Chip(icon: Icons.payment_rounded, label: transaction.paymentMethod, cs: cs),
          ]),
          const SizedBox(height: 5),
          Text(_fmtTime(transaction.dateTime), style: Theme.of(context).textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
        ])),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('${isCashIn ? '+' : '−'} ₹${transaction.amount.toStringAsFixed(2)}', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: isCashIn ? const Color(0xFF1B8A3A) : cs.error)),
          if (runningBalance != null) ...[
            const SizedBox(height: 4),
            Row(mainAxisSize: MainAxisSize.min, children: [
              Text('Bal ', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
              Text('₹${runningBalance!.abs().toStringAsFixed(2)}', style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600, color: runningBalance! >= 0 ? const Color(0xFF1B8A3A) : cs.error)),
            ]),
          ],
        ]),
      ]))),
    );
  }

  String _fmtTime(DateTime dt) {
    final h = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final min = dt.minute.toString().padLeft(2, '0');
    return '$h:$min ${dt.hour >= 12 ? 'PM' : 'AM'}';
  }
}

class _Chip extends StatelessWidget {
  final IconData icon; final String label; final ColorScheme cs;
  const _Chip({required this.icon, required this.label, required this.cs});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(color: cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(6)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 10, color: cs.onSurfaceVariant), const SizedBox(width: 3), Text(label, style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant, fontWeight: FontWeight.w500))]),
  );
}
