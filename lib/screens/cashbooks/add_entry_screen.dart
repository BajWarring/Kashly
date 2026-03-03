import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math';

import '../../core/models/book.dart';
import '../../core/models/entry.dart';
import '../../core/models/field_option.dart';
import '../../core/models/custom_field.dart';
import '../../core/models/currency.dart';
import '../../core/models/edit_log.dart';
import '../../core/database_helper.dart';
import '../../core/theme.dart';
import 'manage_options_screen.dart';
import 'manage_custom_fields_screen.dart';

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
  String _currencySymbol = '₹';
  
  List<String> remarkSuggestions = [];
  List<FieldOption> _topCategories = [];
  List<FieldOption> _topPaymentMethods = [];

  List<CustomField> _customFieldsData = [];
  final Map<String, String> _customFieldValues = {};

  bool get isEdit => widget.existingEntry != null;
  Color get activeColor => isCashIn ? success : danger;
  Color get activeBg => isCashIn ? successLight : dangerLight;

  @override
  void initState() {
    super.initState();
    isCashIn = (widget.existingEntry?.type ?? widget.initialType) == 'in';
    
    _currencySymbol = worldCurrencies.firstWhere((c) => c.code == widget.book.currency, orElse: () => worldCurrencies[0]).symbol;
    
    if (isEdit) {
      _amountCtrl.text = widget.existingEntry!.amount.toString();
      _remarkCtrl.text = widget.existingEntry!.note;
      selectedCategory = widget.existingEntry!.category;
      selectedPayment = widget.existingEntry!.paymentMethod;
      
      final d = DateTime.fromMillisecondsSinceEpoch(widget.existingEntry!.timestamp);
      _selectedDate = d;
      _selectedTime = TimeOfDay(hour: d.hour, minute: d.minute);

      if (widget.existingEntry!.customFields.isNotEmpty) {
        widget.existingEntry!.customFields.forEach((key, value) {
          _customFieldValues[key] = value.toString();
        });
      }
    }
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final remarks = await DatabaseHelper.instance.getRecentRemarks(widget.book.id);
    final cFields = await DatabaseHelper.instance.getCustomFieldsForBook(widget.book.id);
    
    var cats = await DatabaseHelper.instance.getTopOptions('Category');
    var methods = await DatabaseHelper.instance.getTopOptions('Payment Method');
    
    if (cats.isEmpty) await DatabaseHelper.instance.insertOption(FieldOption(id: 'c1', fieldName: 'Category', value: 'General', lastUsed: 0));
    if (methods.isEmpty) await DatabaseHelper.instance.insertOption(FieldOption(id: 'p1', fieldName: 'Payment Method', value: 'Cash', lastUsed: 0));

    cats = await DatabaseHelper.instance.getTopOptions('Category');
    methods = await DatabaseHelper.instance.getTopOptions('Payment Method');

    if (!cats.any((c) => c.value == 'General')) cats.insert(0, FieldOption(id: 'def_cat', fieldName: 'Category', value: 'General', lastUsed: 0));
    if (!methods.any((m) => m.value == 'Cash')) methods.insert(0, FieldOption(id: 'def_pay', fieldName: 'Payment Method', value: 'Cash', lastUsed: 0));

    if (!mounted) return;

    setState(() {
      remarkSuggestions = remarks;
      _customFieldsData = cFields;
      _topCategories = cats;
      _topPaymentMethods = methods;
    });
  }

  Future<void> _openManageOptions(String fieldName) async {
    final selectedFromMore = await Navigator.push(context, MaterialPageRoute(builder: (_) => ManageOptionsScreen(fieldName: fieldName)));
    await _loadInitialData();
    if (!mounted) return; 
    if (selectedFromMore != null && selectedFromMore is String) {
      setState(() {
        if (fieldName == 'Category') selectedCategory = selectedFromMore;
        if (fieldName == 'Payment Method') selectedPayment = selectedFromMore;
      });
    }
  }

  String _formatDate(DateTime d) => DateFormat('MMM d, yyyy').format(d);
  String _formatTime(TimeOfDay t) => DateFormat('h:mm a').format(DateTime(2020, 1, 1, t.hour, t.minute));

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime(2000), lastDate: DateTime(2100), builder: (context, child) => Theme(data: Theme.of(context).copyWith(colorScheme: ColorScheme.light(primary: activeColor, onPrimary: Colors.white, onSurface: textDark)), child: child!));
    if (date != null) { setState(() => _selectedDate = date); _pickTime(); }
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(context: context, initialTime: _selectedTime, builder: (context, child) => Theme(data: Theme.of(context).copyWith(colorScheme: ColorScheme.light(primary: activeColor, onPrimary: Colors.white, onSurface: textDark)), child: child!));
    if (time != null) setState(() => _selectedTime = time);
  }

  Future<void> _saveEntry(bool addNew) async {
    if (_amountCtrl.text.isEmpty || _remarkCtrl.text.trim().isEmpty || selectedCategory.isEmpty || selectedPayment.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Amount, Remarks, Category, and Payment are mandatory.'), backgroundColor: danger, behavior: SnackBarBehavior.floating));
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
      customFields: Map<String, dynamic>.from(_customFieldValues),
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
      
      final oldDateObj = DateTime.fromMillisecondsSinceEpoch(old.timestamp);
      await logIfChanged('Date', _formatDate(oldDateObj), _formatDate(combinedDate));
      await logIfChanged('Time', _formatTime(TimeOfDay.fromDateTime(oldDateObj)), _formatTime(_selectedTime));
      await logIfChanged('Amount', old.amount.toString(), amount.toString());
      await logIfChanged('Type', old.type.toUpperCase(), typeStr.toUpperCase());
      await logIfChanged('Category', old.category, selectedCategory);
      await logIfChanged('Payment Method', old.paymentMethod, selectedPayment);
      await logIfChanged('Remark', old.note, _remarkCtrl.text.trim());

      // FIXED: Iterating over Custom Fields to create logs using their actual Name
      Map<String, dynamic> oldCF = {};
      if (old.customFields.isNotEmpty) {
        try { oldCF = old.customFields; } catch(_) {}
      }
      for (var cf in _customFieldsData) {
        String oldVal = oldCF[cf.id]?.toString() ?? '';
        String newVal = _customFieldValues[cf.id] ?? '';
        await logIfChanged(cf.name, oldVal, newVal); 
      }

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
        _customFieldValues.clear();
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
      onTap: () => onSelect(label), borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(color: isSelected ? activeBg : Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: isSelected ? activeColor : borderCol, width: 1.5)),
        child: Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: isSelected ? activeColor : textDark)),
      ),
    );
  }

  Widget _buildCustomFieldInput(CustomField field) {
    String val = _customFieldValues[field.id] ?? '';
    
    Widget inputWidget;
    if (field.type == 'Dropdown' && field.options.isNotEmpty) {
      List<String> opts = field.options.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      inputWidget = Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderCol, width: 1.5)),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            isExpanded: true,
            value: opts.contains(val) ? val : null,
            hint: const Text('Select option', style: TextStyle(color: textMuted)),
            items: opts.map((String value) => DropdownMenuItem<String>(value: value, child: Text(value))).toList(),
            onChanged: (newValue) => setState(() => _customFieldValues[field.id] = newValue!),
          ),
        ),
      );
    } else if (field.type == 'Radio' && field.options.isNotEmpty) {
      List<String> opts = field.options.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      inputWidget = Wrap(
        spacing: 10, runSpacing: 10,
        children: opts.map((o) => _buildQuickChip(o, val, (selected) => setState(() => _customFieldValues[field.id] = selected))).toList()
      );
    } else if (field.type == 'Contacts') {
      List<String> contacts = ['John Doe', 'Jane Smith', 'Supplier A', 'Vendor B']; 
      inputWidget = Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderCol, width: 1.5)),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            isExpanded: true,
            icon: const Icon(Icons.contact_page, color: textMuted),
            value: contacts.contains(val) ? val : null,
            hint: const Text('Select from Contacts', style: TextStyle(color: textMuted)),
            items: contacts.map((String value) => DropdownMenuItem<String>(value: value, child: Text(value))).toList(),
            onChanged: (newValue) => setState(() => _customFieldValues[field.id] = newValue!),
          ),
        ),
      );
    } else {
      inputWidget = TextField(
        onChanged: (text) => _customFieldValues[field.id] = text,
        controller: TextEditingController(text: val)..selection = TextSelection.collapsed(offset: val.length),
        decoration: InputDecoration(hintText: 'Enter ${field.name}', hintStyle: const TextStyle(color: textMuted), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: borderCol, width: 1.5)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: borderCol, width: 1.5)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: activeColor, width: 2))),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(field.name.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textMuted, letterSpacing: 1)),
          const SizedBox(height: 8),
          inputWidget,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [Text(isEdit ? 'Edit Entry' : 'Add Entry'), Text(widget.book.name, style: const TextStyle(fontSize: 12, color: textMuted, fontWeight: FontWeight.normal))])),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: appBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderCol)),
            child: Row(children: [
              Expanded(child: GestureDetector(onTap: () => setState(() => isCashIn = true), child: Container(padding: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: isCashIn ? success : Colors.transparent, borderRadius: BorderRadius.circular(12), boxShadow: isCashIn ? [BoxShadow(color: success.withValues(alpha: 0.3), blurRadius: 4, offset: const Offset(0, 2))] : null), alignment: Alignment.center, child: Text('CASH IN', style: TextStyle(fontWeight: FontWeight.w900, color: isCashIn ? Colors.white : textMuted, letterSpacing: 0.5))))),
              Expanded(child: GestureDetector(onTap: () => setState(() => isCashIn = false), child: Container(padding: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: !isCashIn ? danger : Colors.transparent, borderRadius: BorderRadius.circular(12), boxShadow: !isCashIn ? [BoxShadow(color: danger.withValues(alpha: 0.3), blurRadius: 4, offset: const Offset(0, 2))] : null), alignment: Alignment.center, child: Text('CASH OUT', style: TextStyle(fontWeight: FontWeight.w900, color: !isCashIn ? Colors.white : textMuted, letterSpacing: 0.5))))),
            ]),
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(child: InkWell(onTap: _pickDateTime, borderRadius: BorderRadius.circular(16), child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderCol, width: 1.5)), child: Row(children: [Icon(Icons.calendar_today, size: 18, color: activeColor), const SizedBox(width: 8), Expanded(child: Text(_formatDate(_selectedDate), style: const TextStyle(fontWeight: FontWeight.bold, color: textDark, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis))])))),
              const SizedBox(width: 12),
              Expanded(child: InkWell(onTap: _pickTime, borderRadius: BorderRadius.circular(16), child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderCol, width: 1.5)), child: Row(children: [Icon(Icons.access_time_filled, size: 18, color: activeColor), const SizedBox(width: 8), Expanded(child: Text(_formatTime(_selectedTime), style: const TextStyle(fontWeight: FontWeight.bold, color: textDark, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis))])))),
            ],
          ),
          const SizedBox(height: 24),

          const Text('AMOUNT *', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textMuted, letterSpacing: 1)),
          const SizedBox(height: 8),
          TextField(
            controller: _amountCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: textDark),
            decoration: InputDecoration(
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 16, right: 8),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [Text(_currencySymbol, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: textDark))]),
              ),
              hintText: '0.00', hintStyle: const TextStyle(color: textLight),
              filled: true, fillColor: Colors.white, 
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: borderCol, width: 1.5)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: borderCol, width: 1.5)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: activeColor, width: 2)),
            ),
          ),
          const SizedBox(height: 24),

          const Text('REMARKS *', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textMuted, letterSpacing: 1)),
          const SizedBox(height: 8),
          TextField(
            controller: _remarkCtrl, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textDark),
            decoration: InputDecoration(
              hintText: 'What was this for?', hintStyle: const TextStyle(color: textMuted, fontWeight: FontWeight.normal),
              filled: true, fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: borderCol, width: 1.5)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: borderCol, width: 1.5)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: activeColor, width: 2)),
            ),
          ),
          const SizedBox(height: 12),
          
          if (remarkSuggestions.isNotEmpty)
            Wrap(spacing: 8, runSpacing: 8, children: remarkSuggestions.map((s) => InkWell(onTap: () => setState(() => _remarkCtrl.text = s), borderRadius: BorderRadius.circular(8), child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: Colors.white, border: Border.all(color: borderCol), borderRadius: BorderRadius.circular(8)), child: Text(s, style: const TextStyle(fontSize: 12, color: textMuted, fontWeight: FontWeight.w500))))).toList()),
          if (remarkSuggestions.isNotEmpty) const SizedBox(height: 24),

          const Text('CATEGORY *', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textMuted, letterSpacing: 1)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10, runSpacing: 10,
            children: [
              ..._topCategories.map((c) => _buildQuickChip(c.value, selectedCategory, (val) => setState(()=>selectedCategory = val))),
              InkWell(onTap: () => _openManageOptions('Category'), borderRadius: BorderRadius.circular(12), child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderCol, width: 1.5)), child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.tune, size: 14, color: textDark), SizedBox(width: 6), Text('More', style: TextStyle(fontWeight: FontWeight.w600, color: textDark))]))),
            ],
          ),
          const SizedBox(height: 24),

          const Text('PAYMENT METHOD *', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textMuted, letterSpacing: 1)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10, runSpacing: 10,
            children: [
              ..._topPaymentMethods.map((c) => _buildQuickChip(c.value, selectedPayment, (val) => setState(()=>selectedPayment = val))),
              InkWell(onTap: () => _openManageOptions('Payment Method'), borderRadius: BorderRadius.circular(12), child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderCol, width: 1.5)), child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.tune, size: 14, color: textDark), SizedBox(width: 6), Text('More', style: TextStyle(fontWeight: FontWeight.w600, color: textDark))]))),
            ],
          ),
          const SizedBox(height: 32),

          if (_customFieldsData.isNotEmpty) ...[
            const Divider(color: borderCol),
            const SizedBox(height: 24),
            ..._customFieldsData.map((field) => _buildCustomFieldInput(field)),
          ],

          InkWell(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ManageCustomFieldsScreen(bookId: widget.book.id))).then((_) => _loadInitialData()),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderCol, width: 1.5)),
              child: Row(children: [Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: appBg, shape: BoxShape.circle), child: const Icon(Icons.dashboard_customize, color: accent, size: 20)), const SizedBox(width: 16), const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Manage Custom Fields', style: TextStyle(fontWeight: FontWeight.bold, color: textDark)), Text('Add Party, Image, or Custom Text fields', style: TextStyle(fontSize: 11, color: textMuted))])), const Icon(Icons.chevron_right, color: textLight)]),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: borderCol))),
        padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: MediaQuery.of(context).padding.bottom + 16),
        child: isEdit 
          ? SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => _saveEntry(false), style: ElevatedButton.styleFrom(backgroundColor: activeColor, elevation: 0, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))), child: const Text('UPDATE ENTRY', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1))))
          : Row(
              children: [
                Expanded(child: ElevatedButton(onPressed: () => _saveEntry(true), style: ElevatedButton.styleFrom(backgroundColor: activeBg, elevation: 0, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))), child: Text('Save & New', style: TextStyle(color: activeColor, fontWeight: FontWeight.bold)))),
                const SizedBox(width: 12),
                Expanded(flex: 2, child: ElevatedButton(onPressed: () => _saveEntry(false), style: ElevatedButton.styleFrom(backgroundColor: activeColor, elevation: 0, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))), child: const Text('SAVE ENTRY', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)))),
              ],
            ),
      ),
    );
  }
}
