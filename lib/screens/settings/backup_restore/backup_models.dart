class PendingSync {
  final String bookName;
  final int pendingEntries;
  PendingSync(this.bookName, this.pendingEntries);
}

class BackupFile {
  final String name;
  final String date;
  final String size;
  final bool isCloud;
  BackupFile(this.name, this.date, this.size, this.isCloud);
}
