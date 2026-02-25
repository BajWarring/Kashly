import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:kashly/domain/entities/backup_record.dart';

Future<File> generateBackupReportPdf(List<BackupRecord> records) async {
  final pdf = pw.Document();
  pdf.addPage(
    pw.Page(
      build: (pw.Context context) => pw.Column(
        children: [
          pw.Text('Backup Report'),
          pw.Table.fromTextArray(
            data: [
              ['ID', 'Type', 'Date', 'Status'],
              ...records.map((r) => [r.id, r.type.name, r.createdAt.toString(), r.status.name]),
            ],
          ),
        ],
      ),
    ),
  );

  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/backup_report.pdf');
  await file.writeAsBytes(await pdf.save());
  return file;
}

Future<File> exportBackupManifest(List<BackupRecord> records) async {
  final data = [
    ['ID', 'Type', 'Date', 'Status', 'Notes'],
    ...records.map((r) => [r.id, r.type.name, r.createdAt.toString(), r.status.name, r.notes ?? '']),
  ];
  final csv = const ListToCsvConverter().convert(data);

  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/backup_manifest.csv');
  await file.writeAsString(csv);
  return file;
}

// Usage: In settings or backup center, call generateBackupReportPdf(backups);
