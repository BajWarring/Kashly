enum EntryType { cashIn, cashOut }

enum PaymentMethod {
  cash,
  bankTransfer,
  upi,
  card,
  cheque,
  other;

  String get label {
    switch (this) {
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.bankTransfer:
        return 'Bank Transfer';
      case PaymentMethod.upi:
        return 'UPI';
      case PaymentMethod.card:
        return 'Card';
      case PaymentMethod.cheque:
        return 'Cheque';
      case PaymentMethod.other:
        return 'Other';
    }
  }
}

class Transaction {
  final String id;
  final EntryType entryType;
  final double amount;
  final DateTime dateTime;
  final String? remarks;
  final String category;
  final String paymentMethod;
  final String cashbookId;

  Transaction({
    required this.id,
    required this.entryType,
    required this.amount,
    required this.dateTime,
    this.remarks,
    required this.category,
    required this.paymentMethod,
    required this.cashbookId,
  });

  bool get isCashIn => entryType == EntryType.cashIn;

  Map<String, dynamic> toJson() => {
        'id': id,
        'entryType': entryType.name,
        'amount': amount,
        'dateTime': dateTime.toIso8601String(),
        'remarks': remarks,
        'category': category,
        'paymentMethod': paymentMethod,
        'cashbookId': cashbookId,
      };

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
        id: json['id'],
        entryType: EntryType.values.byName(json['entryType']),
        amount: (json['amount'] as num).toDouble(),
        dateTime: DateTime.parse(json['dateTime']),
        remarks: json['remarks'],
        category: json['category'],
        paymentMethod: json['paymentMethod'],
        cashbookId: json['cashbookId'],
      );
}
