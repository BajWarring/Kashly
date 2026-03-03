import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

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
  List<Book> _subBooks = [];
  String? _editingField; 
  final _editCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _book = widget.book;
    _loadSubBooks();
  }

  Future<void> _loadSubBooks() async {
    final data = await DatabaseHelper.instance.getSubBooks(_book.id);
    if (!mounted) return;
    setState(() { _subBooks = data; });
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

  void _renameSubBook(Book sb) async {
    final ctrl = TextEditingController(text: sb.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Sub Book'),
        content: TextField(controller: ctrl, autofocus: true, decoration: InputDecoration(filled: true, fillColor: appBg, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: accent), onPressed: () => Navigator.pop(ctx, ctrl.text), child: const Text('Save', style: TextStyle(color: Colors.white)))
        ]
      )
    );
    if (newName != null && newName.trim().isNotEmpty) {
      sb.name = newName.trim();
      await DatabaseHelper.instance.updateBook(sb);
      _loadSubBooks();
    }
  }

  void _deleteSubBook(Book sb) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Sub Book', style: TextStyle(color: danger)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('This will delete the sub-book and all its entries permanently.', style: TextStyle(fontSize: 13, color: textMuted)),
            const SizedBox(height: 16),
            TextField(controller: ctrl, autofocus: true, decoration: InputDecoration(hintText: 'Type "${sb.name}" to confirm', filled: true, fillColor: dangerLight, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          StatefulBuilder(
            builder: (c, setD) {
              ctrl.addListener(() => setD((){}));
              return ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: danger),
                onPressed: ctrl.text == sb.name ? () async {
                  await DatabaseHelper.instance.deleteBook(sb.id);
                  if (!ctx.mounted) return;
                  Navigator.pop(ctx);
                  _loadSubBooks();
                } : null, 
                child: const Text('Delete', style: TextStyle(color: Colors.white))
              );
            }
          )
        ]
      )
    );
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
            const Text('Choose Icon or Image', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Wrap(
              spacing: 16, runSpacing: 16,
              children: [
                InkWell(
                  onTap: () async {
                    final picker = ImagePicker();
                    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                    if (pickedFile != null) {
                      setState(() => _book.icon = pickedFile.path);
                      await DatabaseHelper.instance.updateBook(_book);
                    }
                    if (!ctx.mounted) return;
                    Navigator.pop(ctx);
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 64, height: 64,
                    decoration: BoxDecoration(color: appBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderCol, style: BorderStyle.solid)),
                    child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.upload, color: textMuted, size: 20), SizedBox(height: 4), Text('Gallery', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: textMuted))]),
                  ),
                ),
                ...availableIcons.keys.map((key) => InkWell(
                  onTap: () async {
                    setState(() => _book.icon = key);
                    await DatabaseHelper.instance.updateBook(_book);
                    if (!ctx.mounted) return;
                    Navigator.pop(ctx);
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 64, height: 64,
                    decoration: BoxDecoration(color: _book.icon == key ? accent : appBg, borderRadius: BorderRadius.circular(16), boxShadow: _book.icon == key ? [BoxShadow(color: accent.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))] : null),
                    child: Icon(availableIcons[key], color: _book.icon == key ? Colors.white : textMuted),
                  ),
                )),
              ]
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
    return DateFormat('MMM d, yyyy • h:mm a').format(DateTime.fromMillisecondsSinceEpoch(ms));
  }

  Widget _buildBookCover() {
    if (availableIcons.containsKey(_book.icon)) {
      return Icon(availableIcons[_book.icon], color: accent, size: 32);
    } else {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.file(
          File(_book.icon),
          width: 64, height: 64, fit: BoxFit.cover,
          errorBuilder: (ctx, err, stack) => const Icon(Icons.broken_image, color: textMuted),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Book Details')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
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
                      Container(
                        width: 64, height: 64, 
                        decoration: BoxDecoration(color: accentLight, borderRadius: BorderRadius.circular(16)), 
                        child: _buildBookCover(),
                      ),
                      Container(width: 64, height: 64, decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.camera_alt, color: Colors.white70, size: 24)),
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

          const Text('BOOK INFORMATION', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textLight, letterSpacing: 1.2)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: borderCol)),
            child: Column(
              children: [
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
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              TextField(controller: _editCtrl, autofocus: true, decoration: const InputDecoration(isDense: true, filled: true, fillColor: appBg, border: OutlineInputBorder(borderSide: BorderSide.none))),
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
                        : Text(_book.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textDark)),
                    ],
                  ),
                ),
                const Divider(height: 1, color: borderCol),
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

          // --- NEW: SUB BOOKS MANAGEMENT ---
          if (_book.parentId == null) ...[
            const Text('SUB BOOKS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textLight, letterSpacing: 1.2)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: borderCol)),
              child: _subBooks.isEmpty 
                ? const Padding(padding: EdgeInsets.all(24), child: Center(child: Text('No sub-books connected.', style: TextStyle(color: textMuted, fontWeight: FontWeight.w500))))
                : Column(
                    children: _subBooks.asMap().entries.map((entry) {
                      int idx = entry.key;
                      Book sb = entry.value;
                      return Column(
                        children: [
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                            leading: const Icon(Icons.account_tree_outlined, color: textLight),
                            title: Text(sb.name, style: const TextStyle(fontWeight: FontWeight.bold, color: textDark)),
                            trailing: PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert, color: textMuted),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              onSelected: (v) {
                                if (v == 'rename') _renameSubBook(sb);
                                if (v == 'delete') _deleteSubBook(sb);
                              },
                              itemBuilder: (c) => [
                                const PopupMenuItem(value: 'rename', child: Text('Rename')),
                                const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: danger))),
                              ]
                            )
                          ),
                          if (idx != _subBooks.length - 1) const Divider(height: 1, color: borderCol),
                        ],
                      );
                    }).toList(),
                  ),
            ),
            const SizedBox(height: 32),
          ],

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
