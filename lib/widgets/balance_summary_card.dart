// UI ONLY

import 'package:flutter/material.dart';
import '../models/cashbook.dart';

class BalanceSummaryCard extends StatelessWidget {
  final CashBook cashbook;

  const BalanceSummaryCard({super.key, required this.cashbook});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isPositive = cashbook.isPositive;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Overall balance
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isPositive
                        ? colorScheme.primaryContainer
                        : colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isPositive
                        ? Icons.account_balance_wallet_outlined
                        : Icons.warning_amber_rounded,
                    color: isPositive
                        ? colorScheme.onPrimaryContainer
                        : colorScheme.onErrorContainer,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Overall Balance',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${isPositive ? '+' : '-'} ₹${cashbook.balance.abs().toStringAsFixed(2)}',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isPositive
                                  ? const Color(0xFF1B8A3A)
                                  : colorScheme.error,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            Divider(color: colorScheme.outlineVariant),
            const SizedBox(height: 12),

            // In and Out row
            Row(
              children: [
                Expanded(
                  child: _StatBox(
                    label: 'Total In',
                    amount: cashbook.totalIn,
                    isIn: true,
                    colorScheme: colorScheme,
                  ),
                ),
                Container(
                  width: 1,
                  height: 48,
                  color: colorScheme.outlineVariant,
                ),
                Expanded(
                  child: _StatBox(
                    label: 'Total Out',
                    amount: cashbook.totalOut,
                    isIn: false,
                    colorScheme: colorScheme,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final double amount;
  final bool isIn;
  final ColorScheme colorScheme;

  const _StatBox({
    required this.label,
    required this.amount,
    required this.isIn,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isIn
                    ? Colors.green.withOpacity(0.15)
                    : Colors.red.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isIn ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                size: 14,
                color: isIn ? const Color(0xFF1B8A3A) : colorScheme.error,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '₹${amount.toStringAsFixed(2)}',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isIn ? const Color(0xFF1B8A3A) : colorScheme.error,
              ),
        ),
      ],
    );
  }
}
