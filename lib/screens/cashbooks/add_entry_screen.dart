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
  late bool isCashIn;
  final TextEditingController _amountCtrl = TextEditingController();
  final TextEditingController _remarkCtrl = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  String selectedCategory = '';
  String selectedPayment = '';
  
  List<String> remarkSuggestions = [];
  List<FieldOption> _topCategories = [];
  List<FieldOption> _topPaymentMethods = [];

  bool get isEdit => widget.existingEntry != null;
  Color get activeColor => isCashIn ? success : danger;
  Color get activeBg => isCashIn ? successLight : dangerLight;

  @override
  void initState() {
    super.initState();
    isCashIn = (widget.existingEntry?.type ?? widget.initialType) == 'in';
    
    if (isEdit) {
      _amountCtrl.text = widget.existingEntry!.amount.toString();
      _remarkCtrl.text = widget.existingEntry!.note;
      selectedCategory = widget.existingEntry!.category;
      selectedPayment = widget.existingEntry!.paymentMethod;
      
      final d = DateTime.fromMillisecondsSinceEpoch(widget.existingEntry!.timestamp);
      _selectedDate = d;
      _selectedTime = TimeOfDay(hour: d.hour, minute: d.minute);
    }
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    // 1. Fetch dynamic remarks for this specific cashbook
    final remarks = await DatabaseHelper.instance.getRecentRemarks(widget.book.id);

    // 2. Fetch or create top options
    var cats = await DatabaseHelper.instance.getTopOptions('Category');
    var methods = await DatabaseHelper.instance.getTopOptions('Payment Method');
    
    if (cats.isEmpty) await DatabaseHelper.instance.insertOption(FieldOption(id: 'c1', fieldName: 'Category', value: 'General', lastUsed: 0));
    if (methods.isEmpty) await DatabaseHelper.instance.insertOption(FieldOption(id: 'p1', fieldName: 'Payment Method', value: 'Cash', lastUsed: 0));

    cats = await DatabaseHelper.instance.getTopOptions('Category');
    methods = await DatabaseHelper.instance.getTopOptions('Payment Method');

    // 3. Guarantee 'General' and 'Cash' are always visible even if they aren't the most recently used
    if (!cats.any((c) => c.value == 'General')) cats.insert(0, FieldOption(id: 'def_cat', fieldName: 'Category', value: 'General', lastUsed: 0));
    if (!methods.any((m) => m.value == 'Cash')) methods.insert(0, FieldOption(id: 'def_pay', fieldName: 'Payment Method', value: 'Cash', lastUsed: 0));

    if (!mounted) return;

    setState(() {
      remarkSuggestions = remarks;
      _topCategories = cats;
      _topPaymentMethods = methods;
    });
    
    // Note: We intentionally leave selectedCategory and selectedPayment empty for new entries!
  }

  Future<void> _openManageOptions(String fieldName) async {
    final selectedFromMore = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ManageOptionsScreen(fieldName: fieldName)),
    );
    
    await _loadInitialData();
    if (!mounted) return; 

    if (selectedFromMore != null && selectedFromMore is String) {
      setState(() {
        if (fieldName == 'Category') selectedCategory = selectedFromMore;
        if (fieldName == 'Payment Method') selectedPayment = selectedFromMore;
      });
    }
  }

  String _formatDate(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day.toString().padLeft(2, '0')} ${months[d.month - 1]} ${d.year}';
  }

  String _formatTime(TimeOfDay t) {
    final h = t.hour == 0 ? 12 : (t.hour > 12 ? t.hour - 12 : t.hour);
    final m = t.minute.toString().padLeft(2, '0');
    final period = t.hour >= 12 ? 'PM' : 'AM';
    return '${h.toString().padLeft(2, '0')}:$m $period';
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context, initialDate: _selectedDate, firstDate: DateTime(2000), lastDate: DateTime(2100),
      builder: (context, child) => Theme(data: Theme.of(context).copyWith(colorScheme: ColorScheme.light(primary: activeColor, onPrimary: Colors.white, onSurface: textDark)), child: child!),
    );
    if (date != null) {
      setState(() => _selectedDate = date);
      _pickTime();
    }
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context, initialTime: _selectedTime,
      builder: (context, child) => Theme(data: Theme.of(context).copyWith(colorScheme: ColorScheme.light(primary: activeColor, onPrimary: Colors.white, onSurface: textDark)), child: child!),
    );
    if (time != null) setState(() => _selectedTime = time);
  }

  Future<void> _saveEntry(bool addNew) async {
    // MANDATORY FIELDS VALIDATION
    if (_amountCtrl.text.isEmpty || _remarkCtrl.text.trim().isEmpty || selectedCategory.isEmpty || selectedPayment.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Amount, Remarks, Category, and Payment are required.'), 
        backgroundColor: danger, behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    final double amount = double.tryParse(_amountCtrl.text) ?? 0.0;
    final String typeStr = isCashIn ? 'in' : 'out';
    final DateTime combinedDate = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, _selectedTime.hour, _selectedTime.minute);
    
    final entry = Entry(
      id: isEdit ? widget.existingEntry!.id : 'ENT-${Random().nextInt(999999)}',
      bookId: widget.book.id,
      type: typeStr,
      amount: amount,
      note: _remarkCtrl.text.trim(),
      category: selectedCategory,
      paymentMethod: selectedPayment,
      timestamp: combinedDate.millisecondsSinceEpoch,
      linkedEntryId: isEdit ? widget.existingEntry!.linkedEntryId : null,
      customFields: isEdit ? widget.existingEntry!.customFields : {},
    );

    if (isEdit) {
      final old = widget.existingEntry!;
      double oldSignedAmount = old.type == 'in' ? old.amount : -old.amount;
      double newSignedAmount = typeStr == 'in' ? amount : -amount;
      widget.book.balance += (newSignedAmount - oldSignedAmount);
      await DatabaseHelper.instance.updateBook(widget.book);

      Future<void> logIfChanged(String field, String oldVal, String newVal) async {
        if (oldVal != newVal) {
          await DatabaseHelper.instance.insertEditLog(EditLog(id: 'LOG-${Random().nextInt(999999)}', entryId: old.id, field: field, oldValue: oldVal.isEmpty ? 'Empty' : oldVal, newValue: newVal.isEmpty ? 'Empty' : newVal, timestamp: DateTime.now().millisecondsSinceEpoch));
        }
      }
      
      // LOGGING DATE AND TIME CHANGES
      final oldDateObj = DateTime.fromMillisecondsSinceEpoch(old.timestamp);
      await logIfChanged('Date', _formatDate(oldDateObj), _formatDate(combinedDate));
      await logIfChanged('Time', _formatTime(TimeOfDay.fromDateTime(oldDateObj)), _formatTime(_selectedTime));

      await logIfChanged('Amount', old.amount.toString(), amount.toString());
      await logIfChanged('Type', old.type.toUpperCase(), typeStr.toUpperCase());
      await logIfChanged('Category', old.category, selectedCategory);
      await logIfChanged('Payment Method', old.paymentMethod, selectedPayment);
      await logIfChanged('Remark', old.note, _remarkCtrl.text.trim());

      await DatabaseHelper.instance.updateEntry(entry);
    } else {
      await DatabaseHelper.instance.insertEntry(entry);
      widget.book.balance += (typeStr == 'in' ? amount : -amount);
      await DatabaseHelper.instance.updateBook(widget.book);
    }
    
    await DatabaseHelper.instance.recordOptionUsage('Category', selectedCategory);
    await DatabaseHelper.instance.recordOptionUsage('Payment Method', selectedPayment);

    if (!mounted) return;

    if (addNew) {
      _amountCtrl.clear();
      _remarkCtrl.clear();
      setState(() {
        _selectedDate = DateTime.now();
        _selectedTime = TimeOfDay.now();
        selectedCategory = '';
        selectedPayment = '';
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Saved! Add next entry.'), backgroundColor: success));
      _loadInitialData(); 
    } else {
      Navigator.pop(context, true); 
    }
  }

  Widget _buildQuickChip(String label, String currentVal, Function(String) onSelect) {
    final bool isSelected = label == currentVal;
    return InkWell(
      onTap: () => onSelect(label),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(color: isSelected ? activeBg : appBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: isSelected ? activeColor : borderCol)),
        child: Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: isSelected ? activeColor : textMuted)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(isEdit ? 'Edit Entry' : 'Add Entry'),
            Text(widget.book.name, style: const TextStyle(fontSize: 12, color: textMuted, fontWeight: FontWeight.normal)),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // TYPE SWITCHER
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: appBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderCol)),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => isCashIn = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(color: isCashIn ? success : Colors.transparent, borderRadius: BorderRadius.circular(12), boxShadow: isCashIn ? [BoxShadow(color: success.withValues(alpha: 0.3), blurRadius: 4, offset: const Offset(0, 2))] : null),
                      alignment: Alignment.center,
                      child: Text('CASH IN', style: TextStyle(fontWeight: FontWeight.w900, color: isCashIn ? Colors.white : textMuted, letterSpacing: 0.5)),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => isCashIn = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(color: !isCashIn ? danger : Colors.transparent, borderRadius: BorderRadius.circular(12), boxShadow: !isCashIn ? [BoxShadow(color: danger.withValues(alpha: 0.3), blurRadius: 4, offset: const Offset(0, 2))] : null),
                      alignment: Alignment.center,
                      child: Text('CASH OUT', style: TextStyle(fontWeight: FontWeight.w900, color: !isCashIn ? Colors.white : textMuted, letterSpacing: 0.5)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // DATE & TIME
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: _pickDateTime,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(color: appBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderCol)),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, size: 18, color: activeColor),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_formatDate(_selectedDate), style: const TextStyle(fontWeight: FontWeight.bold, color: textDark, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: _pickTime,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(color: appBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderCol)),
                    child: Row(
                      children: [
                        Icon(Icons.access_time_filled, size: 18, color: activeColor),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_formatTime(_selectedTime), style: const TextStyle(fontWeight: FontWeight.bold, color: textDark, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // AMOUNT FIELD
          const Text('AMOUNT *', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textMuted, letterSpacing: 1)),
          const SizedBox(height: 8),
          TextField(
            controller: _amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: activeColor),
            decoration: InputDecoration(
              prefixText: '₹ ',
              prefixStyle: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: activeColor.withValues(alpha: 0.5)),
              filled: true, fillColor: activeBg.withValues(alpha: 0.3),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: activeColor, width: 2)),
            ),
          ),
          const SizedBox(height: 24),

          // REMARKS FIELD
          const Text('REMARKS *', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textMuted, letterSpacing: 1)),
          const SizedBox(height: 8),
          TextField(
            controller: _remarkCtrl,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: activeColor),
            decoration: InputDecoration(
              hintText: 'What was this for?',
              hintStyle: const TextStyle(color: textLight, fontWeight: FontWeight.normal),
              filled: true, fillColor: appBg,
              // Added Border/Edge to remarks field
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: borderCol)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: borderCol)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: activeColor, width: 2)),
            ),
          ),
          const SizedBox(height: 12),
          
          // DYNAMIC SUGGESTIONS
          if (remarkSuggestions.isNotEmpty)
            Wrap(
              spacing: 8, runSpacing: 8,
              children: remarkSuggestions.map((s) => InkWell(
                onTap: () => setState(() => _remarkCtrl.text = s),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: Colors.white, border: Border.all(color: borderCol), borderRadius: BorderRadius.circular(8)),
                  child: Text(s, style: const TextStyle(fontSize: 12, color: textMuted, fontWeight: FontWeight.w500)),
                ),
              )).toList(),
            ),
          if (remarkSuggestions.isNotEmpty) const SizedBox(height: 24),

          // CATEGORY
          const Text('CATEGORY *', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textMuted, letterSpacing: 1)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10, runSpacing: 10,
            children: [
              ..._topCategories.map((c) => _buildQuickChip(c.value, selectedCategory, (val) => setState(()=>selectedCategory = val))),
              InkWell(
                onTap: () => _openManageOptions('Category'),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderCol, style: BorderStyle.solid)),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.tune, size: 14, color: textMuted), SizedBox(width: 6), Text('More', style: TextStyle(fontWeight: FontWeight.w600, color: textMuted))]),
                ),
              )
            ],
          ),
          const SizedBox(height: 24),

          // PAYMENT METHOD
          const Text('PAYMENT METHOD *', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textMuted, letterSpacing: 1)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10, runSpacing: 10,
            children: [
              ..._topPaymentMethods.map((c) => _buildQuickChip(c.value, selectedPayment, (val) => setState(()=>selectedPayment = val))),
              InkWell(
                onTap: () => _openManageOptions('Payment Method'),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderCol, style: BorderStyle.solid)),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.tune, size: 14, color: textMuted), SizedBox(width: 6), Text('More', style: TextStyle(fontWeight: FontWeight.w600, color: textMuted))]),
                ),
              )
            ],
          ),
          const SizedBox(height: 120),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: isEdit 
          ? SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _saveEntry(false), 
                style: ElevatedButton.styleFrom(backgroundColor: activeColor, elevation: 4, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))), 
                child: const Text('UPDATE ENTRY', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1))
              ),
            )
          : Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _saveEntry(true), 
                    style: ElevatedButton.styleFrom(backgroundColor: activeBg, elevation: 0, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))), 
                    child: Text('Save & New', style: TextStyle(color: activeColor, fontWeight: FontWeight.bold))
                  )
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2, 
                  child: ElevatedButton(
                    onPressed: () => _saveEntry(false), 
                    style: ElevatedButton.styleFrom(backgroundColor: activeColor, elevation: 4, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))), 
                    child: const Text('SAVE ENTRY', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1))
                  )
                ),
              ],
            ),
      ),
    );
  }
}
