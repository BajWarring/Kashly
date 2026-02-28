import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/models/book.dart';
import '../../core/models/entry.dart';
import '../../core/database_helper.dart';
import '../../core/theme.dart';
import 'add_entry_screen.dart';
import 'entry_details_screen.dart';

class CashbookScreen extends StatefulWidget {
  final Book book;
  const CashbookScreen({super.key, required this.book});

  @override
  State<CashbookScreen> createState() => _CashbookScreenState();
}

class _CashbookScreenState extends State<CashbookScreen> {
  List<Entry> entries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    setState(() => _isLoading = true);
    
    final data = await DatabaseHelper.instance.getEntriesForBook(widget.book.id);
    
    setState(() {
      entries = data;
      _isLoading = false;
    });
  }

  void _openAddEntryScreen(String type) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddEntryScreen(
          book: widget.book,
          initialType: type,
        ),
      ),
    );
    // Refresh the list and the balance when returning
    _loadEntries();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.book.name),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Text(
                'Balance: ₹${widget.book.balance.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          )
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: accent))
        : entries.isEmpty 
            ? const Center(child: Text('No entries yet. Add some cash!', style: TextStyle(color: textMuted)))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  final isOut = entry.type == 'out';
                  final dateStr = DateFormat('dd MMM, hh:mm a').format(DateTime.fromMillisecondsSinceEpoch(entry.timestamp));
                  
                  return Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      side: const BorderSide(color: borderCol),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EntryDetailsScreen(
                              entry: entry,
                              book: widget.book,
                            ),
                          ),
                        ).then((_) => _loadEntries()); 
                      },
                      title: Text(
                        entry.category.isNotEmpty ? entry.category : 'Uncategorized',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: textDark),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          if (entry.note.isNotEmpty) Text(entry.note, style: const TextStyle(color: textMuted, fontSize: 13)),
                          Text(dateStr, style: const TextStyle(color: textLight, fontSize: 11)),
                        ],
                      ),
                      trailing: Text(
                        '${isOut ? '-' : '+'}₹${entry.amount.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: isOut ? danger : success,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  );
                },
              ),
      
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _openAddEntryScreen('out'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: dangerLight,
                    foregroundColor: danger,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.remove_circle_outline),
                  label: const Text('CASH OUT', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _openAddEntryScreen('in'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: successLight,
                    foregroundColor: success,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('CASH IN', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
