class CustomField {
  String id;
  String bookId;
  String name;
  String type; // 'Text', 'Dropdown', 'Radio', 'Contacts'
  String options; // Comma-separated options for Dropdowns and Radios
  int sortOrder;

  CustomField({
    required this.id,
    required this.bookId,
    required this.name,
    required this.type,
    this.options = '',
    required this.sortOrder,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bookId': bookId,
      'name': name,
      'type': type,
      'options': options,
      'sortOrder': sortOrder,
    };
  }

  factory CustomField.fromMap(Map<String, dynamic> map) {
    return CustomField(
      id: map['id'],
      bookId: map['bookId'],
      name: map['name'],
      type: map['type'],
      options: map['options'] ?? '',
      sortOrder: map['sortOrder'],
    );
  }
}
