import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:kashly/core/di/providers.dart';
import 'package:kashly/core/theme/app_theme.dart';
import 'package:kashly/domain/entities/transaction.dart';
import 'package:kashly/ux_and_ui_elements/dialogs.dart';
import 'package:kashly/services/sync_engine/sync_service.dart';

const _categories = [
  'Food & Dining',
  'Transport',
  'Utilities',
  'Shopping',
  'Entertainment',
  'Healthcare',
  'Education',
  'Salary',
  'Business',
  'Transfer',
  'Other'
];

const _methods = [
  'Cash',
  'Bank Transfer',
  'Credit Card',
  'Debit Card',
  'UPI',
  'Cheque',
  'Other'
];

class TransactionEntryForm extends ConsumerStatefulWidget {
  final String cashbookId;
  final Transaction? existingTransaction;

  const TransactionEntryForm({
    super.key,
    required this.cashbookId,
    this.existingTransaction,
  });

  @override
  ConsumerState<TransactionEntryForm> createState() =>
      _TransactionEntryFormState();
}

class _TransactionEntryFormState
    extends ConsumerState<TransactionEntryForm> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _remarkCtrl = TextEditingController();

  late TransactionType _type;
  late DateTime _date;
  late String _category;
  late String _method;
  bool _isSaving = false;
  final List<Map<String, dynamic>> _splitEntries = [];

  @override
  void initState() {
    super.initState();
    final tx = widget.existingTransaction;
    _type = tx?.type ?? TransactionType.cashIn;
    _date = tx?.date ?? DateTime.now();
    _category = tx?.category ?? _categories.first;
    _method = tx?.method ?? _methods.first;
    if (tx != null) {
      _amountCtrl.text = tx.amount.toString();
      _remarkCtrl.text = tx.remark;
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _remarkCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingTransaction != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Transaction' : 'New Transaction'),
        actions: [
          if (_isSaving)
            const Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                    width: 20,
                    height: 20,
                    child:
                        CircularProgressIndicator(strokeWidth: 2))),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Type toggle
            Card(
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    Expanded(
                      child: _TypeButton(
                        label: 'Cash In',
                        icon: Icons.arrow_downward,
                        isSelected:
                            _type == TransactionType.cashIn,
                        color: AppColors.cashIn,
                        onTap: () => setState(
                            () => _type = TransactionType.cashIn),
                      ),
                    ),
                    Expanded(
                      child: _TypeButton(
                        label: 'Cash Out',
                        icon: Icons.arrow_upward,
                        isSelected:
                            _type == TransactionType.cashOut,
                        color: AppColors.cashOut,
                        onTap: () => setState(
                            () => _type = TransactionType.cashOut),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Amount
            TextFormField(
              controller: _amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                  decimal: true),
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixIcon: Icon(Icons.attach_money),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) {
                  return 'Amount is required';
                }
                if (double.tryParse(v) == null) {
                  return 'Enter a valid number';
                }
                if (double.parse(v) <= 0) {
                  return 'Amount must be positive';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),

            // Date picker
            InkWell(
              onTap: _pickDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date',
                  prefixIcon: Icon(Icons.calendar_today_outlined),
                ),
                child: Text(
                    '${_date.day}/${_date.month}/${_date.year}'),
              ),
            ),
            const SizedBox(height: 12),

            // Quick categories
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: _categories
                  .map((cat) => ChoiceChip(
                        label: Text(cat,
                            style: const TextStyle(fontSize: 12)),
                        selected: _category == cat,
                        onSelected: (_) =>
                            setState(() => _category = cat),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 12),

            // Category dropdown
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(
                labelText: 'Category',
                prefixIcon: Icon(Icons.category_outlined),
              ),
              items: _categories
                  .map((c) => DropdownMenuItem(
                      value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) =>
                  setState(() => _category = v ?? _categories.first),
            ),
            const SizedBox(height: 12),

            // Remark
            TextFormField(
              controller: _remarkCtrl,
              decoration: const InputDecoration(
                labelText: 'Remark / Description',
                prefixIcon: Icon(Icons.notes_outlined),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),

            // Method
            DropdownButtonFormField<String>(
              initialValue: _method,
              decoration: const InputDecoration(
                labelText: 'Payment Method',
                prefixIcon: Icon(Icons.payment_outlined),
              ),
              items: _methods
                  .map((m) => DropdownMenuItem(
                      value: m, child: Text(m)))
                  .toList(),
              onChanged: (v) =>
                  setState(() => _method = v ?? _methods.first),
            ),
            const SizedBox(height: 12),

            // Split entries
            if (_splitEntries.isNotEmpty) ...[
              const Text('Split Entries',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              ..._splitEntries.asMap().entries.map((entry) =>
                  _SplitEntryRow(
                    index: entry.key,
                    data: entry.value,
                    onRemove: () => setState(
                        () => _splitEntries.removeAt(entry.key)),
                    onChanged: (data) => setState(
                        () => _splitEntries[entry.key] = data),
                  )),
            ],

            OutlinedButton.icon(
              onPressed: _addSplit,
              icon: const Icon(Icons.call_split_outlined, size: 16),
              label: const Text('Add Split'),
            ),
            const SizedBox(height: 24),

            // Save button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isSaving ? null : _save,
                icon: const Icon(Icons.save_outlined),
                label: Text(isEdit
                    ? 'Update Transaction'
                    : 'Save Transaction'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _addSplit() {
    setState(() {
      _splitEntries.add({
        'amount': '',
        'category': _categories.first,
        'remark': ''
      });
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final repo = ref.read(transactionRepositoryProvider);
      final now = DateTime.now();
      final isEdit = widget.existingTransaction != null;

      final transaction = Transaction(
        id: widget.existingTransaction?.id ?? const Uuid().v4(),
        cashbookId: widget.cashbookId,
        amount: double.parse(_amountCtrl.text),
        type: _type,
        category: _category,
        remark: _remarkCtrl.text,
        method: _method,
        date: _date,
        createdAt: widget.existingTransaction?.createdAt ?? now,
        updatedAt: now,
        syncStatus: TransactionSyncStatus.pending,
        driveMeta: widget.existingTransaction?.driveMeta ??
            const DriveMeta(),
        isSplit: _splitEntries.isNotEmpty,
      );

      if (isEdit) {
        await repo.updateTransaction(transaction, 'user');
      } else {
        await repo.createTransaction(transaction);
      }

      // Save splits
      for (final split in _splitEntries) {
        if ((split['amount'] as String).isNotEmpty) {
          await repo.createTransaction(Transaction(
            id: const Uuid().v4(),
            cashbookId: widget.cashbookId,
            amount:
                double.tryParse(split['amount'] as String) ?? 0,
            type: _type,
            category: split['category'] as String,
            remark: split['remark'] as String? ?? '',
            method: _method,
            date: _date,
            createdAt: now,
            updatedAt: now,
            syncStatus: TransactionSyncStatus.pending,
            driveMeta: const DriveMeta(),
            parentTransactionId: transaction.id,
          ));
        }
      }

      // Trigger sync
      ref.read(syncServiceProvider).triggerSync(
            isEdit ? SyncTrigger.editEntry : SyncTrigger.addEntry,
          );

      ref.invalidate(transactionsProvider(widget.cashbookId));
      ref.invalidate(cashbookBalanceProvider(widget.cashbookId));
      ref.invalidate(cashbookTotalInProvider(widget.cashbookId));
      ref.invalidate(cashbookTotalOutProvider(widget.cashbookId));
      ref.invalidate(nonUploadedTransactionsProvider);

      if (mounted) {
        showSuccessSnackbar(context,
            isEdit ? 'Transaction updated' : 'Transaction saved');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) showErrorSnackbar(context, 'Failed to save: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

class _TypeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _TypeButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isSelected ? Border.all(color: color) : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                color: isSelected ? color : Colors.grey, size: 18),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    color: isSelected ? color : Colors.grey,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _SplitEntryRow extends StatelessWidget {
  final int index;
  final Map<String, dynamic> data;
  final VoidCallback onRemove;
  final ValueChanged<Map<String, dynamic>> onChanged;

  const _SplitEntryRow({
    required this.index,
    required this.data,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: data['amount'] as String?,
                decoration: const InputDecoration(
                    labelText: 'Amount', isDense: true),
                keyboardType:
                    const TextInputType.numberWithOptions(
                        decimal: true),
                onChanged: (v) =>
                    onChanged({...data, 'amount': v}),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                initialValue: data['remark'] as String?,
                decoration: const InputDecoration(
                    labelText: 'Remark', isDense: true),
                onChanged: (v) =>
                    onChanged({...data, 'remark': v}),
              ),
            ),
            IconButton(
                icon: const Icon(Icons.remove_circle_outline,
                    color: Colors.red),
                onPressed: onRemove),
          ],
        ),
      ),
    );
  }
}
