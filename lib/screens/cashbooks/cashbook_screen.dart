import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/models/book.dart';
import '../../core/models/entry.dart';
import '../../core/database_helper.dart';
import '../../core/theme.dart';
import 'add_entry_screen.dart';
import 'entry_details_screen.dart';
import 'generate_report_screen.dart';

class CashbookScreen extends StatefulWidget {
  final Book book;
  const CashbookScreen({super.key, required this.book});

  @override
  State<CashbookScreen> createState() => _CashbookScreenState();
}

class _CashbookScreenState extends State<CashbookScreen> {
  bool _isSearchActive = false;
  String _searchQuery = '';
  
  // Filter States
  String _filterType = 'All Entries';
  List<String> _filterCategories = [];
  List<String> _filterPayments = [];
  
  List<Entry> entries = [];
  Map<String, double> runningBalances = {};
  double totalIn = 0;
  double totalOut = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    setState(() => _isLoading = true);
    
    final data = await DatabaseHelper.instance.getEntriesForBook(widget.book.id);
    
    double running = 0;
    double tIn = 0;
    double tOut = 0;
    Map<String, double> bals = {};
    
    for (var e in data.reversed) {
      if (e.type == 'in') {
        running += e.amount;
        tIn += e.amount;
      } else {
        running -= e.amount;
        tOut += e.amount;
      }
      bals[e.id] = running;
    }
    
    if (!mounted) return;
    setState(() {
      entries = data;
      runningBalances = bals;
      totalIn = tIn;
      totalOut = tOut;
      _isLoading = false;
    });
  }

  String _formatCur(double amt) {
    String formatted = amt.abs().toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
    return amt < 0 ? '-₹$formatted' : '₹$formatted';
  }

  void _openFilter(String type) async {
    if (type == 'type') {
      final res = await FilterDialogs.showSelectionDialog(context, 'Entry Type', ['All Entries', 'Cash In', 'Cash Out'], false);
      if (res != null && res.isNotEmpty) setState(() => _filterType = res.first);
    } else if (type == 'category') {
      final opts = await DatabaseHelper.instance.getAllOptions('Category');
      if (!mounted) return;
      final res = await FilterDialogs.showSelectionDialog(context, 'Categories', opts.map((e)=>e.value).toList(), true);
      if (res != null) setState(() => _filterCategories = res);
    } else if (type == 'payment') {
      final opts = await DatabaseHelper.instance.getAllOptions('Payment Method');
      if (!mounted) return;
      final res = await FilterDialogs.showSelectionDialog(context, 'Payment Method', opts.map((e)=>e.value).toList(), true);
      if (res != null) setState(() => _filterPayments = res);
    }
  }

  PreferredSizeWidget _buildAppBar() {
    if (_isSearchActive) {
      return AppBar(
        leading: IconButton(icon: const Icon(Icons.close, color: textMuted), onPressed: () => setState(() { _isSearchActive = false; _searchQuery = ''; })),
        title: TextField(autofocus: true, decoration: const InputDecoration(hintText: 'Search entries...', border: InputBorder.none, hintStyle: TextStyle(color: textLight)), style: const TextStyle(fontSize: 18, color: textDark, fontWeight: FontWeight.w600), onChanged: (val) => setState(() => _searchQuery = val)),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.filter_list, color: (_filterType != 'All Entries' || _filterCategories.isNotEmpty || _filterPayments.isNotEmpty) ? accent : textMuted),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            onSelected: _openFilter,
            itemBuilder: (context) => [
              const PopupMenuItem(enabled: false, child: Text('FILTER BY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: textLight))),
              const PopupMenuItem(value: 'type', child: Text('Entry Type', style: TextStyle(fontWeight: FontWeight.w600))),
              const PopupMenuItem(value: 'category', child: Text('Categories', style: TextStyle(fontWeight: FontWeight.w600))),
              const PopupMenuItem(value: 'payment', child: Text('Payment Method', style: TextStyle(fontWeight: FontWeight.w600))),
            ],
          )
        ],
      );
    }

    return AppBar(
      title: Text(widget.book.name),
      actions: [
        IconButton(icon: const Icon(Icons.search), onPressed: () => setState(() => _isSearchActive = true)),
      ],
    );
  }

  void _openAddEntryScreen(String type) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => AddEntryScreen(book: widget.book, initialType: type)));
    _loadEntries();
  }

  @override
  Widget build(BuildContext context) {
    // ACTUAL FILTERING LOGIC
    final displayEntries = entries.where((e) {
      bool searchMatch = e.note.toLowerCase().contains(_searchQuery.toLowerCase()) || e.category.toLowerCase().contains(_searchQuery.toLowerCase());
      bool typeMatch = _filterType == 'All Entries' || (_filterType == 'Cash In' && e.type == 'in') || (_filterType == 'Cash Out' && e.type == 'out');
      bool catMatch = _filterCategories.isEmpty || _filterCategories.contains(e.category);
      bool payMatch = _filterPayments.isEmpty || _filterPayments.contains(e.paymentMethod);
      return searchMatch && typeMatch && catMatch && payMatch;
    }).toList();

    return Scaffold(
      appBar: _buildAppBar(),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: accent)) 
        : Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16), padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: appBg, borderRadius: BorderRadius.circular(24), border: Border.all(color: borderCol)),
            child: Column(
              children: [
                const Text('OVERALL BALANCE', style: TextStyle(color: textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                const SizedBox(height: 4),
                Text(_formatCur(widget.book.balance), style: const TextStyle(color: textDark, fontSize: 32, fontWeight: FontWeight.w900)),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Total Cash In', style: TextStyle(color: textMuted, fontSize: 12, fontWeight: FontWeight.w600)), const SizedBox(height: 2), Text(_formatCur(totalIn), style: const TextStyle(color: success, fontWeight: FontWeight.bold, fontSize: 16))])),
                    Container(width: 1, height: 30, color: borderCol),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [const Text('Total Cash Out', style: TextStyle(color: textMuted, fontSize: 12, fontWeight: FontWeight.w600)), const SizedBox(height: 2), Text(_formatCur(totalOut), style: const TextStyle(color: danger, fontWeight: FontWeight.bold, fontSize: 16))])),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GenerateReportScreen(book: widget.book))),
                    icon: const Icon(Icons.picture_as_pdf, size: 18, color: Colors.white),
                    label: const Text('Generate Reports', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(backgroundColor: accent, elevation: 0, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  ),
                )
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Showing ${displayEntries.length} Entries', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textMuted))]),
          ),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 100),
              itemCount: displayEntries.length,
              itemBuilder: (context, index) {
                final entry = displayEntries[index];
                
                // Formatted Dates: Feb 23, 2026 style
                final dateStr = DateFormat('MMM d, yyyy').format(DateTime.fromMillisecondsSinceEpoch(entry.timestamp));
                final timeStr = DateFormat('h:mm a').format(DateTime.fromMillisecondsSinceEpoch(entry.timestamp));
                
                bool showDateHeader = true;
                if (index > 0) {
                   final prevDate = DateFormat('MMM d, yyyy').format(DateTime.fromMillisecondsSinceEpoch(displayEntries[index - 1].timestamp));
                   if (prevDate == dateStr) showDateHeader = false;
                }

                final bool isIn = entry.type == 'in';
                final Color eColor = isIn ? success : danger;
                final Color eBg = isIn ? successLight : dangerLight;
                final double bal = runningBalances[entry.id] ?? 0;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showDateHeader)
                      Padding(padding: const EdgeInsets.only(left: 20, top: 16, bottom: 8), child: Text(dateStr.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textLight, letterSpacing: 1))),
                    
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderCol)),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EntryDetailsScreen(entry: entry, book: widget.book))).then((_) => _loadEntries()),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(width: 40, height: 40, decoration: BoxDecoration(color: eBg, borderRadius: BorderRadius.circular(12)), child: Icon(isIn ? Icons.arrow_downward : Icons.arrow_upward, color: eColor, size: 20)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // COMPACT: Tags front of time
                                    Row(
                                      children: [
                                        Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: appBg, borderRadius: BorderRadius.circular(6)), child: Text(entry.category, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: textMuted))),
                                        const SizedBox(width: 6),
                                        Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: appBg, borderRadius: BorderRadius.circular(6)), child: Text(entry.paymentMethod, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: textMuted))),
                                        const SizedBox(width: 8),
                                        Text(timeStr, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textMuted)),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(entry.note.isNotEmpty ? entry.note : entry.category, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textDark)),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text((isIn ? '+' : '-') + _formatCur(entry.amount), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: eColor)),
                                  const SizedBox(height: 4),
                                  Text('Bal: ${_formatCur(bal)}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textLight)),
                                ],
                              )
                            ],
                          ),
                        ),
                      ),
                    )
                  ],
                );
              },
            ),
          )
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: FloatingActionButton.extended(heroTag: 'in', onPressed: () => _openAddEntryScreen('in'), backgroundColor: success, elevation: 4, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), icon: const Icon(Icons.add, color: Colors.white), label: const Text('CASH IN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
            const SizedBox(width: 16),
            Expanded(child: FloatingActionButton.extended(heroTag: 'out', onPressed: () => _openAddEntryScreen('out'), backgroundColor: danger, elevation: 4, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), icon: const Icon(Icons.remove, color: Colors.white), label: const Text('CASH OUT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
          ],
        ),
      ),
    );
  }
}
