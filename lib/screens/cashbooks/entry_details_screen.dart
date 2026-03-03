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
  Map<int, List<EditLog>> groupedLogs = {};
  final Map<String, String> _customFieldNames = {};
  bool _isLoadingLogs = true;

  @override
  void initState() {
    super.initState();
    _currentEntry = widget.entry;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoadingLogs = true);
    
    final logs = await DatabaseHelper.instance.getLogsForEntry(_currentEntry.id);
    final cfs = await DatabaseHelper.instance.getCustomFieldsForBook(widget.book.id);
    
    Map<int, List<EditLog>> grouped = {};
    for (var log in logs) {
      if (!grouped.containsKey(log.timestamp)) {
        grouped[log.timestamp] = [];
      }
      grouped[log.timestamp]!.add(log);
    }

    if (!mounted) return;
    setState(() {
      for (var cf in cfs) {
        _customFieldNames[cf.id] = cf.name;
      }
      groupedLogs = grouped;
      _isLoadingLogs = false;
    });
  }

  String _formatDateTime(int ms) {
    return DateFormat('MMM d, yyyy • h:mm a').format(DateTime.fromMillisecondsSinceEpoch(ms));
  }

  void _openEditEditor() async {
    final bool? didUpdate = await Navigator.push(context, MaterialPageRoute(builder: (context) => AddEntryScreen(book: widget.book, existingEntry: _currentEntry)));
    if (didUpdate == true) {
      final updatedEntry = await DatabaseHelper.instance.getEntryById(_currentEntry.id);
      if (!mounted) return; 
      if (updatedEntry != null) {
        setState(() => _currentEntry = updatedEntry);
        _loadData(); 
      }
    }
  }

  void _deleteEntry() async {
    final navigator = Navigator.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Entry?'),
        content: const Text('Are you sure you want to permanently delete this transaction?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: danger), onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.white)))
        ],
      )
    );

    if (confirm == true) {
      Entry? linked = await DatabaseHelper.instance.getLinkedEntry(_currentEntry.id);
      if (linked != null) {
        final lb = await DatabaseHelper.instance.getBookById(linked.bookId);
        if (lb != null) {
          lb.balance += (linked.type == 'in' ? -linked.amount : linked.amount);
          await DatabaseHelper.instance.updateBook(lb);
        }
        await DatabaseHelper.instance.deleteEntry(linked.id);
      }

      await DatabaseHelper.instance.deleteEntry(_currentEntry.id);
      double amountToReverse = _currentEntry.type == 'in' ? -_currentEntry.amount : _currentEntry.amount;
      widget.book.balance += amountToReverse;
      await DatabaseHelper.instance.updateBook(widget.book);
      navigator.pop(); 
    }
  }

  void _showShareSheet(BuildContext context) {
    int selectedOption = 0; 
    showModalBottomSheet(
      context: context, backgroundColor: Colors.white, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Share Entry', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textDark)),
              const SizedBox(height: 16),
              InkWell(
                onTap: () => setSheetState(() => selectedOption = 0), borderRadius: BorderRadius.circular(12),
                child: Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Row(children: [Icon(selectedOption == 0 ? Icons.radio_button_checked : Icons.radio_button_unchecked, color: selectedOption == 0 ? accent : textMuted), const SizedBox(width: 12), const Text('Share without Edit Logs', style: TextStyle(fontWeight: FontWeight.w600, color: textDark, fontSize: 16))])),
              ),
              InkWell(
                onTap: () => setSheetState(() => selectedOption = 1), borderRadius: BorderRadius.circular(12),
                child: Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Row(children: [Icon(selectedOption == 1 ? Icons.radio_button_checked : Icons.radio_button_unchecked, color: selectedOption == 1 ? accent : textMuted), const SizedBox(width: 12), const Text('Share including Edit Logs', style: TextStyle(fontWeight: FontWeight.w600, color: textDark, fontSize: 16))])),
              ),
              const SizedBox(height: 24),
              SizedBox(width: double.infinity, child: ElevatedButton.icon(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.share, color: Colors.white, size: 18), label: const Text('Share Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), style: ElevatedButton.styleFrom(backgroundColor: accent, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)))))
            ],
          ),
        ),
      )
    );
  }

  Widget _buildGridItem(String title, String val, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [Icon(icon, size: 12, color: textLight), const SizedBox(width: 4), Text(title.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: textMuted))]),
        const SizedBox(height: 4),
        Text(val.isEmpty ? '-' : val, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textDark), maxLines: 1, overflow: TextOverflow.ellipsis),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isIn = _currentEntry.type == 'in';
    final Color eColor = isIn ? success : danger;
    final Color eBg = isIn ? successLight : dangerLight;

    final dateStr = DateFormat('MMM d, yyyy').format(DateTime.fromMillisecondsSinceEpoch(_currentEntry.timestamp));
    final timeStr = DateFormat('h:mm a').format(DateTime.fromMillisecondsSinceEpoch(_currentEntry.timestamp));

    Map<String, dynamic> cFields = {};
    if (_currentEntry.customFields.isNotEmpty) {
      try { cFields = _currentEntry.customFields; } catch(_) { /* ignore map error */ }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Entry Details'),
        // FIXED: Hide Edit/Delete appbar actions if it's a Sub-Book
        actions: widget.book.parentId == null ? [
          IconButton(icon: const Icon(Icons.edit_outlined), onPressed: _openEditEditor),
          IconButton(icon: const Icon(Icons.delete_outline, color: danger), onPressed: _deleteEntry),
        ] : [],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: borderCol)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: eBg, borderRadius: BorderRadius.circular(8)), child: Text('CASH ${_currentEntry.type.toUpperCase()}', style: TextStyle(color: eColor, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1))),
                    
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('$dateStr • $timeStr', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textMuted)),
                        const SizedBox(height: 2),
                        Text('ID: ${_currentEntry.id}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: textLight)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text('₹${_currentEntry.amount.toStringAsFixed(2)}', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: eColor)),
                const SizedBox(height: 8),
                Text(_currentEntry.note, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textDark)),
                const Divider(height: 32, color: borderCol),
                
                GridView.count(
                  crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 3.0, mainAxisSpacing: 8, crossAxisSpacing: 12,
                  children: [
                    _buildGridItem('Category', _currentEntry.category, Icons.category),
                    _buildGridItem('Payment Mode', _currentEntry.paymentMethod, Icons.account_balance),
                    
                    ...cFields.entries.map((e) {
                      String fieldName = _customFieldNames[e.key] ?? 'Custom Field';
                      return _buildGridItem(fieldName, e.value.toString(), Icons.label_important);
                    }),
                  ],
                )
              ],
            ),
          ),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderCol)),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: textLight, size: 20),
                const SizedBox(width: 12),
                Expanded(child: Text('Entry created on ${_formatDateTime(groupedLogs.isEmpty ? _currentEntry.timestamp : groupedLogs.keys.last)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: textMuted))),
              ],
            ),
          ),

          if (groupedLogs.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: appBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderCol)),
              child: Row(
                children: [
                  const Icon(Icons.edit, color: textLight, size: 20),
                  const SizedBox(width: 12),
                  Expanded(child: Text('Entry last modified on ${_formatDateTime(_currentEntry.timestamp)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: textMuted))),
                ],
              ),
            ),
            
          const SizedBox(height: 24),

          const Padding(padding: EdgeInsets.only(left: 8, bottom: 12), child: Text('EDIT HISTORY', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textLight, letterSpacing: 1.2))),
          
          if (_isLoadingLogs)
             const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: accent)))
          else if (groupedLogs.isEmpty)
            Container(
              padding: const EdgeInsets.all(24), alignment: Alignment.center,
              decoration: BoxDecoration(color: Colors.transparent, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderCol, style: BorderStyle.solid)),
              child: const Text('No edit history found.', style: TextStyle(color: textMuted, fontWeight: FontWeight.w500)),
            )
          else
            ...groupedLogs.keys.map((timestamp) {
              final logs = groupedLogs[timestamp]!;
              return Container(
                margin: const EdgeInsets.only(bottom: 8), 
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderCol)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [const Icon(Icons.history, size: 12, color: textLight), const SizedBox(width: 6), Text(_formatDateTime(timestamp), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textMuted))]),
                    const SizedBox(height: 8),
                    ...logs.map((log) => Padding(
                      padding: const EdgeInsets.only(bottom: 6.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(width: 75, child: Text(log.field, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textDark))),
                          Expanded(
                            child: Row(
                              children: [
                                Flexible(child: Text(log.oldValue, style: const TextStyle(fontSize: 12, color: danger, decoration: TextDecoration.lineThrough, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
                                const Padding(padding: EdgeInsets.symmetric(horizontal: 6), child: Icon(Icons.arrow_forward, size: 12, color: textLight)),
                                Flexible(child: Text(log.newValue, style: const TextStyle(fontSize: 12, color: success, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                              ]
                            )
                          )
                        ],
                      ),
                    ))
                  ],
                ),
              );
            }),
          
          const SizedBox(height: 100), 
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Expanded(child: ElevatedButton.icon(onPressed: () => _showShareSheet(context), icon: const Icon(Icons.share, color: textDark), label: const Text('Share', style: TextStyle(color: textDark, fontWeight: FontWeight.bold)), style: ElevatedButton.styleFrom(backgroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: borderCol))))),
            
            // FIXED: Hides the big Edit Entry FAB if it's a Sub-Book
            if (widget.book.parentId == null) ...[
              const SizedBox(width: 12),
              Expanded(flex: 2, child: ElevatedButton.icon(onPressed: _openEditEditor, icon: const Icon(Icons.edit, color: Colors.white), label: const Text('Edit Entry', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), style: ElevatedButton.styleFrom(backgroundColor: accent, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))))),
            ]
          ],
        ),
      ),
    );
  }
}
