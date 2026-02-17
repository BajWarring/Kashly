class CashBook {
  final String id;
  final String name;
  final double totalIn;
  final double totalOut;
  final List<String> customCategories;
  final List<String> customPaymentMethods;

  CashBook({
    required this.id,
    required this.name,
    this.totalIn = 0.0,
    this.totalOut = 0.0,
    List<String>? customCategories,
    List<String>? customPaymentMethods,
  })  : customCategories = customCategories ?? [],
        customPaymentMethods = customPaymentMethods ?? [];

  double get balance => totalIn - totalOut;
  bool get isPositive => balance >= 0;

  List<String> get allCategories => [
        'General', 'Food & Drinks', 'Transport', 'Salary', 'Business',
        'Bills & Utilities', 'Shopping', 'Entertainment', 'Healthcare', 'Investment',
        ...customCategories,
      ];

  List<String> get allPaymentMethods => [
        'Cash', 'Bank Transfer', 'UPI', 'Card', 'Cheque', 'Other',
        ...customPaymentMethods,
      ];

  CashBook copyWith({
    String? id,
    String? name,
    double? totalIn,
    double? totalOut,
    List<String>? customCategories,
    List<String>? customPaymentMethods,
  }) {
    return CashBook(
      id: id ?? this.id,
      name: name ?? this.name,
      totalIn: totalIn ?? this.totalIn,
      totalOut: totalOut ?? this.totalOut,
      customCategories: customCategories ?? this.customCategories,
      customPaymentMethods: customPaymentMethods ?? this.customPaymentMethods,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'totalIn': totalIn,
        'totalOut': totalOut,
        'customCategories': customCategories,
        'customPaymentMethods': customPaymentMethods,
      };

  factory CashBook.fromJson(Map<String, dynamic> json) => CashBook(
        id: json['id'],
        name: json['name'],
        totalIn: (json['totalIn'] as num).toDouble(),
        totalOut: (json['totalOut'] as num).toDouble(),
        customCategories: List<String>.from(json['customCategories'] ?? []),
        customPaymentMethods: List<String>.from(json['customPaymentMethods'] ?? []),
      );
}
