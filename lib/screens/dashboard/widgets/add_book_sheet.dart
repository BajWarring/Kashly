import 'package:flutter/material.dart';
import 'dart:math';

import '../../../core/models/book.dart';
import '../../../core/models/currency.dart'; // FIXED: Imported Currency Model
import '../../../core/theme.dart';

class AddBookSheet extends StatefulWidget {
  final Function(Book) onAdd;
  const AddBookSheet({super.key, required this.onAdd});
  
  @override
  State<AddBookSheet> createState() => _AddBookSheetState();
}

class _AddBookSheetState extends State<AddBookSheet> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  Currency _selectedCurrency = worldCurrencies[0];
  String _searchQuery = '';

  void _submit() {
    if (_nameCtrl.text.trim().isEmpty) return;
    int now = DateTime.now().millisecondsSinceEpoch;
    widget.onAdd(Book(
      id: 'KB-${100000 + Random().nextInt(900000)}',
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      balance: 0,
      createdAt: now,
      timestamp: now,
      currency: _selectedCurrency.code,
      icon: 'wallet',
    ));
    Navigator.pop(context);
  }

  void _pickCurrency() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final filteredList = worldCurrencies.where((c) => c.name.toLowerCase().contains(_searchQuery.toLowerCase()) || c.code.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
          return DraggableScrollableSheet(
            initialChildSize: 0.7, minChildSize: 0.5, maxChildSize: 0.9, expand: false,
            builder: (context, scrollController) => Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    autofocus: true,
                    decoration: InputDecoration(hintText: 'Search currency...', prefixIcon: const Icon(Icons.search), filled: true, fillColor: appBg, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
                    onChanged: (val) => setModalState(() => _searchQuery = val),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: filteredList.length,
                    itemBuilder: (c, i) => ListTile(
                      leading: Container(width: 40, height: 40, alignment: Alignment.center, decoration: BoxDecoration(color: appBg, borderRadius: BorderRadius.circular(12)), child: Text(filteredList[i].symbol, style: const TextStyle(fontWeight: FontWeight.bold, color: textDark, fontSize: 16))),
                      title: Text(filteredList[i].code, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(filteredList[i].name),
                      onTap: () {
                        setState(() => _selectedCurrency = filteredList[i]);
                        Navigator.pop(ctx);
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      )
    );
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
            const Text('New Cashbook', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textDark)),
            const SizedBox(height: 24),
            const Text('BOOK NAME', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textMuted, letterSpacing: 1)),
            const SizedBox(height: 8),
            TextField(
              controller: _nameCtrl, autofocus: true,
              decoration: InputDecoration(hintText: 'e.g. Project Alpha', filled: true, fillColor: appBg, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: accent, width: 2))),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            const Text('DESCRIPTION (OPTIONAL)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textMuted, letterSpacing: 1)),
            const SizedBox(height: 8),
            TextField(
              controller: _descCtrl, maxLines: 2,
              decoration: InputDecoration(hintText: 'Brief notes...', filled: true, fillColor: appBg, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: accent, width: 2))),
            ),
            const SizedBox(height: 16),
            const Text('BASE CURRENCY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textMuted, letterSpacing: 1)),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickCurrency,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(color: appBg, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    Text(_selectedCurrency.symbol, style: const TextStyle(fontWeight: FontWeight.bold, color: textDark, fontSize: 16)),
                    const SizedBox(width: 12),
                    Text('${_selectedCurrency.code} - ${_selectedCurrency.name}', style: const TextStyle(fontWeight: FontWeight.w600, color: textDark)),
                    const Spacer(),
                    const Icon(Icons.keyboard_arrow_down, color: textMuted),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(backgroundColor: accent, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
                child: const Text('Create Book', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            )
          ],
        ),
      ),
    );
  }
}
