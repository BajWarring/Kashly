class Book {
  String id;
  String name;
  String description;
  double balance;
  int createdAt;
  int timestamp;
  String currency;
  String icon;

  Book({
    required this.id,
    required this.name,
    required this.description,
    required this.balance,
    required this.createdAt,
    required this.timestamp,
    required this.currency,
    required this.icon,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'balance': balance,
      'createdAt': createdAt,
      'timestamp': timestamp,
      'currency': currency,
      'icon': icon,
    };
  }

  factory Book.fromMap(Map<String, dynamic> map) {
    return Book(
      id: map['id'],
      name: map['name'],
      description: map['description'] ?? '',
      balance: map['balance'],
      createdAt: map['createdAt'],
      timestamp: map['timestamp'],
      currency: map['currency'],
      icon: map['icon'],
    );
  }
}
