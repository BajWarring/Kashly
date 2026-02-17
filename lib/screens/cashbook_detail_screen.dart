// UI ONLY — No business logic here. Logic goes in lib/logic/cashbook_logic.dart

import 'package:flutter/material.dart';
import '../models/cashbook.dart';
import '../models/transaction.dart';
import '../logic/cashbook_logic.dart';
import '../widgets/transaction_card.dart';
import '../widgets/balance_summary_card.dart';
import 'add_entry_screen.dart';
import 'entry_detail_screen.dart';
import 'cashbook_options_screen.dart';

class CashbookDetailScreen extends StatefulWidget {
  final CashBook cashbook;

  const CashbookDetailScreen({super.key, required this.cashbook});

  @override
  State<CashbookDetailScreen> createState() => _CashbookDetailScreenState();
}

class _CashbookDetailScreenState extends State<CashbookDetailScreen> {
  late List<Transaction> _transactions;
  bool _isSearching = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _transactions = CashbookLogic.getSampleTransactions(widget.cashbook.id);
  }

  List<Transaction> get _filtered {
    if (_searchQuery.isEmpty) return _transactions;
    return _transactions.where((t) {
      final q = _searchQuery.toLowerCase();
      return t.remarks!.toLowerCase().contains(q) ||
          t.category.toLowerCase().contains(q) ||
          t.paymentMethod.toLowerCase().contains(q);
    }).toList();
  }

  void _openAddEntry(EntryType type) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddEntryScreen(
          cashbook: widget.cashbook,
          initialEntryType: type,
        ),
      ),
    );
    // TODO: Refresh transactions from logic layer
  }

  void _openEntryDetail(Transaction tx) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EntryDetailScreen(transaction: tx)),
    );
  }

  void _showMoreMenu() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.tune),
              title: const Text('Manage Categories & Payments'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CashbookOptionsScreen(
                      cashbook: widget.cashbook,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_outlined),
              title: const Text('Export as PDF'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Exporting as PDF...')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_chart_outlined),
              title: const Text('Export as CSV'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Exporting as CSV...')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.share_outlined),
              title: const Text('Share'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sharing...')),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline,
                  color: Theme.of(context).colorScheme.error),
              title: Text('Delete CashBook',
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.error)),
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
        icon: Icon(Icons.delete_forever,
            color: Theme.of(context).colorScheme.error),
        title: const Text('Delete CashBook?'),
        content: Text(
            'All transactions in "${widget.cashbook.name}" will be permanently deleted.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text('${widget.cashbook.name} deleted')),
              );
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

    // Group transactions by date
    final Map<String, List<Transaction>> grouped = {};
    for (final tx in _filtered) {
      final key = _formatGroupDate(tx.dateTime);
      grouped.putIfAbsent(key, () => []).add(tx);
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
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
            : Text(widget.cashbook.name),
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
              icon: const Icon(Icons.search),
              tooltip: 'Search',
              onPressed: () => setState(() => _isSearching = true),
            ),
            IconButton(
              icon: const Icon(Icons.ios_share_outlined),
              tooltip: 'Export',
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  builder: (_) => SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Text('Export',
                              style:
                                  Theme.of(context).textTheme.titleLarge),
                        ),
                        ListTile(
                          leading:
                              const Icon(Icons.picture_as_pdf_outlined),
                          title: const Text('Export as PDF'),
                          onTap: () => Navigator.pop(context),
                        ),
                        ListTile(
                          leading:
                              const Icon(Icons.table_chart_outlined),
                          title: const Text('Export as CSV'),
                          onTap: () => Navigator.pop(context),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.more_vert),
              tooltip: 'More',
              onPressed: _showMoreMenu,
            ),
          ],
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Balance Summary Card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: BalanceSummaryCard(cashbook: widget.cashbook),
            ),
          ),

          // Section Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Text(
                    'Transactions',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                  ),
                  const SizedBox(width: 8),
                  Chip(
                    label: Text('${_filtered.length}'),
                    labelStyle: TextStyle(
                        fontSize: 12, color: colorScheme.onSecondaryContainer),
                    backgroundColor: colorScheme.secondaryContainer,
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
          ),

          // Transactions grouped by date
          if (_filtered.isEmpty)
            SliverFillRemaining(
              child: _EmptyTransactions(
                onAddEntry: () => _openAddEntry(EntryType.cashIn),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final keys = grouped.keys.toList();
                    final key = keys[index];
                    final txList = grouped[key]!;
                    return _DateGroup(
                      date: key,
                      transactions: txList,
                      onTap: _openEntryDetail,
                    );
                  },
                  childCount: grouped.length,
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: _CashInOutFAB(
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
    return '${dt.day} ${_monthName(dt.month)}, ${dt.year}';
  }

  String _monthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

// --- Sub-widgets (UI only) ---

class _DateGroup extends StatelessWidget {
  final String date;
  final List<Transaction> transactions;
  final void Function(Transaction) onTap;

  const _DateGroup({
    required this.date,
    required this.transactions,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 6),
          child: Text(
            date,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        ...transactions.map(
          (tx) => TransactionCard(
            transaction: tx,
            onTap: () => onTap(tx),
          ),
        ),
      ],
    );
  }
}

class _EmptyTransactions extends StatelessWidget {
  final VoidCallback onAddEntry;

  const _EmptyTransactions({required this.onAddEntry});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.receipt_long_outlined,
                size: 48, color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          Text('No transactions yet',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Tap + to record your first entry',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          FilledButton.tonalIcon(
            onPressed: onAddEntry,
            icon: const Icon(Icons.add),
            label: const Text('Add Entry'),
          ),
        ],
      ),
    );
  }
}

class _CashInOutFAB extends StatefulWidget {
  final VoidCallback onCashIn;
  final VoidCallback onCashOut;

  const _CashInOutFAB({required this.onCashIn, required this.onCashOut});

  @override
  State<_CashInOutFAB> createState() => _CashInOutFABState();
}

class _CashInOutFABState extends State<_CashInOutFAB>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late AnimationController _controller;
  late Animation<double> _expandAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _expandAnim = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    _expanded ? _controller.forward() : _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Cash Out
        ScaleTransition(
          scale: _expandAnim,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_expanded)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Material(
                      color: colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        child: Text('Cash Out',
                            style: TextStyle(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
                FloatingActionButton.small(
                  heroTag: 'cashout',
                  backgroundColor: colorScheme.errorContainer,
                  foregroundColor: colorScheme.onErrorContainer,
                  onPressed: () {
                    _toggle();
                    widget.onCashOut();
                  },
                  child: const Icon(Icons.remove),
                ),
              ],
            ),
          ),
        ),
        // Cash In
        ScaleTransition(
          scale: _expandAnim,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_expanded)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Material(
                      color: colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        child: Text('Cash In',
                            style: TextStyle(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
                FloatingActionButton.small(
                  heroTag: 'cashin',
                  backgroundColor: colorScheme.primaryContainer,
                  foregroundColor: colorScheme.onPrimaryContainer,
                  onPressed: () {
                    _toggle();
                    widget.onCashIn();
                  },
                  child: const Icon(Icons.add),
                ),
              ],
            ),
          ),
        ),
        // Main FAB
        FloatingActionButton(
          heroTag: 'main',
          onPressed: _toggle,
          child: AnimatedRotation(
            turns: _expanded ? 0.125 : 0,
            duration: const Duration(milliseconds: 250),
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
