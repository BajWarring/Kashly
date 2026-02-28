import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/models/entry.dart';
import '../../core/theme.dart'; // Make sure your colors like textDark, appBg, accent are here

// --- MOCK DATA MODEL FOR EDIT HISTORY ---
// We will move this to your real models folder later
class EditLog {
  final String field;
  final String oldValue;
  final String newValue;
  final int timestamp;

  EditLog({required this.field, required this.oldValue, required this.newValue, required this.timestamp});
}

class EntryDetailsScreen extends StatefulWidget {
  final Entry entry;

  const EntryDetailsScreen({super.key, required this.entry});

  @override
  State<EntryDetailsScreen> createState() => _EntryDetailsScreenState();
}

class _EntryDetailsScreenState extends State<EntryDetailsScreen> {
  // Mock data for UI demonstration
  final String category = "Office Supplies";
  final String paymentMethod = "Credit Card";
  final int createdAt = DateTime.now().subtract(const Duration(days: 2)).millisecondsSinceEpoch;
  
  // Mock edit history (sorted descending by default)
  final List<EditLog> editHistory = [
    EditLog(field: 'Amount', oldValue: '500.0', newValue: '550.0', timestamp: DateTime.now().subtract(const Duration(hours: 2)).millisecondsSinceEpoch),
    EditLog(field: 'Remark', oldValue: 'Pens', newValue: 'Pens and Paper', timestamp: DateTime.now().subtract(const Duration(hours: 2)).millisecondsSinceEpoch),
    EditLog(field: 'Category', oldValue: 'Misc', newValue: 'Office Supplies', timestamp: DateTime.now().subtract(const Duration(days: 1)).millisecondsSinceEpoch),
  ];

  String _formatDateTime(int ms) {
    return DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.fromMillisecondsSinceEpoch(ms));
  }

  void _deleteEntry() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Entry?'),
        content: const Text('Are you sure you want to permanently delete this transaction?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: danger),
            onPressed: () {
              // TODO: Delete from SQLite database
              Navigator.pop(ctx); // Close dialog
              Navigator.pop(context); // Go back to cashbook
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          )
        ],
      )
    );
  }

  void _showShareOptions() {
    bool includeHistory = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateSheet) => Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Share Entry', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textDark)),
              const SizedBox(height: 16),
              
              // Option 1: Without History (Default)
              RadioListTile<bool>(
                value: false,
                groupValue: includeHistory,
                onChanged: (val) => setStateSheet(() => includeHistory = val!),
                title: const Text('Standard Share', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Share basic entry details only.'),
                activeColor: accent,
                contentPadding: EdgeInsets.zero,
              ),
              
              // Option 2: With History
              RadioListTile<bool>(
                value: true,
                groupValue: includeHistory,
                onChanged: (val) => setStateSheet(() => includeHistory = val!),
                title: const Text('Include Edit History', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Share full details including all past edits.'),
                activeColor: accent,
                contentPadding: EdgeInsets.zero,
              ),
              
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Implement actual sharing logic
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sharing ${includeHistory ? "with" : "without"} history...')));
                  },
                  icon: const Icon(Icons.share, color: Colors.white),
                  label: const Text('Share Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              )
            ],
          ),
        ),
      )
    );
  }

  void _openEditEditor() {
    // TODO: Open an edit screen pre-filled with this entry's data
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Edit editor opening...')));
  }

  // Helper widget to build rows inside cards
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
    final bool isOut = widget.entry.type == 'out';
    final Color typeColor = isOut ? danger : success;
    final String typeText = isOut ? 'CASH OUT (-)' : 'CASH IN (+)';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Entry Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: danger),
            onPressed: _deleteEntry,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          
          // 1. MAIN CARD (Big Rectangle)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: borderCol)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('ENTRY TYPE', typeText, valueColor: typeColor, isLarge: true),
                const Divider(height: 24, color: borderCol),
                _buildDetailRow('AMOUNT', '${isOut ? "-" : "+"} ${widget.entry.amount}', valueColor: typeColor, isLarge: true),
                const Divider(height: 24, color: borderCol),
                _buildDetailRow('DATE & TIME', _formatDateTime(widget.entry.timestamp)),
                const Divider(height: 24, color: borderCol),
                _buildDetailRow('CATEGORY', category),
                const Divider(height: 24, color: borderCol),
                _buildDetailRow('PAYMENT METHOD', paymentMethod),
                const Divider(height: 24, color: borderCol),
                _buildDetailRow('REMARK', widget.entry.note.isEmpty ? 'N/A' : widget.entry.note),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2. ADDITIONAL FIELDS CARD
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: borderCol)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('ADDITIONAL DETAILS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textMuted, letterSpacing: 1.2)),
                const SizedBox(height: 12),
                _buildDetailRow('Reference No.', 'REF-90210'), // Dummy additional field
                const Divider(height: 24, color: borderCol),
                _buildDetailRow('Billed To', 'Client Alpha'), // Dummy additional field
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 3. CREATION CARD
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: appBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderCol)),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: textMuted, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Entry first created on\n${_formatDateTime(createdAt)}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textMuted, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // 4. EDIT HISTORY CARDS
          if (editHistory.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.only(left: 8.0, bottom: 12.0),
              child: Text('EDIT HISTORY', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textLight, letterSpacing: 1.2)),
            ),
            ...editHistory.map((log) => Container(
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

      // 5. BOTTOM FAB BUTTONS
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'share_fab',
            onPressed: _showShareOptions,
            backgroundColor: Colors.white,
            child: const Icon(Icons.share, color: textDark),
          ),
          const SizedBox(width: 16),
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
