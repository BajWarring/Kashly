import 'package:flutter/material.dart';
import '../models/cashbook.dart';

class BalanceSummaryCard extends StatelessWidget {
  final CashBook cashbook;
  const BalanceSummaryCard({super.key, required this.cashbook});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isPositive = cashbook.isPositive;
    return Card(
      elevation: 0, color: cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(padding: const EdgeInsets.all(20), child: Column(children: [
        Row(children: [
          Container(padding: const EdgeInsets.all(11), decoration: BoxDecoration(color: isPositive ? const Color(0xFF1B8A3A).withValues(alpha: 0.12) : cs.errorContainer.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(14)), child: Icon(Icons.account_balance_wallet_rounded, color: isPositive ? const Color(0xFF1B8A3A) : cs.error, size: 22)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Overall Balance', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: cs.onSurfaceVariant)),
            const SizedBox(height: 2),
            Text('${isPositive ? '+' : '−'} ₹${cashbook.balance.abs().toStringAsFixed(2)}', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5, color: isPositive ? const Color(0xFF1B8A3A) : cs.error)),
          ])),
        ]),
        const SizedBox(height: 16),
        Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.6)),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: _StatColumn(label: 'Total In', amount: cashbook.totalIn, icon: Icons.arrow_downward_rounded, isIn: true, cs: cs)),
          Container(width: 1, height: 52, color: cs.outlineVariant.withValues(alpha: 0.5)),
          Expanded(child: _StatColumn(label: 'Total Out', amount: cashbook.totalOut, icon: Icons.arrow_upward_rounded, isIn: false, cs: cs)),
        ]),
      ])),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label; final double amount; final IconData icon; final bool isIn; final ColorScheme cs;
  const _StatColumn({required this.label, required this.amount, required this.icon, required this.isIn, required this.cs});
  @override
  Widget build(BuildContext context) {
    final color = isIn ? const Color(0xFF1B8A3A) : cs.error;
    return Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(padding: const EdgeInsets.all(5), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle), child: Icon(icon, size: 13, color: color)),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: cs.onSurfaceVariant)),
      ]),
      const SizedBox(height: 5),
      Text('₹${amount.toStringAsFixed(2)}', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: color, letterSpacing: -0.3)),
    ]);
  }
}
