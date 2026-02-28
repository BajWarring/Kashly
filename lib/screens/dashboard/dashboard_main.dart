import 'package:flutter/material.dart';

import '../../core/models/book.dart';
import '../../core/database_helper.dart';
import '../../core/theme.dart'; 
import '../cashbooks/cashbook_screen.dart'; // Fixed import
import '../cashbooks/entry_details_screen.dart'; // Fixed import
import 'widgets/add_book_sheet.dart'; 

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  bool _isSearchActive = false;
  String _searchQuery = '';
  String _filterType = 'modified'; 
  bool _sortAscending = false;
  
  List<Book> books = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _refreshBooks(); 
  }

  Future<void> _refreshBooks() async {
    setState(() => _isLoading = true);
    final data = await DatabaseHelper.instance.getAllBooks();
    setState(() {
      books = data;
      _isLoading = false;
    });
  }

  Future<void> _addBook(Book book) async {
    await DatabaseHelper.instance.insertBook(book);
    _refreshBooks();
  }

  Future<void> _deleteBook(String id) async {
    await DatabaseHelper.instance.deleteBook(id);
    _refreshBooks();
  }

  List<Book> get _filteredAndSortedBooks {
    List<Book> res = books.where((b) => b.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    res.sort((a, b) {
      if (_filterType == 'name') {
        int cmp = a.name.compareTo(b.name);
        return _sortAscending ? cmp : -cmp;
      } else {
        int cmp = a.timestamp.compareTo(b.timestamp);
        return _sortAscending ? cmp : -cmp;
      }
    });
    return res;
  }

  String _formatCurrency(double amt, String sym) {
    String formatted = amt.abs().toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
    return amt < 0 ? '-$sym$formatted' : '$sym$formatted';
  }

  String _timeAgo(int timestamp) {
    final diff = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(timestamp));
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  Widget _buildHeader() {
    if (_currentIndex == 1) {
      return const Padding(
        padding: EdgeInsets.only(top: 60, left: 24, right: 24, bottom: 20),
        child: Text('Settings', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: textDark)),
      );
    }

    if (_isSearchActive) {
      return Padding(
        padding: const EdgeInsets.only(top: 50, left: 16, right: 16, bottom: 10),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.close, color: textMuted),
              onPressed: () => setState(() { _isSearchActive = false; _searchQuery = ''; }),
            ),
            Expanded(
              child: TextField(
                autofocus: true,
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: const InputDecoration(
                  hintText: 'Search cashbooks...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: textLight, fontWeight: FontWeight.w500),
                ),
                style: const TextStyle(fontSize: 18, color: textDark, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 50, left: 24, right: 16, bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(10), boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))]),
                child: const Icon(Icons.account_balance_wallet, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Text('Kashly', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: textDark, letterSpacing: -0.5)),
            ],
          ),
          Row(
            children: [
              IconButton(icon: const Icon(Icons.search, color: textMuted), onPressed: () => setState(() => _isSearchActive = true)),
              PopupMenuButton<String>(
                icon: const Icon(Icons.filter_list, color: textMuted),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                onSelected: (val) {
                  setState(() {
                    if (val == 'asc_desc') _sortAscending = !_sortAscending;
                    else _filterType = val;
                  });
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(enabled: false, child: Text('SORT BY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: textLight))),
                  PopupMenuItem(value: 'name', child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Name', style: TextStyle(fontWeight: FontWeight.w600)), if (_filterType == 'name') const Icon(Icons.check, color: accent, size: 18)])),
                  PopupMenuItem(value: 'modified', child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Last Modified', style: TextStyle(fontWeight: FontWeight.w600)), if (_filterType == 'modified') const Icon(Icons.check, color: accent, size: 18)])),
                  const PopupMenuDivider(),
                  PopupMenuItem(value: 'asc_desc', child: Row(children: [Icon(_sortAscending ? Icons.arrow_upward : Icons.arrow_downward, size: 18, color: textMuted), const SizedBox(width: 8), Text(_sortAscending ? 'Ascending' : 'Descending', style: const TextStyle(fontWeight: FontWeight.w600))])),
                ],
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    if (_isLoading) return const Expanded(child: Center(child: CircularProgressIndicator(color: accent)));

    final list = _filteredAndSortedBooks;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          child: Row(
            children: [
              const Text('YOUR BOOKS', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: textMuted, letterSpacing: 1.2)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: borderCol, borderRadius: BorderRadius.circular(6)),
                child: Text('${list.length}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textDark)),
              )
            ],
          ),
        ),
        if (list.isEmpty)
          const Expanded(child: Center(child: Text("No cashbooks found.", style: TextStyle(color: textMuted, fontWeight: FontWeight.w500))))
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 100),
              itemCount: list.length,
              itemBuilder: (context, index) {
                final book = list[index];
                final bool isNeg = book.balance < 0;
                final bool isZero = book.balance == 0;
                final Color balColor = isNeg ? danger : (isZero ? textMuted : success);
                final Color iconBg = isNeg ? dangerLight : (isZero ? appBg : accentLight);
                final Color iconCol = isNeg ? danger : (isZero ? textLight : accent);
                final IconData trendIcon = isNeg ? Icons.trending_down : (isZero ? Icons.remove : Icons.trending_up);

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(20), border: Border.all(color: borderCol)),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CashbookScreen(book: book))).then((_) => _refreshBooks()),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 48, height: 48,
                              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(14)),
                              child: Icon(availableIcons[book.icon] ?? Icons.account_balance_wallet, color: iconCol),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(book.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textDark), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 4),
                                  Text('Updated: ${_timeAgo(book.timestamp)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: textMuted)),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(_formatCurrency(book.balance, worldCurrencies.firstWhere((c)=>c.code == book.currency).symbol), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: balColor)),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(trendIcon, size: 12, color: balColor.withValues(alpha: 0.8)),
                                    const SizedBox(width: 4),
                                    Text(book.currency, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: textLight)),
                                  ],
                                )
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          )
      ],
    );
  }

  Widget _buildSettingsTab() {
    return ListView(
      padding: const EdgeInsets.only(bottom: 100, top: 20),
      children: const [
        Center(child: Text('Settings Coming Soon', style: TextStyle(color: textMuted, fontWeight: FontWeight.w500))),
      ],
    );
  }

  void _showAddSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddBookSheet(onAdd: _addBook),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _currentIndex == 0 ? _buildHomeTab() : _buildSettingsTab()),
          ],
        ),
      ),
      floatingActionButton: _currentIndex == 0 ? FloatingActionButton(
        onPressed: _showAddSheet,
        backgroundColor: accent,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, size: 28, color: Colors.white),
      ) : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(border: Border(top: BorderSide(color: borderCol))),
        child: NavigationBar(
          backgroundColor: Colors.white.withValues(alpha: 0.95),
          elevation: 0,
          indicatorColor: accentLight,
          selectedIndex: _currentIndex,
          onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home, color: accent), label: 'Home'),
            NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings, color: accent), label: 'Settings'),
          ],
        ),
      ),
    );
  }
}
