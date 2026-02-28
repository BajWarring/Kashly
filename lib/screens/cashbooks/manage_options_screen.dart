import 'package:flutter/material.dart';

import '../../core/models/field_option.dart';
import '../../core/database_helper.dart';
import '../../core/theme.dart'; // Adjust path for your colors

class ManageOptionsScreen extends StatefulWidget {
  final String fieldName; // e.g., 'Category' or 'Payment Method'

  const ManageOptionsScreen({super.key, required this.fieldName});

  @override
  State<ManageOptionsScreen> createState() => _ManageOptionsScreenState();
}

class _ManageOptionsScreenState extends State<ManageOptionsScreen> {
  List<FieldOption> _options = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  Future<void> _loadOptions() async {
    setState(() => _isLoading = true);
    final data = await DatabaseHelper.instance.getAllOptions(widget.fieldName);
    setState(() {
      _options = data;
      _isLoading = false;
    });
  }

  // --- ADD / EDIT DIALOG ---
  void _showOptionDialog({FieldOption? existingOption}) {
    final ctrl = TextEditingController(text: existingOption?.value ?? '');
    final isEdit = existingOption != null;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('${isEdit ? "Edit" : "New"} ${widget.fieldName}'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            hintText: 'e.g. ${widget.fieldName == "Category" ? "Travel" : "Debit Card"}',
            filled: true,
            fillColor: appBg,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: accent),
            onPressed: () async {
              final val = ctrl.text.trim();
              if (val.isEmpty) return;

              if (isEdit) {
                existingOption.value = val;
                await DatabaseHelper.instance.updateFieldOption(existingOption);
              } else {
                final newOpt = FieldOption(
                  id: 'OPT-${DateTime.now().millisecondsSinceEpoch}',
                  fieldName: widget.fieldName,
                  value: val,
                  usageCount: 0,
                  lastUsed: DateTime.now().millisecondsSinceEpoch,
                );
                await DatabaseHelper.instance.insertOption(newOpt);
              }

              Navigator.pop(ctx);
              _loadOptions();
            },
            child: const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // --- DELETE CONFIRMATION ---
  void _confirmDelete(FieldOption option) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Option?'),
        content: Text('Are you sure you want to delete "${option.value}" from your saved list?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: danger),
            onPressed: () async {
              await DatabaseHelper.instance.deleteFieldOption(option.id);
              Navigator.pop(ctx);
              _loadOptions();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          )
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.fieldName),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: accent))
          : _options.isEmpty
              ? Center(child: Text('No saved options. Add one!', style: const TextStyle(color: textMuted)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _options.length,
                  itemBuilder: (context, index) {
                    final opt = _options[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderCol),
                      ),
                      child: ListTile(
                        title: Text(opt.value, style: const TextStyle(fontWeight: FontWeight.bold, color: textDark)),
                        subtitle: Text('Used ${opt.usageCount} times', style: const TextStyle(fontSize: 12, color: textMuted)),
                        onTap: () {
                          // Select this option and return to the Add Entry screen
                          Navigator.pop(context, opt.value);
                        },
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: textLight, size: 20),
                              onPressed: () => _showOptionDialog(existingOption: opt),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: danger, size: 20),
                              onPressed: () => _confirmDelete(opt),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: accent,
        onPressed: () => _showOptionDialog(),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('Add ${widget.fieldName}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
