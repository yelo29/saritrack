class Expense {
  final int? id;
  final String category;
  final double amount;
  final String? description;
  final String createdAt;

  Expense({
    this.id,
    required this.category,
    required this.amount,
    this.description,
    required this.createdAt,
  });

  // Convert to map for database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category,
      'amount': amount,
      'description': description,
      'created_at': createdAt,
    };
  }

  // Create from map from database
  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as int?,
      category: map['category'] as String,
      amount: map['amount'] as double,
      description: map['description'] as String?,
      createdAt: map['created_at'] as String,
    );
  }

  // Copy with method for updates
  Expense copyWith({
    int? id,
    String? category,
    double? amount,
    String? description,
    String? createdAt,
  }) {
    return Expense(
      id: id ?? this.id,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
