import 'package:flutter/material.dart';
import 'dart:math';

import '../../core/models/book.dart';
import '../../core/models/entry.dart';
import '../../core/models/field_option.dart';
import '../../core/models/edit_log.dart';
import '../../core/database_helper.dart';
import '../../core/theme.dart';
import 'manage_options_screen.dart';

class AddEntryScreen extends StatefulWidget {
  final Book book;
  final Entry? existingEntry; 
  final String initialType; 

  const AddEntryScreen({super.key, required this.book, this.existingEntry, this.initialType = 'in'});

  @override
  State<AddEntryScreen> createState() => _AddEntryScreenState();
}

class _AddEntryScreenState extends State<AddEntryScreen> {
  late String _type;
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  
  String _selectedCategory = '';
  String _selectedPaymentMethod = '';
  
  List<FieldOption> _topCategories = [];
  List<FieldOption> _topPaymentMethods = [];

  bool get isEdit => widget.existingEntry != null;

  @override
  void initState() {
    super.initState();
    _type = widget.existingEntry?.type ?? widget.initialType;
    if (isEdit) {
      _amountCtrl.text = widget.existingEntry!.amount.toString();
      _noteCtrl.text = widget.existingEntry!.note;
      _selectedCategory = widget.existingEntry!.category;
      _selectedPaymentMethod = widget.existingEntry!.paymentMethod;
    }
    _loadTopOptions();
  }

  Future<void> _loadTopOptions() async {
    final cats = await DatabaseHelper.instance.getTopOptions('Category');
    final methods = await DatabaseHelper.instance.getTopOptions('Payment Method');
    
    if (cats.isEmpty) {
      await DatabaseHelper.instance.insertOption(FieldOption(id: 'c1', fieldName: 'Category', value: 'Sales', lastUsed: 0));
    }
    if (methods.isEmpty) {
      await DatabaseHelper.instance.insertOption(FieldOption(id: 'p1', fieldName: 'Payment Method', value: 'Cash', lastUsed: 0));
    }

    setState(() {
      _topCategories = cats;
      _topPaymentMethods = methods;
    });
    
    if (!isEdit && _selectedCategory.isEmpty && _topCategories.isNotEmpty) _selectedCategory = _topCategories.first.value;
    if (!isEdit && _selectedPaymentMethod.isEmpty && _topPaymentMethods.isNotEmpty) _selectedPaymentMethod = _topPaymentMethods.first.value;
  }

  Future<void> _openManageOptions(String fieldName) async {
    final selectedFromMore = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ManageOptionsScreen(fieldName: fieldName)),
    );
    
    await _loadTopOptions();
    
    if (selectedFromMore != null && selectedFromMore is String) {
      setState(() {
        if (fieldName == 'Category') _selectedCategory = selectedFromMore;
        if (fieldName == 'Payment Method') _selectedPaymentMethod = selectedFromMore;
      });
    }
  }

  Future<void> _saveEntry({required bool addNew}) async {
    if (_amountCtrl.text.isEmpty) return;

    final double amount = double.tryParse(_amountCtrl.text) ?? 0.0;
    int now = DateTime.now().millisecondsSinceEpoch;
    
    final entry = Entry(
      id: isEdit ? widget.existingEntry!.id : 'ENT-${Random().nextInt(999999)}',
      bookId: widget.book.id,
      type: _type,
      amount: amount,
      note: _noteCtrl.text.trim(),
      category: _selectedCategory,
      paymentMethod: _selectedPaymentMethod,
      timestamp: isEdit ? widget.existingEntry!.timestamp : now,
    );

    if (isEdit) {
      final old = widget.existingEntry!;
      
      // Calculate balance difference
      double oldSignedAmount = old.type == 'in' ? old.amount : -old.amount;
      double newSignedAmount = _type == 'in' ? amount : -amount;
      double difference = newSignedAmount - oldSignedAmount;
      
      // Apply the difference to the book balance
      widget.book.balance += difference;
      await DatabaseHelper.instance.updateBook(widget.book);

      // Log changes
      Future<void> logIfChanged(String field, String oldVal, String newVal) async {
        if (oldVal != newVal) {
          await DatabaseHelper.instance.insertEditLog(EditLog(
            id: 'LOG-${Random().nextInt(999999)}',
            entryId: old.id,
            field: field,
            oldValue: oldVal.isEmpty ? 'Empty' : oldVal,
            newValue: newVal.isEmpty ? 'Empty' : newVal,
            timestamp: now,
          ));
        }
      }

      await logIfChanged('Amount', old.amount.toString(), amount.toString());
      await logIfChanged('Type', old.type.toUpperCase(), _type.toUpperCase());
      await logIfChanged('Category', old.category, _selectedCategory);
      await logIfChanged('Payment Method', old.paymentMethod, _selectedPaymentMethod);
      await logIfChanged('Remark', old.note, _noteCtrl.text.trim());

      await DatabaseHelper.instance.updateEntry(entry);
      
    } else {
      // It's a brand new entry
      await DatabaseHelper.instance.insertEntry(entry);
      
      // Update book balance
      widget.book.balance += (_type == 'in' ? amount : -amount);
      await DatabaseHelper.instance.updateBook(widget.book);
    }
    
    // Boost the ranking of the used categories
    await DatabaseHelper.instance.recordOptionUsage('Category', _selectedCategory);
    await DatabaseHelper.instance.recordOptionUsage('Payment Method', _selectedPaymentMethod);

    if (addNew) {
      _amountCtrl.clear();
      _noteCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved! Add next entry.')));
      _loadTopOptions(); 
    } else {
      Navigator.pop(context, true); 
    }
  }

  Widget _buildOptionsRow(String title, String fieldName, List<FieldOption> options, String selectedValue, Function(String) onSelect) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textMuted)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...options.map((opt) {
              final isSelected = selectedValue == opt.value;
              return ChoiceChip(
                label: Text(opt.value, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.white : textDark)),
                selected: isSelected,
                selectedColor: accent,
                backgroundColor: appBg,
                showCheckmark: false,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: isSelected ? accent : borderCol)),
                onSelected: (selected) { if (selected) onSelect(opt.value); },
              );
            }),
            ActionChip(
              label: const Text('+ More', style: TextStyle(fontWeight: FontWeight.bold, color: accent)),
              backgroundColor: accentLight,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Colors.transparent)),
              onPressed: () => _openManageOptions(fieldName),
            ),
          ],
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Entry' : 'New Entry')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: appBg, borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _type = 'in'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(color: _type == 'in' ? success : Colors.transparent, borderRadius: BorderRadius.circular(12)),
                      child: Center(child: Text('CASH IN (+)', style: TextStyle(fontWeight: FontWeight.bold, color: _type == 'in' ? Colors.white : textMuted))),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _type = 'out'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(color: _type == 'out' ? danger : Colors.transparent, borderRadius: BorderRadius.circular(12)),
                      child: Center(child: Text('CASH OUT (-)', style: TextStyle(fontWeight: FontWeight.bold, color: _type == 'out' ? Colors.white : textMuted))),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _amountCtrl,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900),
            decoration: const InputDecoration(labelText: 'Amount', prefixText: '₹ ', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 24),
          _buildOptionsRow('CATEGORY', 'Category', _topCategories, _selectedCategory, (val) => setState(() => _selectedCategory = val)),
          const SizedBox(height: 24),
          _buildOptionsRow('PAYMENT METHOD', 'Payment Method', _topPaymentMethods, _selectedPaymentMethod, (val) => setState(() => _selectedPaymentMethod = val)),
          const SizedBox(height: 24),
          TextField(
            controller: _noteCtrl,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Remarks (Optional)', border: OutlineInputBorder()),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: isEdit 
            ? SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _saveEntry(addNew: false),
                  style: ElevatedButton.styleFrom(backgroundColor: accent, padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: const Text('Update Entry', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              )
            : Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _saveEntry(addNew: true),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), side: const BorderSide(color: accent)),
                      child: const Text('Save & Add New', style: TextStyle(color: accent, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _saveEntry(addNew: false),
                      style: ElevatedButton.styleFrom(backgroundColor: accent, padding: const EdgeInsets.symmetric(vertical: 16)),
                      child: const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
        ),
      ),
    );
  }
}
