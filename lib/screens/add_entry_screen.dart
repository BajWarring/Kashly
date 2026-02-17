// UI ONLY — Add Entry Screen (original, unchanged)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/cashbook.dart';
import '../models/transaction.dart';
import '../logic/cashbook_logic.dart';

class AddEntryScreen extends StatefulWidget {
  final CashBook cashbook;
  final EntryType initialEntryType;
  const AddEntryScreen({super.key, required this.cashbook, required this.initialEntryType});
  @override
  State<AddEntryScreen> createState() => _AddEntryScreenState();
}

class _AddEntryScreenState extends State<AddEntryScreen> {
  late EntryType _entryType;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  String? _selectedCategory;
  String? _selectedPaymentMethod;
  late List<String> _activeCategories;
  late List<String> _activePaymentMethods;
  final List<String> _defaultCategories = const ['General','Food & Drinks','Transport','Salary','Business','Bills & Utilities','Shopping','Entertainment','Healthcare','Investment'];
  final List<String> _defaultPaymentMethods = const ['Cash','Bank Transfer','UPI','Card','Cheque','Other'];
  final _amountController = TextEditingController();
  final _remarksController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _entryType = widget.initialEntryType;
    _selectedDate = DateTime.now();
    _selectedTime = TimeOfDay.now();
    _activeCategories = List<String>.from(widget.cashbook.allCategories);
    _activePaymentMethods = List<String>.from(widget.cashbook.allPaymentMethods);
    _selectedCategory = _activeCategories.first;
    _selectedPaymentMethod = _activePaymentMethods.first;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime(2000), lastDate: DateTime(2100));
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _selectedTime);
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _save({bool addNew = false}) async {
    if (!_formKey.currentState!.validate()) return;
    if (_saving) return;
    setState(() => _saving = true);
    final dateTime = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, _selectedTime.hour, _selectedTime.minute);
    await CashbookLogic.addTransaction(
      cashbookId: widget.cashbook.id, entryType: _entryType,
      amount: double.parse(_amountController.text), dateTime: dateTime,
      category: _selectedCategory ?? _activeCategories.first,
      paymentMethod: _selectedPaymentMethod ?? _activePaymentMethods.first,
      remarks: _remarksController.text.trim().isEmpty ? null : _remarksController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('${_entryType == EntryType.cashIn ? 'Cash In' : 'Cash Out'} ₹${_amountController.text} saved!'),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
    if (addNew) {
      _amountController.clear(); _remarksController.clear();
      setState(() { _selectedDate = DateTime.now(); _selectedTime = TimeOfDay.now(); _selectedCategory = _activeCategories.isNotEmpty ? _activeCategories.first : null; _selectedPaymentMethod = _activePaymentMethods.isNotEmpty ? _activePaymentMethods.first : null; });
    } else { Navigator.pop(context); }
  }

  void _manageOptions({required bool isCategory}) {
    showModalBottomSheet(context: context, isScrollControlled: true, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => DraggableScrollableSheet(initialChildSize: 0.75, maxChildSize: 0.95, minChildSize: 0.4, expand: false, builder: (context, scrollController) {
        return _ManageOptionsSheet(
          title: isCategory ? 'Manage Categories' : 'Manage Payment Methods',
          defaultOptions: isCategory ? _defaultCategories : _defaultPaymentMethods,
          activeOptions: isCategory ? _activeCategories : _activePaymentMethods,
          customOptions: isCategory ? widget.cashbook.customCategories : widget.cashbook.customPaymentMethods,
          scrollController: scrollController,
          onChanged: (updated) => setState(() {
            if (isCategory) { _activeCategories = updated; if (!updated.contains(_selectedCategory)) _selectedCategory = updated.isNotEmpty ? updated.first : null; }
            else { _activePaymentMethods = updated; if (!updated.contains(_selectedPaymentMethod)) _selectedPaymentMethod = updated.isNotEmpty ? updated.first : null; }
          }),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isCashIn = _entryType == EntryType.cashIn;
    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(scrolledUnderElevation: 2, title: Text(isCashIn ? 'Add Cash In' : 'Add Cash Out', style: const TextStyle(fontWeight: FontWeight.w600))),
      body: Form(key: _formKey, child: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 120), children: [
        _EntryTypeToggle(selectedType: _entryType, onChanged: (t) => setState(() => _entryType = t)),
        const SizedBox(height: 22),
        _FieldLabel(label: 'Amount'),
        const SizedBox(height: 8),
        TextFormField(controller: _amountController, keyboardType: const TextInputType.numberWithOptions(decimal: true), inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800, color: isCashIn ? const Color(0xFF1B8A3A) : cs.error, letterSpacing: -0.5),
          decoration: InputDecoration(prefixIcon: Padding(padding: const EdgeInsets.only(left: 18, right: 8, top: 4), child: Text('₹', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: cs.onSurfaceVariant.withValues(alpha: 0.5), fontWeight: FontWeight.w300))),
            prefixIconConstraints: const BoxConstraints(minWidth: 0), hintText: '0.00',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: cs.outlineVariant)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: cs.primary, width: 2)),
            filled: true, fillColor: cs.surfaceContainerLow, contentPadding: const EdgeInsets.fromLTRB(0, 18, 18, 18)),
          validator: (v) { if (v == null || v.isEmpty) return 'Please enter an amount'; final n = double.tryParse(v); if (n == null || n <= 0) return 'Enter a valid amount greater than 0'; return null; }),
        const SizedBox(height: 22),
        _FieldLabel(label: 'Date & Time'),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: _TapTile(icon: Icons.calendar_today_outlined, value: _formatDate(_selectedDate), onTap: _pickDate, cs: cs)),
          const SizedBox(width: 10),
          Expanded(child: _TapTile(icon: Icons.access_time_outlined, value: _selectedTime.format(context), onTap: _pickTime, cs: cs)),
        ]),
        const SizedBox(height: 22),
        _FieldLabel(label: 'Remarks', optional: true),
        const SizedBox(height: 8),
        TextFormField(controller: _remarksController, maxLines: 2, decoration: InputDecoration(hintText: 'Add a note about this entry...', border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: cs.outlineVariant)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: cs.primary, width: 2)), filled: true, fillColor: cs.surfaceContainerLow)),
        const SizedBox(height: 22),
        _FieldLabel(label: 'Category'),
        const SizedBox(height: 8),
        _ChipSelector(options: _activeCategories, selected: _selectedCategory, onSelected: (v) => setState(() => _selectedCategory = v), onManage: () => _manageOptions(isCategory: true), cs: cs),
        const SizedBox(height: 22),
        _FieldLabel(label: 'Payment Method'),
        const SizedBox(height: 8),
        _ChipSelector(options: _activePaymentMethods, selected: _selectedPaymentMethod, onSelected: (v) => setState(() => _selectedPaymentMethod = v), onManage: () => _manageOptions(isCategory: false), cs: cs),
      ])),
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
        decoration: BoxDecoration(color: cs.surface, border: Border(top: BorderSide(color: cs.outlineVariant))),
        child: Row(children: [
          Expanded(child: OutlinedButton.icon(icon: const Icon(Icons.add_rounded, size: 18), label: const Text('Save & Add New'), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))), onPressed: _saving ? null : () => _save(addNew: true))),
          const SizedBox(width: 12),
          Expanded(child: FilledButton.icon(icon: _saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.check_rounded, size: 18), label: const Text('Save', style: TextStyle(fontWeight: FontWeight.w700)), style: FilledButton.styleFrom(backgroundColor: isCashIn ? const Color(0xFF1B8A3A) : cs.error, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))), onPressed: _saving ? null : () => _save())),
        ]),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${dt.day} ${m[dt.month - 1]} ${dt.year}';
  }

  @override
  void dispose() { _amountController.dispose(); _remarksController.dispose(); super.dispose(); }
}

// ── Shared sub-widgets ────────────────────────────────────────────────────

class _EntryTypeToggle extends StatelessWidget {
  final EntryType selectedType;
  final void Function(EntryType) onChanged;
  const _EntryTypeToggle({required this.selectedType, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(decoration: BoxDecoration(color: cs.surfaceContainerHighest, borderRadius: BorderRadius.circular(18)), padding: const EdgeInsets.all(5), child: Row(children: [
      _Tab(label: 'Cash In', icon: Icons.arrow_downward_rounded, isSelected: selectedType == EntryType.cashIn, selColor: const Color(0xFF1B8A3A), selBg: const Color(0xFFE8F5E9), onTap: () => onChanged(EntryType.cashIn)),
      _Tab(label: 'Cash Out', icon: Icons.arrow_upward_rounded, isSelected: selectedType == EntryType.cashOut, selColor: cs.error, selBg: cs.errorContainer, onTap: () => onChanged(EntryType.cashOut)),
    ]));
  }
}

class _Tab extends StatelessWidget {
  final String label; final IconData icon; final bool isSelected; final Color selColor; final Color selBg; final VoidCallback onTap;
  const _Tab({required this.label, required this.icon, required this.isSelected, required this.selColor, required this.selBg, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Expanded(child: GestureDetector(onTap: onTap, child: AnimatedContainer(duration: const Duration(milliseconds: 200), curve: Curves.easeInOut, padding: const EdgeInsets.symmetric(vertical: 13), decoration: BoxDecoration(color: isSelected ? selBg : Colors.transparent, borderRadius: BorderRadius.circular(13)), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, size: 18, color: isSelected ? selColor : Theme.of(context).colorScheme.onSurfaceVariant), const SizedBox(width: 8), Text(label, style: TextStyle(fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500, color: isSelected ? selColor : Theme.of(context).colorScheme.onSurfaceVariant))]))));
  }
}

class _FieldLabel extends StatelessWidget {
  final String label; final bool optional;
  const _FieldLabel({required this.label, this.optional = false});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(children: [Text(label, style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700, color: cs.onSurface)), if (optional) ...[const SizedBox(width: 6), Text('optional', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant))]]);
  }
}

class _TapTile extends StatelessWidget {
  final IconData icon; final String value; final VoidCallback onTap; final ColorScheme cs;
  const _TapTile({required this.icon, required this.value, required this.onTap, required this.cs});
  @override
  Widget build(BuildContext context) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(16), child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15), decoration: BoxDecoration(color: cs.surfaceContainerLow, border: Border.all(color: cs.outlineVariant), borderRadius: BorderRadius.circular(16)), child: Row(children: [Icon(icon, size: 18, color: cs.primary), const SizedBox(width: 9), Expanded(child: Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis))])));
}

class _ChipSelector extends StatelessWidget {
  final List<String> options; final String? selected; final void Function(String) onSelected; final VoidCallback onManage; final ColorScheme cs;
  const _ChipSelector({required this.options, required this.selected, required this.onSelected, required this.onManage, required this.cs});
  @override
  Widget build(BuildContext context) => Wrap(spacing: 8, runSpacing: 8, children: [
    ...options.map((opt) => ChoiceChip(label: Text(opt), selected: selected == opt, onSelected: (_) => onSelected(opt), selectedColor: cs.primaryContainer, checkmarkColor: cs.onPrimaryContainer, labelStyle: TextStyle(color: selected == opt ? cs.onPrimaryContainer : cs.onSurface, fontWeight: selected == opt ? FontWeight.w700 : FontWeight.normal), side: BorderSide(color: selected == opt ? cs.primary.withValues(alpha: 0.4) : cs.outlineVariant))),
    ActionChip(avatar: Icon(Icons.tune_rounded, size: 15, color: cs.primary), label: const Text('Manage'), onPressed: onManage, side: BorderSide(color: cs.outlineVariant)),
  ]);
}

class _ManageOptionsSheet extends StatefulWidget {
  final String title; final List<String> defaultOptions; final List<String> activeOptions; final List<String> customOptions; final ScrollController scrollController; final void Function(List<String>) onChanged;
  const _ManageOptionsSheet({required this.title, required this.defaultOptions, required this.activeOptions, required this.customOptions, required this.scrollController, required this.onChanged});
  @override
  State<_ManageOptionsSheet> createState() => _ManageOptionsSheetState();
}

class _ManageOptionsSheetState extends State<_ManageOptionsSheet> {
  late List<String> _active;
  late List<String> _custom;
  final _addCtrl = TextEditingController();

  @override
  void initState() { super.initState(); _active = List.from(widget.activeOptions); _custom = List.from(widget.customOptions); }

  bool _isActive(String opt) => _active.contains(opt);

  void _toggleDefault(String opt, bool enable) {
    setState(() { if (enable) { if (!_active.contains(opt)) _active.add(opt); } else { _active.remove(opt); } });
  }

  void _addCustom() {
    final v = _addCtrl.text.trim();
    if (v.isEmpty) return;
    if (_active.contains(v) || _custom.contains(v)) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Already exists'))); return; }
    setState(() { _custom.add(v); _active.add(v); });
    _addCtrl.clear();
  }

  void _deleteCustom(String opt) => setState(() { _custom.remove(opt); _active.remove(opt); });

  void _renameCustom(String old) {
    final ctrl = TextEditingController(text: old);
    showDialog(context: context, builder: (_) => AlertDialog(title: const Text('Rename'), content: TextField(controller: ctrl, autofocus: true, decoration: const InputDecoration(border: OutlineInputBorder())), actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
      FilledButton(onPressed: () { final nv = ctrl.text.trim(); if (nv.isNotEmpty && nv != old) setState(() { final ci = _custom.indexOf(old); if (ci != -1) _custom[ci] = nv; final ai = _active.indexOf(old); if (ai != -1) _active[ai] = nv; }); Navigator.pop(context); }, child: const Text('Save')),
    ]));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(children: [
      Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 0), child: Column(children: [
        Container(width: 32, height: 4, decoration: BoxDecoration(color: cs.onSurfaceVariant.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 14),
        Row(children: [Text(widget.title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)), const Spacer()]),
      ])),
      Expanded(child: ListView(controller: widget.scrollController, padding: const EdgeInsets.all(16), children: [
        Row(children: [
          Expanded(child: TextField(controller: _addCtrl, onSubmitted: (_) => _addCustom(), decoration: InputDecoration(hintText: 'Add new option...', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), filled: true, fillColor: cs.surfaceContainerLow, contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12)))),
          const SizedBox(width: 10),
          FilledButton(onPressed: _addCustom, style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Icon(Icons.add_rounded)),
        ]),
        const SizedBox(height: 20),
        Text('Default Options', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        ...widget.defaultOptions.map((opt) => Card(elevation: 0, margin: const EdgeInsets.only(bottom: 6), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.6))), child: SwitchListTile(value: _isActive(opt), onChanged: (v) => _toggleDefault(opt, v), title: Text(opt, style: const TextStyle(fontWeight: FontWeight.w500)), secondary: Icon(_isActive(opt) ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20, color: _isActive(opt) ? cs.primary : cs.onSurfaceVariant), dense: true, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))),
        if (_custom.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text('Custom Options', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          ..._custom.map((opt) => Card(elevation: 0, margin: const EdgeInsets.only(bottom: 6), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: cs.primaryContainer)), color: cs.primaryContainer.withValues(alpha: 0.2), child: ListTile(leading: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(8)), child: Icon(Icons.label_outline, size: 16, color: cs.onPrimaryContainer)), title: Text(opt, style: const TextStyle(fontWeight: FontWeight.w600)), trailing: Row(mainAxisSize: MainAxisSize.min, children: [IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => _renameCustom(opt), visualDensity: VisualDensity.compact, iconSize: 20), IconButton(icon: Icon(Icons.delete_outline, color: cs.error), onPressed: () => _deleteCustom(opt), visualDensity: VisualDensity.compact, iconSize: 20)]), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))),
        ],
      ])),
      Padding(padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).padding.bottom + 12), child: FilledButton.icon(icon: const Icon(Icons.check_rounded), label: const Text('Apply', style: TextStyle(fontWeight: FontWeight.w700)), style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))), onPressed: () { widget.onChanged(_active); Navigator.pop(context); })),
    ]);
  }

  @override
  void dispose() { _addCtrl.dispose(); super.dispose(); }
}
