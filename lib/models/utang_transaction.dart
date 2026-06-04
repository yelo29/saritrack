class UtangTransaction {
  final int? id;
  final int customerId;
  final double amount;
  final String type; // 'credit' or 'payment'
  final String? notes;
  final String createdAt;

  UtangTransaction({
    this.id,
    required this.customerId,
    required this.amount,
    required this.type,
    this.notes,
    required this.createdAt,
  });

  // Convert to map for database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customer_id': customerId,
      'amount': amount,
      'type': type,
      'notes': notes,
      'created_at': createdAt,
    };
  }

  // Create from map from database
  factory UtangTransaction.fromMap(Map<String, dynamic> map) {
    return UtangTransaction(
      id: map['id'] as int?,
      customerId: map['customer_id'] as int,
      amount: map['amount'] as double,
      type: map['type'] as String,
      notes: map['notes'] as String?,
      createdAt: map['created_at'] as String,
    );
  }

  // Copy with method for updates
  UtangTransaction copyWith({
    int? id,
    int? customerId,
    double? amount,
    String? type,
    String? notes,
    String? createdAt,
  }) {
    return UtangTransaction(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
