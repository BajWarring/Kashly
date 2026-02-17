// UI ONLY

import 'package:flutter/material.dart';
import '../models/cashbook.dart';

class CashBookCard extends StatelessWidget {
  final CashBook cashbook;
  final VoidCallback onTap;

  const CashBookCard({
    super.key,
    required this.cashbook,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isPositive = cashbook.isPositive;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.6)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.menu_book_rounded,
                    color: colorScheme.onPrimaryContainer, size: 24),
              ),
              const SizedBox(width: 14),

              // Name & in/out row
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cashbook.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _MiniStat(
                          icon: Icons.arrow_downward_rounded,
                          value: '₹${cashbook.totalIn.toStringAsFixed(0)}',
                          color: const Color(0xFF1B8A3A),
                        ),
                        const SizedBox(width: 10),
                        _MiniStat(
                          icon: Icons.arrow_upward_rounded,
                          value: '₹${cashbook.totalOut.toStringAsFixed(0)}',
                          color: colorScheme.error,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Balance Badge
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isPositive
                          ? Colors.green.withOpacity(0.12)
                          : colorScheme.errorContainer.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      cashbook.formattedBalance,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isPositive
                                ? const Color(0xFF1B8A3A)
                                : colorScheme.error,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;

  const _MiniStat({required this.icon, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: color),
        const SizedBox(width: 3),
        Text(value,
            style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
