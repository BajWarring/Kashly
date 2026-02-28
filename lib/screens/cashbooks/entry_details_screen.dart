import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/models/book.dart';
import '../../core/models/entry.dart';
import '../../core/models/edit_log.dart';
import '../../core/database_helper.dart';
import '../../core/theme.dart';
import 'add_entry_screen.dart';

class EntryDetailsScreen extends StatefulWidget {
  final Entry entry;
  final Book book;

  const EntryDetailsScreen({super.key, required this.entry, required this.book});

  @override
  State<EntryDetailsScreen> createState() => _EntryDetailsScreenState();
}

class _EntryDetailsScreenState extends State<EntryDetailsScreen> {
  late Entry _currentEntry;
  List<EditLog> editHistory = [];
  bool _isLoadingLogs = true;

  @override
  void initState() {
    super.initState();
    _currentEntry = widget.entry;
    _loadEditHistory();
  }

  Future<void> _loadEditHistory() async {
    setState(() => _isLoadingLogs = true);
    final logs = await DatabaseHelper.instance.getLogsForEntry(_currentEntry.id);
    
    if (!mounted) return;
    
    setState(() {
      editHistory = logs;
      _isLoadingLogs = false;
    });
  }

  String _formatDateTime(int ms) {
    return DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.fromMillisecondsSinceEpoch(ms));
  }

  void _openEditEditor() async {
    final bool? didUpdate = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEntryScreen(
          book: widget.book,
          existingEntry: _currentEntry,
        ),
      ),
    );

    if (didUpdate == true) {
      final updatedEntry = await DatabaseHelper.instance.getEntryById(_currentEntry.id);
      
      if (!mounted) return; 
      
      if (updatedEntry != null) {
        setState(() => _currentEntry = updatedEntry);
        _loadEditHistory(); 
      }
    }
  }

  void _deleteEntry() async {
    // 1. Capture the Navigator synchronously BEFORE any async gaps
    final navigator = Navigator.of(context);

    // 2. Wait for the dialog to return a true/false result
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Entry?'),
        content: const Text('Are you sure you want to permanently delete this transaction?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false), 
            child: const Text('Cancel')
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: danger),
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          )
        ],
      )
    );

    // 3. If the user clicked Delete, run the async code safely
    if (confirm == true) {
      // Delete the entry from the database
      await DatabaseHelper.instance.deleteEntry(_currentEntry.id);
      
      // Reverse the amount from the Book's balance
      double amountToReverse = _currentEntry.type == 'in' ? -_currentEntry.amount : _currentEntry.amount;
      widget.book.balance += amountToReverse;
      await DatabaseHelper.instance.updateBook(widget.book);
      
      // 4. Use the captured navigator!
      navigator.pop(); 
    }
  }

  // ---> THIS IS THE METHOD THAT GOT ACCIDENTALLY DELETED <---
  Widget _buildDetailRow(String label, String value, {Color? valueColor, bool isLarge = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textMuted)),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value, 
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: isLarge ? 18 : 14, 
                fontWeight: isLarge ? FontWeight.w900 : FontWeight.bold, 
                color: valueColor ?? textDark
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isOut = _currentEntry.type == 'out';
    final Color typeColor = isOut ? danger : success;
    final String typeText = isOut ? 'CASH OUT (-)' : 'CASH IN (+)';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Entry Details'),
        actions: [
          IconButton(icon: const Icon(Icons.delete_outline, color: danger), onPressed: _deleteEntry),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: borderCol)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('ENTRY TYPE', typeText, valueColor: typeColor, isLarge: true),
                const Divider(height: 24, color: borderCol),
                _buildDetailRow('AMOUNT', '${isOut ? "-" : "+"} ₹${_currentEntry.amount.toStringAsFixed(2)}', valueColor: typeColor, isLarge: true),
                const Divider(height: 24, color: borderCol),
                _buildDetailRow('DATE & TIME', _formatDateTime(_currentEntry.timestamp)),
                const Divider(height: 24, color: borderCol),
                _buildDetailRow('CATEGORY', _currentEntry.category.isEmpty ? 'N/A' : _currentEntry.category),
                const Divider(height: 24, color: borderCol),
                _buildDetailRow('PAYMENT METHOD', _currentEntry.paymentMethod.isEmpty ? 'N/A' : _currentEntry.paymentMethod),
                const Divider(height: 24, color: borderCol),
                _buildDetailRow('REMARK', _currentEntry.note.isEmpty ? 'N/A' : _currentEntry.note),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: appBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderCol)),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: textMuted, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Entry modified on\n${_formatDateTime(_currentEntry.timestamp)}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textMuted, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          if (_isLoadingLogs)
             const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: accent)))
          else if (editHistory.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.only(left: 8.0, bottom: 12.0),
              child: Text('EDIT HISTORY', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textLight, letterSpacing: 1.2)),
            ),
            ...editHistory.map((EditLog log) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderCol)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Changed: ${log.field}', style: const TextStyle(fontWeight: FontWeight.bold, color: textDark)),
                      Text(_formatDateTime(log.timestamp), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textMuted)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: dangerLight, borderRadius: BorderRadius.circular(8)),
                          child: Text(log.oldValue, style: const TextStyle(fontSize: 13, color: danger, decoration: TextDecoration.lineThrough)),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        child: Icon(Icons.arrow_forward, size: 16, color: textMuted),
                      ),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: successLight, borderRadius: BorderRadius.circular(8)),
                          child: Text(log.newValue, style: const TextStyle(fontSize: 13, color: success, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            )),
          ]
        ],
      ),

      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'edit_fab',
            onPressed: _openEditEditor,
            backgroundColor: accent,
            icon: const Icon(Icons.edit, color: Colors.white),
            label: const Text('Edit Entry', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
