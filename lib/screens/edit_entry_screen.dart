// UI ONLY — Edit Entry Screen

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/cashbook.dart';
import '../models/transaction.dart';
import '../logic/cashbook_logic.dart';

class EditEntryScreen extends StatefulWidget {
  final CashBook cashbook;
  final Transaction transaction;

  const EditEntryScreen({
    super.key,
    required this.cashbook,
    required this.transaction,
  });

  @override
  State<EditEntryScreen> createState() => _EditEntryScreenState();
}

class _EditEntryScreenState extends State<EditEntryScreen> {
  late EntryType _entryType;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late String? _selectedCategory;
  late String? _selectedPaymentMethod;
  late List<String> _activeCategories;
  late List<String> _activePaymentMethods;

  final _amountController = TextEditingController();
  final _remarksController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final tx = widget.transaction;
    _entryType = tx.entryType;
    _selectedDate = tx.dateTime;
    _selectedTime = TimeOfDay(hour: tx.dateTime.hour, minute: tx.dateTime.minute);
    _activeCategories = List<String>.from(widget.cashbook.allCategories);
    _activePaymentMethods = List<String>.from(widget.cashbook.allPaymentMethods);
    _amountController.text = tx.amount.toStringAsFixed(2);
    _remarksController.text = tx.remarks ?? '';
    _selectedCategory = _activeCategories.contains(tx.category)
        ? tx.category
        : _activeCategories.first;
    _selectedPaymentMethod = _activePaymentMethods.contains(tx.paymentMethod)
        ? tx.paymentMethod
        : _activePaymentMethods.first;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_saving) return;
    setState(() => _saving = true);

    final dateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    await CashbookLogic.editTransaction(
      original: widget.transaction,
      entryType: _entryType,
      amount: double.parse(_amountController.text),
      dateTime: dateTime,
      category: _selectedCategory ?? _activeCategories.first,
      paymentMethod: _selectedPaymentMethod ?? _activePaymentMethods.first,
      remarks: _remarksController.text.trim().isEmpty
          ? null
          : _remarksController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _saving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Entry updated!'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
    Navigator.pop(context, true); // Return true to signal a change
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isCashIn = _entryType == EntryType.cashIn;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        scrolledUnderElevation: 2,
        title: const Text(
          'Edit Entry',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
          children: [
            // Edit notice banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: colorScheme.tertiaryContainer.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: colorScheme.tertiary.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.history_rounded,
                      size: 16, color: colorScheme.tertiary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Changes will be recorded in edit history',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onTertiaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            _EntryTypeToggle(
              selectedType: _entryType,
              onChanged: (t) => setState(() => _entryType = t),
            ),
            const SizedBox(height: 22),

            _FieldLabel(label: 'Amount'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))
              ],
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: isCashIn
                        ? const Color(0xFF1B8A3A)
                        : colorScheme.error,
                    letterSpacing: -0.5,
                  ),
              decoration: InputDecoration(
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 18, right: 8, top: 4),
                  child: Text('₹',
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(
                            color: colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.5),
                            fontWeight: FontWeight.w300,
                          )),
                ),
                prefixIconConstraints: const BoxConstraints(minWidth: 0),
                hintText: '0.00',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: colorScheme.outlineVariant),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: colorScheme.primary, width: 2),
                ),
                filled: true,
                fillColor: colorScheme.surfaceContainerLow,
                contentPadding: const EdgeInsets.fromLTRB(0, 18, 18, 18),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Please enter an amount';
                final n = double.tryParse(v);
                if (n == null || n <= 0) return 'Enter a valid amount greater than 0';
                return null;
              },
            ),
            const SizedBox(height: 22),

            _FieldLabel(label: 'Date & Time'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _TapTile(
                    icon: Icons.calendar_today_outlined,
                    value: _formatDate(_selectedDate),
                    onTap: _pickDate,
                    colorScheme: colorScheme,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _TapTile(
                    icon: Icons.access_time_outlined,
                    value: _selectedTime.format(context),
                    onTap: _pickTime,
                    colorScheme: colorScheme,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),

            _FieldLabel(label: 'Remarks', optional: true),
            const SizedBox(height: 8),
            TextFormField(
              controller: _remarksController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Add a note about this entry...',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: colorScheme.outlineVariant),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: colorScheme.primary, width: 2),
                ),
                filled: true,
                fillColor: colorScheme.surfaceContainerLow,
              ),
            ),
            const SizedBox(height: 22),

            _FieldLabel(label: 'Category'),
            const SizedBox(height: 8),
            _ChipSelector(
              options: _activeCategories,
              selected: _selectedCategory,
              onSelected: (v) => setState(() => _selectedCategory = v),
              colorScheme: colorScheme,
            ),
            const SizedBox(height: 22),

            _FieldLabel(label: 'Payment Method'),
            const SizedBox(height: 8),
            _ChipSelector(
              options: _activePaymentMethods,
              selected: _selectedPaymentMethod,
              onSelected: (v) => setState(() => _selectedPaymentMethod = v),
              colorScheme: colorScheme,
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(
            16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
        ),
        child: FilledButton.icon(
          icon: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.check_rounded, size: 18),
          label: const Text('Save Changes',
              style: TextStyle(fontWeight: FontWeight.w700)),
          style: FilledButton.styleFrom(
            backgroundColor:
                isCashIn ? const Color(0xFF1B8A3A) : colorScheme.error,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
          onPressed: _saving ? null : _save,
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const m = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${dt.day} ${m[dt.month - 1]} ${dt.year}';
  }

  @override
  void dispose() {
    _amountController.dispose();
    _remarksController.dispose();
    super.dispose();
  }
}

// ── Shared sub-widgets ────────────────────────────────────────────────────

class _EntryTypeToggle extends StatelessWidget {
  final EntryType selectedType;
  final void Function(EntryType) onChanged;
  const _EntryTypeToggle({required this.selectedType, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.all(5),
      child: Row(
        children: [
          _Tab(
            label: 'Cash In',
            icon: Icons.arrow_downward_rounded,
            isSelected: selectedType == EntryType.cashIn,
            selectedColor: const Color(0xFF1B8A3A),
            selectedBg: const Color(0xFFE8F5E9),
            onTap: () => onChanged(EntryType.cashIn),
          ),
          _Tab(
            label: 'Cash Out',
            icon: Icons.arrow_upward_rounded,
            isSelected: selectedType == EntryType.cashOut,
            selectedColor: colorScheme.error,
            selectedBg: colorScheme.errorContainer,
            onTap: () => onChanged(EntryType.cashOut),
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color selectedColor;
  final Color selectedBg;
  final VoidCallback onTap;

  const _Tab({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.selectedColor,
    required this.selectedBg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            color: isSelected ? selectedBg : Colors.transparent,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 18,
                  color: isSelected
                      ? selectedColor
                      : Theme.of(context).colorScheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Text(label,
                  style: TextStyle(
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? selectedColor
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  final bool optional;
  const _FieldLabel({required this.label, this.optional = false});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Text(label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                )),
        if (optional) ...[
          const SizedBox(width: 6),
          Text('optional',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  )),
        ],
      ],
    );
  }
}

class _TapTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final VoidCallback onTap;
  final ColorScheme colorScheme;

  const _TapTile(
      {required this.icon,
      required this.value,
      required this.onTap,
      required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          border: Border.all(color: colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: colorScheme.primary),
            const SizedBox(width: 9),
            Expanded(
              child: Text(value,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChipSelector extends StatelessWidget {
  final List<String> options;
  final String? selected;
  final void Function(String) onSelected;
  final ColorScheme colorScheme;

  const _ChipSelector({
    required this.options,
    required this.selected,
    required this.onSelected,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map(
        (opt) => ChoiceChip(
          label: Text(opt),
          selected: selected == opt,
          onSelected: (_) => onSelected(opt),
          selectedColor: colorScheme.primaryContainer,
          checkmarkColor: colorScheme.onPrimaryContainer,
          labelStyle: TextStyle(
            color: selected == opt
                ? colorScheme.onPrimaryContainer
                : colorScheme.onSurface,
            fontWeight:
                selected == opt ? FontWeight.w700 : FontWeight.normal,
          ),
          side: BorderSide(
            color: selected == opt
                ? colorScheme.primary.withValues(alpha: 0.4)
                : colorScheme.outlineVariant,
          ),
        ),
      ).toList(),
    );
  }
}
