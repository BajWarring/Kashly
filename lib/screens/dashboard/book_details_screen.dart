import 'package:flutter/material.dart';
import '../../core/models/book.dart';
import '../../core/database_helper.dart';
import '../../core/theme.dart';

class BookDetailsScreen extends StatefulWidget {
  final Book book;
  const BookDetailsScreen({super.key, required this.book});

  @override
  State<BookDetailsScreen> createState() => _BookDetailsScreenState();
}

class _BookDetailsScreenState extends State<BookDetailsScreen> {
  late Book _book;
  String? _editingField; // 'name' or 'description'
  final _editCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _book = widget.book;
  }

  void _saveEdit() async {
    if (_editingField == 'name' && _editCtrl.text.trim().isEmpty) return;
    setState(() {
      if (_editingField == 'name') _book.name = _editCtrl.text.trim();
      if (_editingField == 'description') _book.description = _editCtrl.text.trim();
      _book.timestamp = DateTime.now().millisecondsSinceEpoch;
      _editingField = null;
    });
    await DatabaseHelper.instance.updateBook(_book);
  }

  void _pickIcon() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Choose Icon', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Wrap(
              spacing: 16, runSpacing: 16,
              children: availableIcons.keys.map((key) => InkWell(
                onTap: () async {
                  setState(() => _book.icon = key);
                  await DatabaseHelper.instance.updateBook(_book);
                  if (!ctx.mounted) return;
                  Navigator.pop(ctx);
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(
                    color: _book.icon == key ? accent : appBg,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: _book.icon == key ? [BoxShadow(color: accent.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))] : null,
                  ),
                  child: Icon(availableIcons[key], color: _book.icon == key ? Colors.white : textMuted),
                ),
              )).toList(),
            )
          ],
        ),
      )
    );
  }

  void _strictDelete() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Column(
          children: [
            Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: dangerLight, borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.warning_amber_rounded, color: danger, size: 32)),
            const SizedBox(height: 16),
            const Text('Permanent Deletion', style: TextStyle(fontWeight: FontWeight.w900)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RichText(textAlign: TextAlign.center, text: TextSpan(style: const TextStyle(color: textMuted, fontSize: 14, height: 1.5), children: [
              const TextSpan(text: 'This action is irreversible. Type the exact name: '),
              TextSpan(text: _book.name, style: const TextStyle(fontWeight: FontWeight.bold, color: textDark, backgroundColor: appBg)),
            ])),
            const SizedBox(height: 20),
            TextField(
              controller: ctrl,
              autofocus: true,
              decoration: InputDecoration(hintText: _book.name, filled: true, fillColor: appBg, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)),
            )
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: textMuted, fontWeight: FontWeight.bold))),
          StatefulBuilder(
            builder: (context, setStateDialog) {
              ctrl.addListener(() => setStateDialog((){}));
              final isValid = ctrl.text == _book.name;
              return ElevatedButton(
                onPressed: isValid ? () async {
                  await DatabaseHelper.instance.deleteBook(_book.id);
                  if (!ctx.mounted) return;
                  Navigator.pop(ctx); 
                  if (!context.mounted) return;
                  Navigator.pop(context); 
                } : null,
                style: ElevatedButton.styleFrom(backgroundColor: danger, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              );
            }
          )
        ],
      )
    );
  }

  String _formatDate(int ms) {
    final d = DateTime.fromMillisecondsSinceEpoch(ms);
    return "${d.day}/${d.month}/${d.year} ${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Book Details')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // HEADER PROFILE
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: borderCol)),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _pickIcon,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(width: 64, height: 64, decoration: BoxDecoration(color: accentLight, borderRadius: BorderRadius.circular(16)), child: Icon(availableIcons[_book.icon] ?? Icons.book, color: accent, size: 32)),
                      Container(width: 64, height: 64, decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.camera_alt, color: Colors.white70, size: 24)),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ID: ${_book.id}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textLight, letterSpacing: 1)),
                      const SizedBox(height: 4),
                      Text(_book.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: textDark)),
                    ],
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 32),

          // EDITABLE INFO
          const Text('BOOK INFORMATION', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textLight, letterSpacing: 1.2)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: borderCol)),
            child: Column(
              children: [
                // Name Row
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('NAME', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textMuted)),
                          if (_editingField != 'name') IconButton(constraints: const BoxConstraints(), padding: EdgeInsets.zero, icon: const Icon(Icons.edit, size: 16, color: textLight), onPressed: () { setState(() { _editingField = 'name'; _editCtrl.text = _book.name; }); }),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _editingField == 'name' 
                        ? Row(
                            children: [
                              Expanded(child: TextField(controller: _editCtrl, autofocus: true, decoration: const InputDecoration(isDense: true, filled: true, fillColor: appBg, border: OutlineInputBorder(borderSide: BorderSide.none)))),
                              const SizedBox(width: 8),
                              IconButton(icon: const Icon(Icons.check_circle, color: success), onPressed: _saveEdit),
                              IconButton(icon: const Icon(Icons.cancel, color: textLight), onPressed: () => setState(() => _editingField = null)),
                            ],
                          )
                        : Text(_book.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textDark)),
                    ],
                  ),
                ),
                const Divider(height: 1, color: borderCol),
                // Desc Row
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('DESCRIPTION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textMuted)),
                          if (_editingField != 'description') IconButton(constraints: const BoxConstraints(), padding: EdgeInsets.zero, icon: const Icon(Icons.edit, size: 16, color: textLight), onPressed: () { setState(() { _editingField = 'description'; _editCtrl.text = _book.description; }); }),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _editingField == 'description' 
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              TextField(controller: _editCtrl, autofocus: true, maxLines: 2, decoration: const InputDecoration(isDense: true, filled: true, fillColor: appBg, border: OutlineInputBorder(borderSide: BorderSide.none))),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextButton(onPressed: () => setState(() => _editingField = null), child: const Text('Cancel', style: TextStyle(color: textMuted))),
                                  ElevatedButton(onPressed: _saveEdit, style: ElevatedButton.styleFrom(backgroundColor: accent), child: const Text('Save', style: TextStyle(color: Colors.white))),
                                ],
                              )
                            ],
                          )
                        : Text(_book.description.isEmpty ? 'No description provided.' : _book.description, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: _book.description.isEmpty ? textLight : textDark, fontStyle: _book.description.isEmpty ? FontStyle.italic : FontStyle.normal)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // METADATA
          const Text('METADATA', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textLight, letterSpacing: 1.2)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: borderCol)),
            child: Column(
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Created On', style: TextStyle(fontWeight: FontWeight.bold, color: textMuted)), Text(_formatDate(_book.createdAt), style: const TextStyle(fontWeight: FontWeight.bold, color: textDark))]),
                const Divider(height: 24, color: borderCol),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Last Modified', style: TextStyle(fontWeight: FontWeight.bold, color: textMuted)), Text(_formatDate(_book.timestamp), style: const TextStyle(fontWeight: FontWeight.bold, color: textDark))]),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // DANGER ZONE
          ElevatedButton.icon(
            onPressed: _strictDelete,
            icon: const Icon(Icons.delete_outline, color: danger),
            label: const Text('Delete Cashbook', style: TextStyle(color: danger, fontSize: 16, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(backgroundColor: dangerLight, elevation: 0, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFFFECDD3)))),
          )

        ],
      ),
    );
  }
}
