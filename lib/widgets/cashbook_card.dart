// UI ONLY

import 'package:flutter/material.dart';
import '../models/cashbook.dart';

class CashBookCard extends StatelessWidget {
  final CashBook cashbook;
  final VoidCallback onTap;

  const CashBookCard({super.key, required this.cashbook, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isPositive = cashbook.isPositive;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.7)),
      ),
      color: colorScheme.surface,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Book icon with initial
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    cashbook.name.isNotEmpty ? cashbook.name[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Name + in/out stats
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cashbook.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _InOutBadge(
                          icon: Icons.arrow_downward_rounded,
                          value: '₹${_fmt(cashbook.totalIn)}',
                          color: const Color(0xFF1B8A3A),
                          bg: const Color(0xFF1B8A3A).withOpacity(0.1),
                        ),
                        const SizedBox(width: 8),
                        _InOutBadge(
                          icon: Icons.arrow_upward_rounded,
                          value: '₹${_fmt(cashbook.totalOut)}',
                          color: colorScheme.error,
                          bg: colorScheme.errorContainer.withOpacity(0.5),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Balance
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isPositive
                          ? const Color(0xFF1B8A3A).withOpacity(0.1)
                          : colorScheme.errorContainer.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${isPositive ? '+' : '−'} ₹${_fmt(cashbook.balance.abs())}',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: isPositive ? const Color(0xFF1B8A3A) : colorScheme.error,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Icon(Icons.chevron_right_rounded, size: 18, color: colorScheme.onSurfaceVariant),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _fmt(double v) {
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}

class _InOutBadge extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;
  final Color bg;

  const _InOutBadge({required this.icon, required this.value, required this.color, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 3),
          Text(value, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
