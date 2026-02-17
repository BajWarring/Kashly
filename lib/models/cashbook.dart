class CashBook {
  final String id;
  final String name;
  final double balance;
  final bool isPositive;

  CashBook({
    required this.id,
    required this.name,
    required this.balance,
    required this.isPositive,
  });

  String get formattedBalance {
    final sign = isPositive ? '+' : '-';
    return '$sign ₹${balance.toStringAsFixed(2)}';
  }

  CashBook copyWith({
    String? id,
    String? name,
    double? balance,
    bool? isPositive,
  }) {
    return CashBook(
      id: id ?? this.id,
      name: name ?? this.name,
      balance: balance ?? this.balance,
      isPositive: isPositive ?? this.isPositive,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'balance': balance,
      'isPositive': isPositive,
    };
  }

  factory CashBook.fromJson(Map<String, dynamic> json) {
    return CashBook(
      id: json['id'] as String,
      name: json['name'] as String,
      balance: (json['balance'] as num).toDouble(),
      isPositive: json['isPositive'] as bool,
    );
  }
}
