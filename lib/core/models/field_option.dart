class FieldOption {
  String id;
  String fieldName; // e.g., 'Category', 'Payment Method', 'Contact'
  String value;     // e.g., 'Office Supplies', 'Cash'
  int usageCount;   // To find the "most used"
  int lastUsed;     // To find the "recently used"

  FieldOption({
    required this.id,
    required this.fieldName,
    required this.value,
    this.usageCount = 0,
    required this.lastUsed,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fieldName': fieldName,
      'value': value,
      'usageCount': usageCount,
      'lastUsed': lastUsed,
    };
  }

  factory FieldOption.fromMap(Map<String, dynamic> map) {
    return FieldOption(
      id: map['id'],
      fieldName: map['fieldName'],
      value: map['value'],
      usageCount: map['usageCount'],
      lastUsed: map['lastUsed'],
    );
  }
}
