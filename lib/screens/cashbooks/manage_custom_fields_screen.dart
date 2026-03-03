import 'package:flutter/material.dart';
import '../../core/models/custom_field.dart';
import '../../core/database_helper.dart';
import '../../core/theme.dart';

class ManageCustomFieldsScreen extends StatefulWidget {
  final String bookId;
  const ManageCustomFieldsScreen({super.key, required this.bookId});

  @override
  State<ManageCustomFieldsScreen> createState() => _ManageCustomFieldsScreenState();
}

class _ManageCustomFieldsScreenState extends State<ManageCustomFieldsScreen> {
  List<CustomField> customFields = [];
  bool _isLoading = true;

  final Map<String, IconData> fieldIcons = {
    'Text': Icons.short_text,
    'Dropdown': Icons.arrow_drop_down_circle_outlined,
    'Radio': Icons.radio_button_checked,
    'Contacts': Icons.contact_page_outlined,
  };

  @override
  void initState() {
    super.initState();
    _loadFields();
  }

  Future<void> _loadFields() async {
    setState(() => _isLoading = true);
    final fields = await DatabaseHelper.instance.getCustomFieldsForBook(widget.bookId);
    if (!mounted) return;
    setState(() {
      customFields = fields;
      _isLoading = false;
    });
  }

  void _showFieldDialog({CustomField? existing}) {
    final ctrlName = TextEditingController(text: existing?.name ?? '');
    final ctrlOptions = TextEditingController(text: existing?.options ?? '');
    String selectedType = existing?.type ?? 'Text';

    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Configure Field', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textDark)),
                const SizedBox(height: 24),
                
                const Text('FIELD NAME', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textMuted)),
                const SizedBox(height: 8),
                TextField(controller: ctrlName, autofocus: true, decoration: InputDecoration(hintText: 'e.g. Party Name', filled: true, fillColor: appBg, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
                const SizedBox(height: 24),

                const Text('FIELD TYPE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textMuted)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10, runSpacing: 10,
                  children: fieldIcons.keys.map((type) {
                    bool isSel = selectedType == type;
                    return InkWell(
                      onTap: () => setSheetState(() => selectedType = type),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(color: isSel ? accentLight : appBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: isSel ? accent : borderCol)),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(fieldIcons[type], size: 16, color: isSel ? accent : textMuted), const SizedBox(width: 8), Text(type, style: TextStyle(fontWeight: FontWeight.bold, color: isSel ? accent : textDark))]),
                      ),
                    );
                  }).toList(),
                ),
                
                if (selectedType == 'Dropdown' || selectedType == 'Radio') ...[
                  const SizedBox(height: 24),
                  const Text('OPTIONS (Comma Separated)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textMuted)),
                  const SizedBox(height: 8),
                  TextField(controller: ctrlOptions, decoration: InputDecoration(hintText: 'Option 1, Option 2, Option 3', filled: true, fillColor: appBg, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
                ],

                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (ctrlName.text.trim().isEmpty) return;
                      final field = CustomField(
                        id: existing?.id ?? 'CF-${DateTime.now().millisecondsSinceEpoch}',
                        bookId: widget.bookId,
                        name: ctrlName.text.trim(),
                        type: selectedType,
                        options: ctrlOptions.text.trim(),
                        sortOrder: existing?.sortOrder ?? customFields.length,
                      );
                      if (existing == null) {
                        await DatabaseHelper.instance.insertCustomField(field);
                      } else {
                        await DatabaseHelper.instance.updateCustomField(field);
                      }
                      if (!ctx.mounted) return;
                      Navigator.pop(ctx);
                      _loadFields();
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: textDark, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    child: Text(existing == null ? 'Add Field' : 'Save Changes', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                )
              ],
            ),
          ),
        )
      )
    );
  }

  void _deleteField(CustomField field) async {
    await DatabaseHelper.instance.deleteCustomField(field.id);
    _loadFields();
  }

  Widget _buildFixedTile(String name, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderCol)),
      child: Row(children: [Icon(icon, color: textMuted, size: 20), const SizedBox(width: 16), Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, color: textMuted, fontSize: 15))), const Icon(Icons.lock_outline, color: textLight, size: 18)]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Form Fields')),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: accent))
        : ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text('FIXED FIELDS (Undeletable)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textMuted, letterSpacing: 1)),
              const SizedBox(height: 12),
              _buildFixedTile('Date & Time', Icons.event),
              _buildFixedTile('Amount', Icons.money),
              _buildFixedTile('Remarks', Icons.notes),
              _buildFixedTile('Category', Icons.category),
              _buildFixedTile('Payment Method', Icons.account_balance),
              const SizedBox(height: 32),
              
              const Text('CUSTOM FIELDS (Drag to reorder)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textMuted, letterSpacing: 1)),
              const SizedBox(height: 12),
              if (customFields.isEmpty)
                Container(padding: const EdgeInsets.all(32), alignment: Alignment.center, decoration: BoxDecoration(color: Colors.transparent, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderCol, style: BorderStyle.solid)), child: const Text('No custom fields added yet.', style: TextStyle(color: textMuted, fontWeight: FontWeight.w600)))
              else
                ReorderableListView.builder(
                  shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                  itemCount: customFields.length,
                  onReorder: (oldIdx, newIdx) async {
                    if (newIdx > oldIdx) newIdx -= 1;
                    setState(() {
                      final item = customFields.removeAt(oldIdx);
                      customFields.insert(newIdx, item);
                    });
                    await DatabaseHelper.instance.updateCustomFieldOrders(customFields);
                  },
                  itemBuilder: (context, index) {
                    final field = customFields[index];
                    return KeyedSubtree(
                      key: ValueKey(field.id),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderCol), boxShadow: const [BoxShadow(color: Color(0x05000000), blurRadius: 4, offset: Offset(0, 2))]),
                        child: Row(
                          children: [
                            Icon(fieldIcons[field.type] ?? Icons.list, color: accent, size: 20), const SizedBox(width: 16),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(field.name, style: const TextStyle(fontWeight: FontWeight.bold, color: textDark, fontSize: 15)), Text('${field.type} Field', style: const TextStyle(color: textLight, fontSize: 11, fontWeight: FontWeight.w600))])),
                            IconButton(icon: const Icon(Icons.edit_outlined, color: textMuted, size: 20), padding: EdgeInsets.zero, constraints: const BoxConstraints(), onPressed: () => _showFieldDialog(existing: field)),
                            const SizedBox(width: 16),
                            IconButton(icon: const Icon(Icons.delete_outline, color: danger, size: 20), padding: EdgeInsets.zero, constraints: const BoxConstraints(), onPressed: () => _deleteField(field)),
                            const SizedBox(width: 16),
                            const Icon(Icons.drag_indicator, color: textLight, size: 20),
                          ],
                        ),
                      ),
                    );
                  }
                ),
            ],
          ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: () => _showFieldDialog(),
            icon: const Icon(Icons.add, color: Colors.white), label: const Text('Add New Field', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(backgroundColor: textDark, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
          ),
        ),
      ),
    );
  }
}
