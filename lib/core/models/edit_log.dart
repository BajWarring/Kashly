class EditLog {
  String id;
  String entryId;
  String field;
  String oldValue;
  String newValue;
  int timestamp;

  EditLog({
    required this.id,
    required this.entryId,
    required this.field,
    required this.oldValue,
    required this.newValue,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'entryId': entryId,
      'field': field,
      'oldValue': oldValue,
      'newValue': newValue,
      'timestamp': timestamp,
    };
  }

  factory EditLog.fromMap(Map<String, dynamic> map) {
    return EditLog(
      id: map['id'],
      entryId: map['entryId'],
      field: map['field'],
      oldValue: map['oldValue'],
      newValue: map['newValue'],
      timestamp: map['timestamp'],
    );
  }
}
