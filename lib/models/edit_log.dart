// Model for tracking edit history of a transaction

class EditLog {
  final String id;
  final String transactionId;
  final DateTime editedAt;
  final List<FieldChange> changes;

  EditLog({
    required this.id,
    required this.transactionId,
    required this.editedAt,
    required this.changes,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'transactionId': transactionId,
        'editedAt': editedAt.toIso8601String(),
        'changes': changes.map((c) => c.toJson()).toList(),
      };

  factory EditLog.fromJson(Map<String, dynamic> json) => EditLog(
        id: json['id'],
        transactionId: json['transactionId'],
        editedAt: DateTime.parse(json['editedAt']),
        changes: (json['changes'] as List)
            .map((c) => FieldChange.fromJson(c))
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
