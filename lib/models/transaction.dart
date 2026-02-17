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
  final DateTime createdAt;
  final List<EditLog> editHistory;

  Transaction({
    required this.id,
    required this.entryType,
    required this.amount,
    required this.dateTime,
    this.remarks,
    required this.category,
    required this.paymentMethod,
    required this.cashbookId,
    DateTime? createdAt,
    List<EditLog>? editHistory,
  })  : createdAt = createdAt ?? DateTime.now(),
        editHistory = editHistory ?? [];

  bool get isCashIn => entryType == EntryType.cashIn;

  Transaction copyWith({
    String? id,
    EntryType? entryType,
    double? amount,
    DateTime? dateTime,
    String? remarks,
    String? category,
    String? paymentMethod,
    String? cashbookId,
    DateTime? createdAt,
    List<EditLog>? editHistory,
  }) {
    return Transaction(
      id: id ?? this.id,
      entryType: entryType ?? this.entryType,
      amount: amount ?? this.amount,
      dateTime: dateTime ?? this.dateTime,
      remarks: remarks ?? this.remarks,
      category: category ?? this.category,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      cashbookId: cashbookId ?? this.cashbookId,
      createdAt: createdAt ?? this.createdAt,
      editHistory: editHistory ?? this.editHistory,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'entryType': entryType.name,
        'amount': amount,
        'dateTime': dateTime.toIso8601String(),
        'remarks': remarks,
        'category': category,
        'paymentMethod': paymentMethod,
        'cashbookId': cashbookId,
        'createdAt': createdAt.toIso8601String(),
        'editHistory': editHistory.map((e) => e.toJson()).toList(),
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
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'])
            : DateTime.now(),
        editHistory: json['editHistory'] != null
            ? (json['editHistory'] as List)
                .map((e) => EditLog.fromJson(e as Map<String, dynamic>))
                .toList()
            : [],
      );
}

// ── Edit Log (embedded in Transaction) ──────────────────────────────────────

class EditLog {
  final String id;
  final DateTime editedAt;
  final List<FieldChange> changes;

  EditLog({
    required this.id,
    required this.editedAt,
    required this.changes,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'editedAt': editedAt.toIso8601String(),
        'changes': changes.map((c) => c.toJson()).toList(),
      };

  factory EditLog.fromJson(Map<String, dynamic> json) => EditLog(
        id: json['id'],
        editedAt: DateTime.parse(json['editedAt']),
        changes: (json['changes'] as List)
            .map((c) => FieldChange.fromJson(c as Map<String, dynamic>))
            .toList(),
      );
}

class FieldChange {
  final String fieldName;
  final String before;
  final String after;

  const FieldChange({
    required this.fieldName,
    required this.before,
    required this.after,
  });

  Map<String, dynamic> toJson() => {
        'fieldName': fieldName,
        'before': before,
        'after': after,
      };

  factory FieldChange.fromJson(Map<String, dynamic> json) => FieldChange(
        fieldName: json['fieldName'],
        before: json['before'],
        after: json['after'],
      );
}
