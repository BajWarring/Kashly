import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kashly/core/di/providers.dart';
import 'package:kashly/core/theme/app_theme.dart';
import 'package:kashly/core/utils/utils.dart';
import 'package:kashly/core/utils/icons.dart';
import 'package:kashly/domain/entities/cashbook.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cashbooksAsync = ref.watch(cashbooksProvider);
    final nonUploadedAsync = ref.watch(nonUploadedTransactionsProvider);
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kashly', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: authState.isAuthenticated
                ? const Icon(Icons.account_circle, color: Colors.green)
                : const Icon(Icons.account_circle_outlined),
            onPressed: () => context.go('/auth'),
            tooltip: authState.isAuthenticated ? authState.user?.email : 'Sign In',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(cashbooksProvider);
          ref.invalidate(nonUploadedTransactionsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Drive status banner
            if (!authState.isAuthenticated)
              _DriveStatusBanner(onTap: () => context.go('/auth')),

            // Summary cards
            cashbooksAsync.when(
              data: (cashbooks) => _SummaryCards(cashbooks: cashbooks),
              loading: () => const SizedBox(height: 100, child: Center(child: CircularProgressIndicator())),
              error: (e, _) => Text('Error: $e'),
            ),
            const SizedBox(height: 16),

            // Pending uploads alert
            nonUploadedAsync.when(
              data: (pending) => pending.isNotEmpty
                  ? _PendingUploadsCard(count: pending.length, onTap: () => context.go('/backup_center'))
                  : const SizedBox.shrink(),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),

            // Charts section
            cashbooksAsync.when(
              data: (cashbooks) => cashbooks.isNotEmpty
                  ? Column(
                      children: [
                        const _SectionHeader(title: 'Cash Flow', onAction: null),
                        _CashFlowChart(cashbooks: cashbooks),
                        const SizedBox(height: 16),
                        _SectionHeader(title: 'My Cashbooks', onAction: () => context.go('/cashbooks')),
                        ...cashbooks.take(3).map((cb) => _CashbookSummaryTile(cashbook: cb)),
                        if (cashbooks.length > 3)
                          TextButton(
                            onPressed: () => context.go('/cashbooks'),
                            child: Text('View all ${cashbooks.length} cashbooks'),
                          ),
                      ],
                    )
                  : _EmptyDashboard(onCreateCashbook: () => context.go('/cashbooks')),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _DriveStatusBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _DriveStatusBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.orange.shade900.withValues(alpha: 0.3),
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: const Icon(Icons.cloud_off, color: Colors.orange),
        title: const Text('Drive not connected', style: TextStyle(fontWeight: FontWeight.w600)),
        subtitle: const Text('Tap to enable automatic backup'),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _SummaryCards extends ConsumerWidget {
  final List<Cashbook> cashbooks;
  const _SummaryCards({required this.cashbooks});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    double totalBalance = 0;
    for (final cb in cashbooks) {
      totalBalance += cb.openingBalance;
    }

    return Row(
      children: [
        Expanded(
          child: _MetricCard(
            label: 'Total Balance',
            value: formatCurrency(totalBalance, ''),
            icon: Icons.account_balance_wallet_outlined,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MetricCard(
            label: 'Cashbooks',
            value: cashbooks.length.toString(),
            icon: Icons.book_outlined,
            color: Colors.teal,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MetricCard(
            label: 'Pending Sync',
            value: cashbooks.where((c) => c.syncStatus != SyncStatus.synced).length.toString(),
            icon: Icons.sync_problem_outlined,
            color: Colors.orange,
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class _PendingUploadsCard extends StatelessWidget {
  final int count;
  final VoidCallback onTap;
  const _PendingUploadsCard({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.amber.shade900.withValues(alpha: 0.2),
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: const Icon(Icons.cloud_upload_outlined, color: Colors.amber),
        title: Text('$count entries pending upload', style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: const Text('Tap to open Backup Center'),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onAction;
  const _SectionHeader({required this.title, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          if (onAction != null)
            TextButton(onPressed: onAction, child: const Text('See all')),
        ],
      ),
    );
  }
}

class _CashFlowChart extends StatelessWidget {
  final List<Cashbook> cashbooks;
  const _CashFlowChart({required this.cashbooks});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 160,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) => FlLine(color: AppColors.divider, strokeWidth: 0.5),
              ),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (v, _) => Text(
                      ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'][v.toInt() % 6],
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                    interval: 1,
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: List.generate(6, (i) => FlSpot(i.toDouble(), (i * 1200 + 3000).toDouble())),
                  isCurved: true,
                  color: AppColors.cashIn,
                  barWidth: 2,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(show: true, color: AppColors.cashIn.withValues(alpha: 0.1)),
                ),
                LineChartBarData(
                  spots: List.generate(6, (i) => FlSpot(i.toDouble(), (i * 800 + 1500).toDouble())),
                  isCurved: true,
                  color: AppColors.cashOut,
                  barWidth: 2,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(show: true, color: AppColors.cashOut.withValues(alpha: 0.1)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CashbookSummaryTile extends ConsumerWidget {
  final Cashbook cashbook;
  const _CashbookSummaryTile({required this.cashbook});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withValues(alpha: 0.2),
          child: Text(cashbook.name.substring(0, 1).toUpperCase(),
            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
        ),
        title: Text(cashbook.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('${cashbook.currency} ${cashbook.openingBalance.toStringAsFixed(2)}'),
        trailing: getCashbookSyncIcon(cashbook.syncStatus),
        onTap: () => context.go('/cashbooks/${cashbook.id}'),
      ),
    );
  }
}

class _EmptyDashboard extends StatelessWidget {
  final VoidCallback onCreateCashbook;
  const _EmptyDashboard({required this.onCreateCashbook});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          const Icon(Icons.book_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text('No cashbooks yet', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          const Text('Create your first cashbook to get started', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onCreateCashbook,
            icon: const Icon(Icons.add),
            label: const Text('Create Cashbook'),
          ),
        ],
      ),
    );
  }
}
