import 'package:flutter/material.dart';
import 'dart:math';

import '../../core/models/book.dart';
import '../../core/models/entry.dart';
import '../../core/theme.dart'; // Adjust path if needed

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
    
    // Fetch real data from SQLite
    final data = await DatabaseHelper.instance.getEntriesForBook(widget.book.id);
    
    setState(() {
      entries = data; // Use the real data
      _isLoading = false;
    });
  }


  void _showAddEntryDialog(String type) {
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(type == 'in' ? 'Cash In (+)' : 'Cash Out (-)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Amount', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteCtrl,
              decoration: const InputDecoration(labelText: 'Note / Remark', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: type == 'in' ? success : danger,
            ),
            onPressed: () async {
              if (amountCtrl.text.isEmpty) return;
              
              final newEntry = Entry(
                id: 'ENT-${Random().nextInt(999999)}',
                bookId: widget.book.id,
                type: type,
                amount: double.tryParse(amountCtrl.text) ?? 0.0,
                note: noteCtrl.text.trim(),
                timestamp: DateTime.now().millisecondsSinceEpoch,
              );

             // Insert into SQLite database
              await DatabaseHelper.instance.insertEntry(newEntry);
              
              // Update book balance
              final updatedBook = widget.book;
              updatedBook.balance += (type == 'in' ? newEntry.amount : -newEntry.amount);
              await DatabaseHelper.instance.updateBook(updatedBook);

              Navigator.pop(ctx);
              _loadEntries(); // Refresh the list
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.book.name),
        actions: [
          // A simple balance display in the app bar
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Text(
                'Balance: ${widget.book.balance}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          )
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : entries.isEmpty 
            ? const Center(child: Text('No entries yet. Add some cash!'))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  final isOut = entry.type == 'out';
                  
                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      side: const BorderSide(color: borderCol),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      title: Text(entry.note.isNotEmpty ? entry.note : 'No Note'),
                      subtitle: Text(DateTime.fromMillisecondsSinceEpoch(entry.timestamp).toString()),
                      trailing: Text(
                        '${isOut ? '-' : '+'}${entry.amount}',
                        style: TextStyle(
                          color: isOut ? danger : success,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  );
                },
              ),
      
      // Bottom Buttons for Cash In / Cash Out
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showAddEntryDialog('out'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: dangerLight,
                    foregroundColor: danger,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.remove_circle_outline),
                  label: const Text('CASH OUT', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showAddEntryDialog('in'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: successLight,
                    foregroundColor: success,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
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
