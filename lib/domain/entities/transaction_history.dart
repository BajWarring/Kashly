class TransactionHistory {
  final String id;
  final String transactionId;
  final String fieldName;
  final String oldValue;
  final String newValue;
  final String changedBy;
  final DateTime changedAt;

  const TransactionHistory({
    required this.id,
    required this.transactionId,
    required this.fieldName,
    required this.oldValue,
    required this.newValue,
    required this.changedBy,
    required this.changedAt,
  });

  TransactionHistory copyWith({
    String? id,
    String? transactionId,
    String? fieldName,
    String? oldValue,
    String? newValue,
    String? changedBy,
    DateTime? changedAt,
  }) =>
      TransactionHistory(
        id: id ?? this.id,
        transactionId: transactionId ?? this.transactionId,
        fieldName: fieldName ?? this.fieldName,
        oldValue: oldValue ?? this.oldValue,
        newValue: newValue ?? this.newValue,
        changedBy: changedBy ?? this.changedBy,
        changedAt: changedAt ?? this.changedAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'transactionId': transactionId,
        'fieldName': fieldName,
        'oldValue': oldValue,
        'newValue': newValue,
        'changedBy': changedBy,
        'changedAt': changedAt.toIso8601String(),
      };

  factory TransactionHistory.fromJson(Map<String, dynamic> json) =>
      TransactionHistory(
        id: json['id'] as String,
        transactionId: json['transactionId'] as String,
        fieldName: json['fieldName'] as String,
        oldValue: json['oldValue'] as String,
        newValue: json['newValue'] as String,
        changedBy: json['changedBy'] as String,
        changedAt: DateTime.parse(json['changedAt'] as String),
      );
}
