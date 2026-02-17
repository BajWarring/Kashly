// UI ONLY

import 'package:flutter/material.dart';
import '../models/cashbook.dart';
import '../logic/cashbook_logic.dart';

class CashbookOptionsScreen extends StatefulWidget {
  final CashBook cashbook;

  const CashbookOptionsScreen({super.key, required this.cashbook});

  @override
  State<CashbookOptionsScreen> createState() => _CashbookOptionsScreenState();
}

class _CashbookOptionsScreenState extends State<CashbookOptionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late List<String> _customCategories;
  late List<String> _customPaymentMethods;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _customCategories = List.from(widget.cashbook.customCategories);
    _customPaymentMethods = List.from(widget.cashbook.customPaymentMethods);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Options'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Categories'),
            Tab(text: 'Payment Methods'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _OptionsTabUI(
            sectionTitle: 'Categories',
            defaults: const [
              'General', 'Food & Drinks', 'Transport', 'Salary',
              'Business', 'Bills & Utilities', 'Shopping',
              'Entertainment', 'Healthcare', 'Investment',
            ],
            customs: _customCategories,
            onAdd: (v) => setState(() => _customCategories.add(v)),
            onDelete: (v) => setState(() => _customCategories.remove(v)),
            onRename: (old, newVal) => setState(() {
              final idx = _customCategories.indexOf(old);
              if (idx != -1) _customCategories[idx] = newVal;
            }),
            onReset: () => setState(() => _customCategories.clear()),
            colorScheme: colorScheme,
          ),
          _OptionsTabUI(
            sectionTitle: 'Payment Methods',
            defaults: const [
              'Cash', 'Bank Transfer', 'UPI', 'Card', 'Cheque', 'Other',
            ],
            customs: _customPaymentMethods,
            onAdd: (v) => setState(() => _customPaymentMethods.add(v)),
            onDelete: (v) =>
                setState(() => _customPaymentMethods.remove(v)),
            onRename: (old, newVal) => setState(() {
              final idx = _customPaymentMethods.indexOf(old);
              if (idx != -1) _customPaymentMethods[idx] = newVal;
            }),
            onReset: () => setState(() => _customPaymentMethods.clear()),
            colorScheme: colorScheme,
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            icon: const Icon(Icons.save_outlined),
            label: const Text('Save Changes'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: () async {
              await CashbookLogic.updateCashbookOptions(
                cashbookId: widget.cashbook.id,
                customCategories: _customCategories,
                customPaymentMethods: _customPaymentMethods,
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Options saved'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                Navigator.pop(context);
              }
            },
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

class _OptionsTabUI extends StatefulWidget {
  final String sectionTitle;
  final List<String> defaults;
  final List<String> customs;
  final void Function(String) onAdd;
  final void Function(String) onDelete;
  final void Function(String, String) onRename;
  final VoidCallback onReset;
  final ColorScheme colorScheme;

  const _OptionsTabUI({
    required this.sectionTitle,
    required this.defaults,
    required this.customs,
    required this.onAdd,
    required this.onDelete,
    required this.onRename,
    required this.onReset,
    required this.colorScheme,
  });

  @override
  State<_OptionsTabUI> createState() => _OptionsTabUIState();
}

class _OptionsTabUIState extends State<_OptionsTabUI> {
  final _controller = TextEditingController();

  void _addOption() {
    final value = _controller.text.trim();
    if (value.isEmpty) return;
    if (widget.defaults.contains(value) || widget.customs.contains(value)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Option already exists')),
      );
      return;
    }
    widget.onAdd(value);
    _controller.clear();
  }

  void _confirmReset() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Reset ${widget.sectionTitle}?'),
        content: const Text('All custom options will be removed.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onReset();
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _showRenameDialog(String current) {
    final ctrl = TextEditingController(text: current);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Rename'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final v = ctrl.text.trim();
              if (v.isNotEmpty && v != current) widget.onRename(current, v);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText:
                      'New ${widget.sectionTitle.toLowerCase()} option...',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: widget.colorScheme.surfaceContainerLow,
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
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Icon(Icons.add),
            ),
          ],
        ),
        const SizedBox(height: 20),

        Row(
          children: [
            Text('Default Options',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: widget.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    )),
            const Spacer(),
            Text('Read-only',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: widget.colorScheme.onSurfaceVariant,
                    )),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.defaults
              .map((opt) => Chip(
                    label: Text(opt),
                    backgroundColor:
                        widget.colorScheme.surfaceContainerHighest,
                    avatar: Icon(Icons.lock_outline,
                        size: 14,
                        color: widget.colorScheme.onSurfaceVariant),
                  ))
              .toList(),
        ),

        const SizedBox(height: 20),

        Row(
          children: [
            Text('Custom Options',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: widget.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    )),
            const Spacer(),
            if (widget.customs.isNotEmpty)
              TextButton.icon(
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Reset Custom'),
                onPressed: _confirmReset,
                style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact),
              ),
          ],
        ),
        const SizedBox(height: 8),

        if (widget.customs.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: widget.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: widget.colorScheme.outlineVariant),
            ),
            child: Column(
              children: [
                Icon(Icons.add_circle_outline,
                    size: 32,
                    color: widget.colorScheme.onSurfaceVariant),
                const SizedBox(height: 8),
                Text('No custom options yet',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: widget.colorScheme.onSurfaceVariant,
                        )),
                const SizedBox(height: 4),
                Text('Add one using the field above',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: widget.colorScheme.onSurfaceVariant,
                        )),
              ],
            ),
          )
        else
          ...widget.customs.map(
            (opt) => Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: widget.colorScheme.outlineVariant),
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: widget.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.label_outline,
                      size: 16,
                      color: widget.colorScheme.onPrimaryContainer),
                ),
                title: Text(opt,
                    style:
                        const TextStyle(fontWeight: FontWeight.w500)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: 'Rename',
                      onPressed: () => _showRenameDialog(opt),
                      visualDensity: VisualDensity.compact,
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline,
                          color: widget.colorScheme.error),
                      tooltip: 'Delete',
                      onPressed: () => widget.onDelete(opt),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
