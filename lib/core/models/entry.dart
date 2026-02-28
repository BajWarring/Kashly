class Entry {
  String id;
  String bookId;
  String type; // 'in' or 'out'
  double amount;
  String note;
  int timestamp;

  Entry({
    required this.id,
    required this.bookId,
    required this.type,
    required this.amount,
    required this.note,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bookId': bookId,
      'type': type,
      'amount': amount,
      'note': note,
      'timestamp': timestamp,
    };
  }

  factory Entry.fromMap(Map<String, dynamic> map) {
    return Entry(
      id: map['id'],
      bookId: map['bookId'],
      type: map['type'],
      amount: map['amount'],
      note: map['note'],
      timestamp: map['timestamp'],
    );
  }
}
