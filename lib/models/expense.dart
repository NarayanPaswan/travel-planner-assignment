class Expense {
  final String id;
  final String tripId;
  final String userId;
  final String description;
  final double amount;
  final String currency;
  final String? category;
  final DateTime createdAt;
  final DateTime updatedAt;

  Expense({
    required this.id,
    required this.tripId,
    required this.userId,
    required this.description,
    required this.amount,
    this.currency = 'USD',
    this.category,
    required this.createdAt,
    required this.updatedAt,
  });

  // Static getters for UI components
  static List<String> get expenseCategories => [
    'Food & Dining',
    'Transportation',
    'Accommodation',
    'Entertainment',
    'Shopping',
    'Activities',
    'Other',
  ];

  static List<String> get supportedCurrencies => [
    'USD',
    'EUR',
    'GBP',
    'JPY',
    'CAD',
    'AUD',
    'CHF',
    'CNY',
    'INR',
    'BRL',
  ];

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] ?? '',
      tripId: json['trip_id'] ?? '',
      userId: json['user_id'] ?? '',
      description: json['description'] ?? '',
      amount: (json['amount'] is num)
          ? (json['amount'] as num).toDouble()
          : 0.0,
      currency: json['currency'] ?? 'USD',
      category: json['category'],
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updated_at'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trip_id': tripId,
      'user_id': userId,
      'description': description,
      'amount': amount,
      'currency': currency,
      'category': category,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Expense copyWith({
    String? id,
    String? tripId,
    String? userId,
    String? description,
    double? amount,
    String? currency,
    String? category,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Expense(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      userId: userId ?? this.userId,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get formattedAmount => '$currency ${amount.toStringAsFixed(2)}';
}
