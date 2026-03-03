import 'package:flutter/material.dart';
import 'dart:math';

import '../../../../core/models/book.dart';
import '../../../../core/models/currency.dart';
import '../../../../core/database_helper.dart';
import '../../../../core/theme.dart';
import '../cashbook_screen.dart';

class SubBooksSheet extends StatefulWidget {
  final Book mainBook;
  const SubBooksSheet({super.key, required this.mainBook});

  @override
  State<SubBooksSheet> createState() => _SubBooksSheetState();
}

class _SubBooksSheetState extends State<SubBooksSheet> {
  List<Book> _subBooks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSubBooks();
  }

  Future<void> _loadSubBooks() async {
    setState(() => _isLoading = true);
    final data = await DatabaseHelper.instance.getSubBooks(widget.mainBook.id);
    if (!mounted) return;
    setState(() {
      _subBooks = data;
      _isLoading = false;
    });
  }

  void _addNewSubBook() async {
    final ctrl = TextEditingController();
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Sub Cashbook', style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: ctrl, autofocus: true, textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(hintText: 'e.g. Petty Cash, Bank A/C', filled: true, fillColor: appBg, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: accent), onPressed: () => Navigator.pop(ctx, ctrl.text), child: const Text('Create', style: TextStyle(color: Colors.white))),
        ]
      )
    );

    if (newName != null && newName.trim().isNotEmpty) {
      final newBook = Book(
        id: 'SUB-${10000 + Random().nextInt(90000)}',
        name: newName.trim(), description: 'Sub-book of ${widget.mainBook.name}', balance: 0,
        createdAt: DateTime.now().millisecondsSinceEpoch, timestamp: DateTime.now().millisecondsSinceEpoch,
        currency: widget.mainBook.currency, icon: 'briefcase', parentId: widget.mainBook.id,
      );
      await DatabaseHelper.instance.insertBook(newBook);
      _loadSubBooks();
    }
  }

  String _formatCur(double amt) {
    String sym = worldCurrencies.firstWhere((c) => c.code == widget.mainBook.currency, orElse: () => worldCurrencies[0]).symbol;
    String formatted = amt.abs().toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
    return amt < 0 ? '-$sym$formatted' : '$sym$formatted';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: borderCol, borderRadius: BorderRadius.circular(10)), margin: const EdgeInsets.only(bottom: 20))),
            Text('${widget.mainBook.name} Sub-Books', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textDark)),
            const SizedBox(height: 16),
            
            if (_isLoading)
              const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: accent)))
            else if (_subBooks.isEmpty)
              Container(padding: const EdgeInsets.all(24), alignment: Alignment.center, decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: borderCol, style: BorderStyle.solid)), child: const Text('No sub-books yet. Add one to track transfers!', style: TextStyle(color: textMuted, fontWeight: FontWeight.w600)))
            else
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _subBooks.length,
                  itemBuilder: (ctx, i) {
                    final sb = _subBooks[i];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(width: 40, height: 40, decoration: BoxDecoration(color: accentLight, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.account_tree, color: accent, size: 20)),
                      title: Text(sb.name, style: const TextStyle(fontWeight: FontWeight.bold, color: textDark)),
                      trailing: Text(_formatCur(sb.balance), style: TextStyle(fontWeight: FontWeight.w900, color: sb.balance < 0 ? danger : success)),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (_) => CashbookScreen(book: sb)));
                      },
                    );
                  }
                ),
              ),
            
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _addNewSubBook,
                icon: const Icon(Icons.add, color: Colors.white), label: const Text('Add Sub Book', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(backgroundColor: textDark, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              ),
            )
          ],
        ),
      ),
    );
  }
}
