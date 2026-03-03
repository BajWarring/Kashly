import 'package:flutter/material.dart';
import '../../../../core/theme.dart';
import 'backup_models.dart';

class BackupFileTile extends StatelessWidget {
  final BackupFile file;
  final bool isLast;

  const BackupFileTile({super.key, required this.file, required this.isLast});

  void _showToast(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: file.isCloud ? accentLight : appBg, borderRadius: BorderRadius.circular(12)),
                child: Icon(file.isCloud ? Icons.cloud : Icons.folder_zip, color: file.isCloud ? accent : textMuted, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(file.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textDark), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text('${file.date} • ${file.size}', style: const TextStyle(fontSize: 11, color: textMuted, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: textLight),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                onSelected: (val) {
                  if (val == 'restore') {
                    _showToast(context, 'Restoring ${file.name}...', accent);
                  } else if (val == 'delete') {
                    _showToast(context, 'File deleted.', danger);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'restore', child: Row(children: [Icon(Icons.restore, size: 18, color: textDark), SizedBox(width: 12), Text('Restore Data', style: TextStyle(fontWeight: FontWeight.w600))])),
                  if (!file.isCloud) const PopupMenuItem(value: 'share', child: Row(children: [Icon(Icons.share, size: 18, color: textDark), SizedBox(width: 12), Text('Share File', style: TextStyle(fontWeight: FontWeight.w600))])),
                  const PopupMenuDivider(),
                  const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, size: 18, color: danger), SizedBox(width: 12), Text('Delete', style: TextStyle(color: danger, fontWeight: FontWeight.w600))])),
                ],
              )
            ],
          ),
        ),
        if (!isLast)
          const Divider(height: 1, color: borderCol, indent: 72),
      ],
    );
  }
}

