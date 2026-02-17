// UI ONLY

import 'package:flutter/material.dart';
import '../models/cashbook.dart';
import '../logic/cashbook_logic.dart';
import '../widgets/cashbook_card.dart';
import '../widgets/backup_status_icon.dart';
import '../state/backup_state.dart';
import 'cashbook_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchQuery = '';
  List<CashBook> _cashbooks = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() => _cashbooks = CashbookLogic.getCashbooks());
  }

  List<CashBook> get _filtered {
    if (_searchQuery.isEmpty) return _cashbooks;
    return _cashbooks
        .where((b) => b.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) {
        final colorScheme = Theme.of(context).colorScheme;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
                child: Row(
                  children: [
                    Text('Sort & Filter',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const Spacer(),
                    IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context)),
                  ],
                ),
              ),
              _FilterTile(
                  icon: Icons.trending_up_rounded,
                  label: 'Positive Balance First',
                  onTap: () {
                    setState(() => _cashbooks.sort(
                        (a, b) => b.balance.compareTo(a.balance)));
                    Navigator.pop(context);
                  }),
              _FilterTile(
                  icon: Icons.trending_down_rounded,
                  label: 'Negative Balance First',
                  onTap: () {
                    setState(() => _cashbooks.sort(
                        (a, b) => a.balance.compareTo(b.balance)));
                    Navigator.pop(context);
                  }),
              _FilterTile(
                  icon: Icons.sort_by_alpha_rounded,
                  label: 'Name: A → Z',
                  onTap: () {
                    setState(() => _cashbooks
                        .sort((a, b) => a.name.compareTo(b.name)));
                    Navigator.pop(context);
                  }),
              _FilterTile(
                  icon: Icons.sort_by_alpha_rounded,
                  label: 'Name: Z → A',
                  onTap: () {
                    setState(() => _cashbooks
                        .sort((a, b) => b.name.compareTo(a.name)));
                    Navigator.pop(context);
                  }),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _showAddDialog() {
    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        icon: const Icon(Icons.menu_book_rounded, size: 28),
        title: const Text('New CashBook',
            style: TextStyle(fontWeight: FontWeight.w600)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'CashBook Name',
                hintText: 'e.g. Personal, Business, Travel...',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.edit_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(context);
              await CashbookLogic.addCashbook(name);
              _load();
              if (mounted) {
                BackupStateProvider.of(context).notifyDataChanged();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('"$name" created!'),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                );
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final filtered = _filtered;

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
                  hintText: 'Search cashbooks...',
                  hintStyle:
                      TextStyle(color: colorScheme.onSurfaceVariant),
                  border: InputBorder.none,
                ),
                onChanged: (v) => setState(() => _searchQuery = v),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.menu_book_rounded,
                        size: 20,
                        color: colorScheme.onPrimaryContainer),
                  ),
                  const SizedBox(width: 10),
                  const Text('CashBook',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 20)),
                ],
              ),
        actions: [
          if (_isSearching)
            IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() {
                      _isSearching = false;
                      _searchController.clear();
                      _searchQuery = '';
                    }))
          else ...[
            IconButton(
                icon: const Icon(Icons.search_rounded),
                onPressed: () =>
                    setState(() => _isSearching = true)),
            IconButton(
                icon: const Icon(Icons.filter_list_rounded),
                onPressed: _showFilterSheet),
            const BackupStatusIcon(),
          ],
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary banner (only when there are cashbooks)
          if (!_isSearching && _cashbooks.isNotEmpty)
            _SummaryBanner(cashbooks: _cashbooks),

          // Section header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Text('Your Books',
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
                const Spacer(),
                const BackupStatusText(),
              ],
            ),
          ),

          Expanded(
            child: filtered.isEmpty
                ? _EmptyState(onAdd: _showAddDialog)
                : ListView.builder(
                    padding:
                        const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) => CashBookCard(
                      cashbook: filtered[i],
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CashbookDetailScreen(
                                cashbook: filtered[i]),
                          ),
                        );
                        // Reload when returning — balances may have changed
                        _load();
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New CashBook',
            style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

// ── Summary banner ──────────────────────────────────────────────────────────

class _SummaryBanner extends StatelessWidget {
  final List<CashBook> cashbooks;
  const _SummaryBanner({required this.cashbooks});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final totalIn = cashbooks.fold(0.0, (s, c) => s + c.totalIn);
    final totalOut = cashbooks.fold(0.0, (s, c) => s + c.totalOut);
    final net = totalIn - totalOut;
    final isPositive = net >= 0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primaryContainer,
            colorScheme.secondaryContainer
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Net Balance across all books',
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(
                          color: colorScheme.onPrimaryContainer
                              .withValues(alpha: 0.8),
                        )),
                const SizedBox(height: 4),
                Text(
                  '${isPositive ? '+' : '−'} ₹${net.abs().toStringAsFixed(2)}',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: isPositive
                            ? const Color(0xFF0E6027)
                            : colorScheme.error,
                        letterSpacing: -0.5,
                      ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _NetStat(
                  label: 'In',
                  value: totalIn,
                  isIn: true,
                  colorScheme: colorScheme),
              const SizedBox(height: 6),
              _NetStat(
                  label: 'Out',
                  value: totalOut,
                  isIn: false,
                  colorScheme: colorScheme),
            ],
          ),
        ],
      ),
    );
  }
}

class _NetStat extends StatelessWidget {
  final String label;
  final double value;
  final bool isIn;
  final ColorScheme colorScheme;

  const _NetStat(
      {required this.label,
      required this.value,
      required this.isIn,
      required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isIn
              ? Icons.arrow_downward_rounded
              : Icons.arrow_upward_rounded,
          size: 12,
          color:
              isIn ? const Color(0xFF1B8A3A) : colorScheme.error,
        ),
        const SizedBox(width: 4),
        Text('$label ₹${value.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color:
                  isIn ? const Color(0xFF1B8A3A) : colorScheme.error,
            )),
      ],
    );
  }
}

class _FilterTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _FilterTile(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
        leading: Icon(icon, size: 22),
        title: Text(label),
        onTap: onTap,
        dense: true);
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

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
                color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.menu_book_rounded,
                  size: 52, color: colorScheme.primary),
            ),
            const SizedBox(height: 24),
            Text('No CashBooks Yet',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
                'Create your first cashbook to start\ntracking income and expenses',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant)),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Create CashBook',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
