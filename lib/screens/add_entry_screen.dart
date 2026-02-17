// UI ONLY

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/cashbook.dart';
import '../models/transaction.dart';

class AddEntryScreen extends StatefulWidget {
  final CashBook cashbook;
  final EntryType initialEntryType;

  const AddEntryScreen({
    super.key,
    required this.cashbook,
    required this.initialEntryType,
  });

  @override
  State<AddEntryScreen> createState() => _AddEntryScreenState();
}

class _AddEntryScreenState extends State<AddEntryScreen> {
  late EntryType _entryType;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  String? _selectedCategory;
  String? _selectedPaymentMethod;

  final _amountController = TextEditingController();
  final _remarksController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _entryType = widget.initialEntryType;
    _selectedDate = DateTime.now();
    _selectedTime = TimeOfDay.now();
    _selectedCategory = widget.cashbook.allCategories.first;
    _selectedPaymentMethod = widget.cashbook.allPaymentMethods.first;
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

  void _save({bool addNew = false}) {
    if (!_formKey.currentState!.validate()) return;

    // TODO: Logic layer — CashbookLogic.addTransaction(...)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            '${_entryType == EntryType.cashIn ? 'Cash In' : 'Cash Out'} of ₹${_amountController.text} saved!'),
        behavior: SnackBarBehavior.floating,
      ),
    );

    if (addNew) {
      _amountController.clear();
      _remarksController.clear();
      setState(() {
        _selectedCategory = widget.cashbook.allCategories.first;
        _selectedPaymentMethod = widget.cashbook.allPaymentMethods.first;
        _selectedDate = DateTime.now();
        _selectedTime = TimeOfDay.now();
      });
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isCashIn = _entryType == EntryType.cashIn;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(isCashIn ? 'Add Cash In' : 'Add Cash Out'),
        centerTitle: false,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
          children: [
            // Entry Type Toggle
            _EntryTypeToggle(
              selectedType: _entryType,
              onChanged: (type) => setState(() => _entryType = type),
            ),
            const SizedBox(height: 20),

            // Amount Field
            _SectionLabel(label: 'Amount'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))
              ],
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isCashIn
                        ? const Color(0xFF1B8A3A)
                        : colorScheme.error,
                  ),
              decoration: InputDecoration(
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 16, right: 8),
                  child: Text(
                    '₹',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w300,
                        ),
                  ),
                ),
                prefixIconConstraints: const BoxConstraints(minWidth: 0),
                hintText: '0.00',
                hintStyle: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant.withOpacity(0.4),
                      fontWeight: FontWeight.bold,
                    ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                filled: true,
                fillColor: colorScheme.surfaceContainerLow,
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Enter an amount';
                if (double.tryParse(v) == null || double.parse(v) <= 0) {
                  return 'Enter a valid amount';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Date & Time Row
            _SectionLabel(label: 'Date & Time'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _PickerTile(
                    icon: Icons.calendar_today_outlined,
                    value: _formatDate(_selectedDate),
                    onTap: _pickDate,
                    colorScheme: colorScheme,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _PickerTile(
                    icon: Icons.access_time_outlined,
                    value: _selectedTime.format(context),
                    onTap: _pickTime,
                    colorScheme: colorScheme,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Remarks
            _SectionLabel(label: 'Remarks (Optional)'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _remarksController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Add a note...',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                filled: true,
                fillColor: colorScheme.surfaceContainerLow,
              ),
            ),
            const SizedBox(height: 20),

            // Category
            _SectionLabel(label: 'Category'),
            const SizedBox(height: 8),
            _OptionSelector(
              options: widget.cashbook.allCategories,
              selected: _selectedCategory!,
              onSelected: (v) => setState(() => _selectedCategory = v),
              onManage: () => _showManageOptions(
                context,
                title: 'Manage Categories',
                options: widget.cashbook.customCategories,
                defaultOptions: widget.cashbook.allCategories
                    .take(10)
                    .toList(),
              ),
              colorScheme: colorScheme,
            ),
            const SizedBox(height: 20),

            // Payment Method
            _SectionLabel(label: 'Payment Method'),
            const SizedBox(height: 8),
            _OptionSelector(
              options: widget.cashbook.allPaymentMethods,
              selected: _selectedPaymentMethod!,
              onSelected: (v) => setState(() => _selectedPaymentMethod = v),
              onManage: () => _showManageOptions(
                context,
                title: 'Manage Payment Methods',
                options: widget.cashbook.customPaymentMethods,
                defaultOptions:
                    widget.cashbook.allPaymentMethods.take(6).toList(),
              ),
              colorScheme: colorScheme,
            ),
          ],
        ),
      ),
      bottomNavigationBar: _SaveButtonBar(
        onSave: () => _save(),
        onSaveAndAddNew: () => _save(addNew: true),
        isCashIn: isCashIn,
        colorScheme: colorScheme,
      ),
    );
  }

  void _showManageOptions(
    BuildContext context, {
    required String title,
    required List<String> options,
    required List<String> defaultOptions,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _ManageOptionsScreen(
          title: title,
          customOptions: options,
          defaultOptions: defaultOptions,
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  @override
  void dispose() {
    _amountController.dispose();
    _remarksController.dispose();
    super.dispose();
  }
}

// --- Sub-widgets ---

class _EntryTypeToggle extends StatelessWidget {
  final EntryType selectedType;
  final void Function(EntryType) onChanged;

  const _EntryTypeToggle({
    required this.selectedType,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _ToggleOption(
            label: 'Cash In',
            icon: Icons.arrow_downward_rounded,
            isSelected: selectedType == EntryType.cashIn,
            selectedColor: const Color(0xFF1B8A3A),
            selectedBg: const Color(0xFFE8F5E9),
            onTap: () => onChanged(EntryType.cashIn),
          ),
          _ToggleOption(
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

class _ToggleOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color selectedColor;
  final Color selectedBg;
  final VoidCallback onTap;

  const _ToggleOption({
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
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? selectedBg : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
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
              Text(
                label,
                style: TextStyle(
                  fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? selectedColor
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
    );
  }
}

class _PickerTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final VoidCallback onTap;
  final ColorScheme colorScheme;

  const _PickerTile({
    required this.icon,
    required this.value,
    required this.onTap,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          border: Border.all(color: colorScheme.outline.withOpacity(0.5)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionSelector extends StatelessWidget {
  final List<String> options;
  final String selected;
  final void Function(String) onSelected;
  final VoidCallback onManage;
  final ColorScheme colorScheme;

  const _OptionSelector({
    required this.options,
    required this.selected,
    required this.onSelected,
    required this.onManage,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ...options.map(
          (opt) => ChoiceChip(
            label: Text(opt),
            selected: selected == opt,
            onSelected: (_) => onSelected(opt),
            selectedColor: colorScheme.primaryContainer,
            labelStyle: TextStyle(
              color: selected == opt
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onSurface,
              fontWeight: selected == opt ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
        ActionChip(
          avatar: const Icon(Icons.add, size: 16),
          label: const Text('Manage'),
          onPressed: onManage,
        ),
      ],
    );
  }
}

class _SaveButtonBar extends StatelessWidget {
  final VoidCallback onSave;
  final VoidCallback onSaveAndAddNew;
  final bool isCashIn;
  final ColorScheme colorScheme;

  const _SaveButtonBar({
    required this.onSave,
    required this.onSaveAndAddNew,
    required this.isCashIn,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Save & Add New'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: onSaveAndAddNew,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton.icon(
              icon: const Icon(Icons.check),
              label: const Text('Save'),
              style: FilledButton.styleFrom(
                backgroundColor:
                    isCashIn ? const Color(0xFF1B8A3A) : colorScheme.error,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: onSave,
            ),
          ),
        ],
      ),
    );
  }
}

// --- Manage Options Screen (inside same file as it's a sub-screen) ---

class _ManageOptionsScreen extends StatefulWidget {
  final String title;
  final List<String> customOptions;
  final List<String> defaultOptions;

  const _ManageOptionsScreen({
    required this.title,
    required this.customOptions,
    required this.defaultOptions,
  });

  @override
  State<_ManageOptionsScreen> createState() => _ManageOptionsScreenState();
}

class _ManageOptionsScreenState extends State<_ManageOptionsScreen> {
  late List<String> _custom;
  final _addController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _custom = List<String>.from(widget.customOptions);
  }

  void _addOption() {
    final value = _addController.text.trim();
    if (value.isEmpty) return;
    if (_custom.contains(value) || widget.defaultOptions.contains(value)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Option already exists')),
      );
      return;
    }
    setState(() => _custom.add(value));
    _addController.clear();
    // TODO: Persist via CashbookLogic.updateCashbookOptions(...)
  }

  void _deleteCustomOption(String option) {
    setState(() => _custom.remove(option));
    // TODO: Persist via CashbookLogic.updateCashbookOptions(...)
  }

  void _resetToDefaults() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reset to Defaults?'),
        content: const Text(
            'All custom options will be removed. Default options will remain.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _custom.clear());
              // TODO: Persist
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('Reset'),
            onPressed: _resetToDefaults,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Add new option
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _addController,
                  decoration: InputDecoration(
                    hintText: 'Add custom option...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: colorScheme.surfaceContainerLow,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                  onSubmitted: (_) => _addOption(),
                ),
              ),
              const SizedBox(width: 10),
              FilledButton(
                onPressed: _addOption,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Icon(Icons.add),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Default options (read-only)
          Text('Default Options',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  )),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.defaultOptions
                .map(
                  (opt) => Chip(
                    label: Text(opt),
                    backgroundColor: colorScheme.surfaceContainerHighest,
                  ),
                )
                .toList(),
          ),

          if (_custom.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text('Custom Options',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    )),
            const SizedBox(height: 8),
            ..._custom.map(
              (opt) => Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side:
                      BorderSide(color: colorScheme.outlineVariant),
                ),
                child: ListTile(
                  title: Text(opt),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => _showRenameDialog(opt),
                        visualDensity: VisualDensity.compact,
                      ),
                      IconButton(
                        icon: Icon(Icons.delete_outline,
                            color: colorScheme.error),
                        onPressed: () => _deleteCustomOption(opt),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showRenameDialog(String current) {
    final controller = TextEditingController(text: current);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Rename Option'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final newVal = controller.text.trim();
              if (newVal.isNotEmpty && newVal != current) {
                setState(() {
                  final idx = _custom.indexOf(current);
                  if (idx != -1) _custom[idx] = newVal;
                });
                // TODO: Persist
              }
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _addController.dispose();
    super.dispose();
  }
}
