import 'dart:convert';

class Entry {
  String id;
  String bookId;
  String type; // 'in' or 'out'
  double amount;
  String note; // remarks
  String category;
  String paymentMethod;
  int timestamp; // date & time
  
  // For double-entry features (links to an entry in another book)
  String? linkedEntryId; 
  
  // For dynamic custom fields (contacts, extra categories, etc.)
  Map<String, dynamic> customFields;

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
      // Convert the Map to a JSON string for SQLite
      'customFields': jsonEncode(customFields), 
    };
  }

  factory Entry.fromMap(Map<String, dynamic> map) {
    return Entry(
      id: map['id'],
      bookId: map['bookId'],
      type: map['type'],
      amount: map['amount'],
      note: map['note'],
      category: map['category'],
      paymentMethod: map['paymentMethod'],
      timestamp: map['timestamp'],
      linkedEntryId: map['linkedEntryId'],
      // Decode the JSON string back into a Map
      customFields: map['customFields'] != null ? jsonDecode(map['customFields']) : {},
    );
  }
}
