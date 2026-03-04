import 'dart:convert';

class Entry {
  String id;
  String bookId;
  String type;
  double amount;
  String note;
  String category;
  String paymentMethod;
  int timestamp;
  String? linkedEntryId;
  Map<String, dynamic> customFields;
  int updatedAt; // tracks last local write time — compared with SyncService.lastSyncTime

  Entry({
    required this.id,
    required this.bookId,
    required this.type,
    required this.amount,
    required this.note,
    required this.category,
    required this.paymentMethod,
    required this.timestamp,
    this.linkedEntryId,
    this.customFields = const {},
    this.updatedAt = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bookId': bookId,
      'type': type,
      'amount': amount,
      'note': note,
      'category': category,
      'paymentMethod': paymentMethod,
      'timestamp': timestamp,
      'linkedEntryId': linkedEntryId,
      'customFields': jsonEncode(customFields),
      // updatedAt is intentionally omitted — DatabaseHelper sets it on every write
    };
  }

  factory Entry.fromMap(Map<String, dynamic> map) {
    return Entry(
      id: map['id'],
      bookId: map['bookId'],
      type: map['type'],
      // STRICT CASTING: Prevents silent crash if SQLite returns an int instead of double
      amount: (map['amount'] as num).toDouble(),
      note: map['note'],
      category: map['category'],
      paymentMethod: map['paymentMethod'],
      timestamp: map['timestamp'],
      linkedEntryId: map['linkedEntryId'],
      customFields: map['customFields'] != null
          ? jsonDecode(map['customFields'])
          : {},
      updatedAt: map['updatedAt'] ?? 0,
    );
  }
}
