import 'package:flutter/material.dart';
import 'dart:math';

// Import your core files and sub-screens
import '../../core/models/book.dart';
import '../../core/database_helper.dart';
import '../../core/theme.dart'; // Assuming your colors/constants are here
import '../cashbooks/cashbook_list.dart'; // The inside cashbook screen
import '../cashbooks/details_screen.dart'; // The book details screen
import 'widgets/add_book_sheet.dart'; // The add book bottom sheet

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  bool _isSearchActive = false;
  String _searchQuery = '';
  String _filterType = 'modified'; // 'modified', 'name'
  bool _sortAscending = false;
  
  // State variables for real data
  List<Book> books = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _refreshBooks(); // Fetch real data on startup
  }

  // --- DATABASE OPERATIONS ---
  
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

  Future<void> _updateBook(String id, Book updatedBook) async {
    await DatabaseHelper.instance.updateBook(updatedBook);
    _refreshBooks();
  }

  Future<void> _deleteBook(String id) async {
    await DatabaseHelper.instance.deleteBook(id);
    _refreshBooks();
  }

  // --- HELPERS ---
  
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

  // --- UI COMPONENTS ---
  
  Widget _buildHeader() {
    // (Keep your exact _buildHeader code here - no changes needed)
    // ... [Your existing search/filter header UI]
  }

  Widget _buildHomeTab() {
    if (_isLoading) {
      return const Expanded(
        child: Center(
          child: CircularProgressIndicator(color: accent),
        ),
      );
    }

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
                  decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(20), border: Border.all(color: borderCol), boxShadow: const [BoxShadow(color: Color(0x05000000), blurRadius: 10, offset: Offset(0, 4))]),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CashbookScreen(book: book))),
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
                                    Icon(trendIcon, size: 12, color: balColor.withOpacity(0.8)),
                                    const SizedBox(width: 4),
                                    Text(book.currency, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: textLight)),
                                  ],
                                )
                              ],
                            ),
                            const SizedBox(width: 8),
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert, color: textLight),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              onSelected: (val) {
                                if (val == 'details') {
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => DetailsScreen(book: book, onUpdate: _updateBook, onDelete: _deleteBook)));
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(value: 'details', child: Row(children: [Icon(Icons.info_outline, size: 18, color: textMuted), SizedBox(width: 12), Text('Details', style: TextStyle(fontWeight: FontWeight.w600))])),
                              ],
                            )
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
     // (Keep your exact _buildSettingsTab code here)
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
    // (Keep your exact build code here for Scaffold, NavigationBar, etc.)
  }
}
