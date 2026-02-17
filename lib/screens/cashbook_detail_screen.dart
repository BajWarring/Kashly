// UI ONLY — Logic lives in lib/logic/cashbook_logic.dart

import 'package:flutter/material.dart';
import '../models/cashbook.dart';
import '../models/transaction.dart';
import '../logic/cashbook_logic.dart';
import '../widgets/transaction_card.dart';
import '../widgets/balance_summary_card.dart';
import '../widgets/backup_status_icon.dart';
import '../state/backup_state.dart';
import 'add_entry_screen.dart';
import 'entry_detail_screen.dart';
import 'cashbook_options_screen.dart';

class CashbookDetailScreen extends StatefulWidget {
  final CashBook cashbook;
  const CashbookDetailScreen({super.key, required this.cashbook});

  @override
  State<CashbookDetailScreen> createState() => _CashbookDetailScreenState();
}

class _CashbookDetailScreenState extends State<CashbookDetailScreen>
    with SingleTickerProviderStateMixin {
  late List<Transaction> _transactions;
  // Keep a local mutable copy of the cashbook so balances update on screen
  late CashBook _cashbook;
  bool _isSearching = false;
  String _searchQuery = '';
  bool _isSaving = false;
  final TextEditingController _searchController = TextEditingController();

  late AnimationController _saveAnimCtrl;
  late Animation<double> _saveAnim;

  @override
  void initState() {
    super.initState();
    _cashbook = widget.cashbook;
    _saveAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _saveAnim =
        CurvedAnimation(parent: _saveAnimCtrl, curve: Curves.easeOut);
    _loadTransactions();
  }

  void _loadTransactions() {
    final txList = CashbookLogic.getTransactions(_cashbook.id);
    // Sort newest first
    txList.sort((a, b) => b.dateTime.compareTo(a.dateTime));
    // Also refresh cashbook totals from store
    final refreshed = CashbookLogic.getCashbooks()
        .where((c) => c.id == _cashbook.id)
        .firstOrNull;
    setState(() {
      _transactions = txList;
      if (refreshed != null) _cashbook = refreshed;
    });
  }

  List<Transaction> get _filtered {
    if (_searchQuery.isEmpty) return _transactions;
    final q = _searchQuery.toLowerCase();
    return _transactions.where((t) {
      return (t.remarks ?? '').toLowerCase().contains(q) ||
          t.category.toLowerCase().contains(q) ||
          t.paymentMethod.toLowerCase().contains(q);
    }).toList();
  }

  Map<String, double> _buildRunningBalances(List<Transaction> txList) {
    final sorted = List<Transaction>.from(txList)
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    double running = 0;
    final Map<String, double> map = {};
    for (final tx in sorted) {
      running += tx.isCashIn ? tx.amount : -tx.amount;
      map[tx.id] = running;
    }
    return map;
  }

  Future<void> _openAddEntry(EntryType type) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            AddEntryScreen(cashbook: _cashbook, initialEntryType: type),
      ),
    );
    // Reload after returning (transaction may have been added)
    _loadTransactions();
    if (mounted) {
      setState(() => _isSaving = true);
      _saveAnimCtrl.forward();
      BackupStateProvider.of(context).notifyDataChanged();
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        _saveAnimCtrl.reverse();
        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted) setState(() => _isSaving = false);
      }
    }
  }

  void _openEntryDetail(Transaction tx) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => EntryDetailScreen(
              transaction: tx, cashbookId: _cashbook.id)),
    );
    _loadTransactions(); // refresh in case entry was deleted
  }

  void _showMoreMenu() {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
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
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.tune_rounded),
              title: const Text('Manage Categories & Payments'),
              onTap: () async {
                Navigator.pop(context);
                await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          CashbookOptionsScreen(cashbook: _cashbook),
                    ));
                _loadTransactions();
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_outlined),
              title: const Text('Export as PDF'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.table_chart_outlined),
              title: const Text('Export as CSV'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.share_outlined),
              title: const Text('Share'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: Icon(Icons.delete_outline,
                  color: Theme.of(context).colorScheme.error),
              title: Text('Delete CashBook',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.error)),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        icon: Icon(Icons.delete_forever_rounded,
            color: Theme.of(context).colorScheme.error, size: 32),
        title: const Text('Delete CashBook?'),
        content: Text(
            'All transactions in "${_cashbook.name}" will be permanently deleted.'),
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
              await CashbookLogic.deleteCashbook(_cashbook.id);
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final filtered = _filtered;
    final runningBalances = _buildRunningBalances(filtered);

    // Group by date label (already sorted newest-first)
    final Map<String, List<Transaction>> grouped = LinkedHashMap();
    for (final tx in filtered) {
      final key = _formatGroupDate(tx.dateTime);
      grouped.putIfAbsent(key, () => []).add(tx);
    }
    final groupKeys = grouped.keys.toList();

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        scrolledUnderElevation: 2,
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: TextStyle(color: colorScheme.onSurface),
                decoration: InputDecoration(
                  hintText: 'Search transactions...',
                  hintStyle:
                      TextStyle(color: colorScheme.onSurfaceVariant),
                  border: InputBorder.none,
                ),
                onChanged: (v) => setState(() => _searchQuery = v),
              )
            : Text(_cashbook.name,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 18)),
        actions: [
          if (_isSearching)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => setState(() {
                _isSearching = false;
                _searchController.clear();
                _searchQuery = '';
              }),
            )
          else ...[
            IconButton(
              icon: const Icon(Icons.search_rounded),
              tooltip: 'Search',
              onPressed: () => setState(() => _isSearching = true),
            ),
            IconButton(
              icon: const Icon(Icons.ios_share_outlined),
              tooltip: 'Export',
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  shape: const RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(28)),
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
                            color: colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        Padding(
                          padding:
                              const EdgeInsets.fromLTRB(16, 16, 16, 4),
                          child: Text('Export',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                      fontWeight: FontWeight.w600)),
                        ),
                        ListTile(
                            leading: const Icon(
                                Icons.picture_as_pdf_outlined),
                            title: const Text('Export as PDF'),
                            onTap: () => Navigator.pop(context)),
                        ListTile(
                            leading:
                                const Icon(Icons.table_chart_outlined),
                            title: const Text('Export as CSV'),
                            onTap: () => Navigator.pop(context)),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.more_vert_rounded),
              tooltip: 'More',
              onPressed: _showMoreMenu,
            ),
            const BackupStatusIcon(),
          ],
        ],
      ),

      // ── Body: Stack so saving pill overlays correctly ──────────────────
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Balance summary card
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: BalanceSummaryCard(cashbook: _cashbook),
                ),
              ),

              // Transactions header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                  child: Row(
                    children: [
                      Text('Transactions',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: colorScheme.onSurface,
                              )),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('${filtered.length}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSecondaryContainer,
                            )),
                      ),
                    ],
                  ),
                ),
              ),

              // Empty state or list
              if (filtered.isEmpty)
                SliverFillRemaining(
                  child: _EmptyTransactions(
                    onAddEntry: () => _openAddEntry(EntryType.cashIn),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 160),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final key = groupKeys[index];
                        final txList = grouped[key]!;
                        return _DateGroup(
                          date: key,
                          transactions: txList,
                          runningBalances: runningBalances,
                          onTap: _openEntryDetail,
                        );
                      },
                      childCount: groupKeys.length,
                    ),
                  ),
                ),
            ],
          ),

          // Saving pill — correctly positioned over content
          if (_isSaving)
            Positioned(
              bottom: 160,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _saveAnim,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: colorScheme.inverseSurface,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 12,
                        )
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colorScheme.onInverseSurface,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Saving…',
                          style: TextStyle(
                            color: colorScheme.onInverseSurface,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),

      floatingActionButton: _DualFAB(
        onCashIn: () => _openAddEntry(EntryType.cashIn),
        onCashOut: () => _openAddEntry(EntryType.cashOut),
      ),
    );
  }

  String _formatGroupDate(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final date = DateTime(dt.year, dt.month, dt.day);
    if (date == today) return 'Today';
    if (date == yesterday) return 'Yesterday';
    return '${dt.day} ${_monthName(dt.month)} ${dt.year}';
  }

  String _monthName(int m) => [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ][m - 1];

  @override
  void dispose() {
    _searchController.dispose();
    _saveAnimCtrl.dispose();
    super.dispose();
  }
}

// ── Dual FAB ────────────────────────────────────────────────────────────────

class _DualFAB extends StatelessWidget {
  final VoidCallback onCashIn;
  final VoidCallback onCashOut;
  const _DualFAB({required this.onCashIn, required this.onCashOut});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        FloatingActionButton.extended(
          heroTag: 'cashout_fab',
          backgroundColor: colorScheme.errorContainer,
          foregroundColor: colorScheme.onErrorContainer,
          elevation: 2,
          onPressed: onCashOut,
          icon: const Icon(Icons.arrow_upward_rounded),
          label: const Text('Cash Out',
              style: TextStyle(fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: 12),
        FloatingActionButton.extended(
          heroTag: 'cashin_fab',
          backgroundColor: const Color(0xFF1B8A3A),
          foregroundColor: Colors.white,
          elevation: 2,
          onPressed: onCashIn,
          icon: const Icon(Icons.arrow_downward_rounded),
          label: const Text('Cash In',
              style: TextStyle(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}

// ── Date group ───────────────────────────────────────────────────────────────

class _DateGroup extends StatelessWidget {
  final String date;
  final List<Transaction> transactions;
  final Map<String, double> runningBalances;
  final void Function(Transaction) onTap;

  const _DateGroup({
    required this.date,
    required this.transactions,
    required this.runningBalances,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: Row(
            children: [
              Text(date,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      )),
              const SizedBox(width: 8),
              Expanded(
                  child: Divider(color: colorScheme.outlineVariant)),
            ],
          ),
        ),
        ...transactions.map((tx) => TransactionCard(
              transaction: tx,
              runningBalance: runningBalances[tx.id],
              onTap: () => onTap(tx),
            )),
      ],
    );
  }
}

// ── Empty state ──────────────────────────────────────────────────────────────

class _EmptyTransactions extends StatelessWidget {
  final VoidCallback onAddEntry;
  const _EmptyTransactions({required this.onAddEntry});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.receipt_long_outlined,
                  size: 52, color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            Text('No transactions yet',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('Record your first cash in or out\nusing the buttons below',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    )),
          ],
        ),
      ),
    );
  }
}
