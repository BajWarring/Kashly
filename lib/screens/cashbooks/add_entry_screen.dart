import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math';

import '../../core/models/book.dart';
import '../../core/models/entry.dart';
import '../../core/models/field_option.dart';
import '../../core/models/custom_field.dart';
import '../../core/models/currency.dart';
import '../../core/models/edit_log.dart';
import '../../core/data/database_helper.dart';
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

  List<Book> _availableBooksToLink = [];
  Book? _selectedLinkedBook;

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
        try {
          Map<String, dynamic> cFields = widget.existingEntry!.customFields;
          cFields.forEach((key, value) {
            _customFieldValues[key] = value.toString();
          });
        } catch(_) {}
      }
    }
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final remarks = await DatabaseHelper.instance.getRecentRemarks(widget.book.id);
    final cFields = await DatabaseHelper.instance.getCustomFieldsForBook(widget.book.id);
    
    final allBooks = await DatabaseHelper.instance.getAllBooks();
    _availableBooksToLink = allBooks.where((b) => b.id != widget.book.id).toList();
    
    if (isEdit) {
      Entry? linked = await DatabaseHelper.instance.getLinkedEntry(widget.existingEntry!.id);
      if (linked != null) {
        Book? linkedBk = await DatabaseHelper.instance.getBookById(linked.bookId);
        if (linkedBk != null && linkedBk.id != widget.book.id) {
          _selectedLinkedBook = linkedBk;
        }
      }
    }
    
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

  Future<bool> _showLinkTip() async {
    if (DatabaseHelper.hideLinkTip) return true;
    bool localHide = false;
    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (c, setS) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(children: [Icon(Icons.link, color: accent), SizedBox(width: 8), Text('Link Cashbooks')]),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Linking an entry will automatically create a corresponding entry in the selected cashbook with the opposite type (e.g., Cash In becomes Cash Out). This helps track transfers between books.'),
              const SizedBox(height: 16),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: accent,
                value: localHide,
                onChanged: (v) => setS(() => localHide = v ?? false),
                title: const Text('Do not show again', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              )
            ]
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: accent),
              onPressed: () {
                DatabaseHelper.hideLinkTip = localHide;
                Navigator.pop(ctx, true);
              },
              child: const Text('OK', style: TextStyle(color: Colors.white))
            )
          ]
        )
      )
    );
    return res ?? false;
  }

  Future<void> _handleLinkButton() async {
    if (!DatabaseHelper.hideLinkTip) {
      bool proceed = await _showLinkTip();
      if (!proceed) return;
    }

    if (!mounted) return;

    if (_availableBooksToLink.isEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('No other cashbooks'),
          content: const Text('Add more cashbooks to link entries between them.'),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))]
        )
      );
      return;
    }

    final selected = await showModalBottomSheet<Book>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select Cashbook to Link', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: appBg, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.link_off, color: textMuted, size: 20)),
              title: const Text('None (Remove Link)', style: TextStyle(color: textMuted, fontWeight: FontWeight.w600)),
              onTap: () => Navigator.pop(ctx, Book(id: 'REMOVE', name: '', description: '', balance: 0, createdAt: 0, timestamp: 0, currency: '', icon: '')),
            ),
            const Divider(height: 1),
            ..._availableBooksToLink.map((b) => ListTile(
              leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: accentLight, borderRadius: BorderRadius.circular(8)), child: Icon(availableIcons[b.icon] ?? Icons.book, color: accent, size: 20)),
              title: Text(b.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              trailing: _selectedLinkedBook?.id == b.id ? const Icon(Icons.check_circle, color: accent) : null,
              onTap: () => Navigator.pop(ctx, b),
            ))
          ]
        )
      )
    );

    if (selected != null) {
      if (selected.id == 'REMOVE') {
        setState(() => _selectedLinkedBook = null);
      } else {
        setState(() => _selectedLinkedBook = selected);
      }
    }
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
      bookId: widget.book.id, type: typeStr, amount: amount, note: _remarkCtrl.text.trim(),
      category: selectedCategory, paymentMethod: selectedPayment, timestamp: combinedDate.millisecondsSinceEpoch,
      linkedEntryId: isEdit ? widget.existingEntry!.linkedEntryId : null,
      customFields: Map<String, dynamic>.from(_customFieldValues),
    );

    Future<void> logChange(String targetEntryId, String field, String oldVal, String newVal) async {
      if (oldVal != newVal) {
        await DatabaseHelper.instance.insertEditLog(EditLog(
          id: 'LOG-${Random().nextInt(999999)}', entryId: targetEntryId, field: field, 
          oldValue: oldVal.isEmpty ? 'Empty' : oldVal, newValue: newVal.isEmpty ? 'Empty' : newVal, 
          timestamp: DateTime.now().millisecondsSinceEpoch
        ));
      }
    }

    if (isEdit) {
      final old = widget.existingEntry!;
      widget.book.balance -= (old.type == 'in' ? old.amount : -old.amount);
      
      final oldDateObj = DateTime.fromMillisecondsSinceEpoch(old.timestamp);
      await logChange(old.id, 'Date', _formatDate(oldDateObj), _formatDate(combinedDate));
      await logChange(old.id, 'Time', _formatTime(TimeOfDay.fromDateTime(oldDateObj)), _formatTime(_selectedTime));
      await logChange(old.id, 'Amount', old.amount.toString(), amount.toString());
      await logChange(old.id, 'Type', old.type.toUpperCase(), typeStr.toUpperCase());
      await logChange(old.id, 'Category', old.category, selectedCategory);
      await logChange(old.id, 'Payment Method', old.paymentMethod, selectedPayment);
      await logChange(old.id, 'Remark', old.note, _remarkCtrl.text.trim());
      
      Map<String, dynamic> oldCF = {};
      if (old.customFields.isNotEmpty) { try { oldCF = old.customFields; } catch(_) {} }
      for (var cf in _customFieldsData) {
        await logChange(old.id, cf.name, oldCF[cf.id]?.toString() ?? '', _customFieldValues[cf.id] ?? ''); 
      }

      await DatabaseHelper.instance.updateEntry(entry);
      widget.book.balance += (typeStr == 'in' ? amount : -amount);
      await DatabaseHelper.instance.updateBook(widget.book);

      Entry? existingLinked = await DatabaseHelper.instance.getLinkedEntry(old.id);
      
      if (existingLinked != null) {
        final lb = await DatabaseHelper.instance.getBookById(existingLinked.bookId);
        if (lb != null) {
          lb.balance -= (existingLinked.type == 'in' ? existingLinked.amount : -existingLinked.amount);
          
          if (_selectedLinkedBook == null || _selectedLinkedBook!.id != existingLinked.bookId) {
            await DatabaseHelper.instance.updateBook(lb);
            await DatabaseHelper.instance.deleteEntry(existingLinked.id);
          } else {
            String oldLinkedType = existingLinked.type;
            String newLinkedType = typeStr == 'in' ? 'out' : 'in'; 

            await logChange(existingLinked.id, 'Date', _formatDate(oldDateObj), _formatDate(combinedDate));
            await logChange(existingLinked.id, 'Time', _formatTime(TimeOfDay.fromDateTime(oldDateObj)), _formatTime(_selectedTime));
            await logChange(existingLinked.id, 'Amount', existingLinked.amount.toString(), amount.toString());
            await logChange(existingLinked.id, 'Type', oldLinkedType.toUpperCase(), newLinkedType.toUpperCase()); 
            await logChange(existingLinked.id, 'Category', existingLinked.category, selectedCategory);
            await logChange(existingLinked.id, 'Payment Method', existingLinked.paymentMethod, selectedPayment);
            await logChange(existingLinked.id, 'Remark', existingLinked.note, _remarkCtrl.text.trim());

            existingLinked.amount = amount;
            existingLinked.type = newLinkedType; 
            existingLinked.category = selectedCategory;
            existingLinked.paymentMethod = selectedPayment;
            existingLinked.note = _remarkCtrl.text.trim();
            existingLinked.timestamp = combinedDate.millisecondsSinceEpoch;
            existingLinked.customFields = entry.customFields;
            
            await DatabaseHelper.instance.updateEntry(existingLinked);
            lb.balance += (newLinkedType == 'in' ? amount : -amount);
            await DatabaseHelper.instance.updateBook(lb);
          }
        }
      }

      if (_selectedLinkedBook != null && (existingLinked == null || existingLinked.bookId != _selectedLinkedBook!.id)) {
        final subEntry = Entry(
          id: 'ENT-${Random().nextInt(999999)}', bookId: _selectedLinkedBook!.id, type: typeStr == 'in' ? 'out' : 'in',
          amount: amount, note: _remarkCtrl.text.trim(), category: selectedCategory, paymentMethod: selectedPayment,
          timestamp: combinedDate.millisecondsSinceEpoch, linkedEntryId: entry.id, customFields: entry.customFields,
        );
        await DatabaseHelper.instance.insertEntry(subEntry);
        _selectedLinkedBook!.balance += (subEntry.type == 'in' ? amount : -amount);
        await DatabaseHelper.instance.updateBook(_selectedLinkedBook!);
      }

    } else {
      await DatabaseHelper.instance.insertEntry(entry);
      widget.book.balance += (typeStr == 'in' ? amount : -amount);
      await DatabaseHelper.instance.updateBook(widget.book);
      
      if (_selectedLinkedBook != null) {
        final subEntry = Entry(
          id: 'ENT-${Random().nextInt(999999)}', bookId: _selectedLinkedBook!.id, type: typeStr == 'in' ? 'out' : 'in', 
          amount: amount, note: _remarkCtrl.text.trim(), category: selectedCategory, paymentMethod: selectedPayment,
          timestamp: combinedDate.millisecondsSinceEpoch, linkedEntryId: entry.id, customFields: entry.customFields,
        );
        await DatabaseHelper.instance.insertEntry(subEntry);
        _selectedLinkedBook!.balance += (subEntry.type == 'in' ? amount : -amount);
        await DatabaseHelper.instance.updateBook(_selectedLinkedBook!);
      }
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
            isExpanded: true, value: opts.contains(val) ? val : null, hint: const Text('Select option', style: TextStyle(color: textMuted)),
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
            isExpanded: true, icon: const Icon(Icons.contact_page, color: textMuted), value: contacts.contains(val) ? val : null,
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
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [Text(isEdit ? 'Edit Entry' : 'Add Entry', style: const TextStyle(fontSize: 18)), Text(widget.book.name, style: const TextStyle(fontSize: 12, color: textMuted, fontWeight: FontWeight.normal))],
        ),
        actions: [
          TextButton.icon(
            onPressed: _handleLinkButton,
            icon: Icon(Icons.link, color: _selectedLinkedBook != null ? accent : textMuted),
            label: Text(_selectedLinkedBook != null ? _selectedLinkedBook!.name : 'Link', style: TextStyle(color: _selectedLinkedBook != null ? accent : textMuted, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
        ],
      ),
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
