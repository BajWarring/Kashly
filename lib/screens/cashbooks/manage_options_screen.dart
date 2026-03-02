import 'package:flutter/material.dart';

import '../../core/models/field_option.dart';
import '../../core/database_helper.dart';
import '../../core/theme.dart'; 

class ManageOptionsScreen extends StatefulWidget {
  final String fieldName; 

  const ManageOptionsScreen({super.key, required this.fieldName});

  @override
  State<ManageOptionsScreen> createState() => _ManageOptionsScreenState();
}

class _ManageOptionsScreenState extends State<ManageOptionsScreen> {
  List<FieldOption> _options = [];
  final Set<String> _selectedOptionIds = {}; 
  bool _isLoading = true;
  
  // Basic protections: Don't allow user to delete default core options
  late List<String> lockedItems;

  @override
  void initState() {
    super.initState();
    lockedItems = widget.fieldName == 'Category' ? ['General'] : ['Cash'];
    _loadOptions();
  }

  Future<void> _loadOptions() async {
    setState(() => _isLoading = true);
    final data = await DatabaseHelper.instance.getAllOptions(widget.fieldName);
    if (!mounted) return;
    setState(() {
      _options = data;
      _isLoading = false;
    });
  }

  void _addNewOption() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('New ${widget.fieldName}', style: const TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(hintText: 'Enter name...', filled: true, fillColor: appBg, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: textMuted, fontWeight: FontWeight.bold))),
          ElevatedButton(
            onPressed: () async {
              if (ctrl.text.trim().isNotEmpty) {
                final newOpt = FieldOption(
                  id: 'OPT-${DateTime.now().millisecondsSinceEpoch}',
                  fieldName: widget.fieldName,
                  value: ctrl.text.trim(),
                  usageCount: 0,
                  lastUsed: DateTime.now().millisecondsSinceEpoch,
                );
                await DatabaseHelper.instance.insertOption(newOpt);
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                _loadOptions();
              }
            }, 
            style: ElevatedButton.styleFrom(backgroundColor: accent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('Add', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
          )
        ],
      )
    );
  }

  void _deleteSelected() async {
    for (String id in _selectedOptionIds) {
      await DatabaseHelper.instance.deleteFieldOption(id);
    }
    setState(() => _selectedOptionIds.clear());
    _loadOptions();
  }

  void _toggleSelection(FieldOption opt) {
    if (lockedItems.contains(opt.value)) return; // Protected
    setState(() {
      if (_selectedOptionIds.contains(opt.id)) {
        _selectedOptionIds.remove(opt.id);
      } else {
        _selectedOptionIds.add(opt.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isSelectionMode = _selectedOptionIds.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        leading: isSelectionMode 
          ? IconButton(icon: const Icon(Icons.close, color: textDark), onPressed: () => setState(() => _selectedOptionIds.clear()))
          : IconButton(icon: const Icon(Icons.arrow_back, color: textDark), onPressed: () => Navigator.pop(context)),
        title: Text(isSelectionMode ? '${_selectedOptionIds.length} Selected' : widget.fieldName, style: TextStyle(color: textDark)),
        backgroundColor: isSelectionMode ? accentLight : Colors.transparent,
        actions: [
          if (isSelectionMode)
            IconButton(icon: const Icon(Icons.delete_outline, color: danger), onPressed: _deleteSelected)
          else
            IconButton(icon: const Icon(Icons.add, color: accent), onPressed: _addNewOption),
        ],
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
                    final isLocked = lockedItems.contains(opt.value);
                    final isSelected = _selectedOptionIds.contains(opt.id);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? accentLight.withValues(alpha: 0.5) : Colors.white, 
                        borderRadius: BorderRadius.circular(16), 
                        border: Border.all(color: isSelected ? accent : borderCol)
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                        title: Text(opt.value, style: TextStyle(fontWeight: FontWeight.bold, color: isLocked ? textMuted : textDark)),
                        trailing: isLocked ? const Icon(Icons.lock_outline, size: 18, color: textLight) : (isSelected ? const Icon(Icons.check_circle, color: accent) : null),
                        
                        onLongPress: () => _toggleSelection(opt),
                        onTap: isSelectionMode 
                          ? () => _toggleSelection(opt) 
                          : () {
                              if (!isLocked || isLocked) Navigator.pop(context, opt.value);
                            },
                      ),
                    );
                  },
                ),
    );
  }
}
