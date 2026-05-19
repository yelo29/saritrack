class Refund {
  final int? id;
  final int saleId;
  final String reason;
  final String refundedAt;
  final double amount;
  final int quantity;

  Refund({
    this.id,
    required this.saleId,
    required this.reason,
    required this.refundedAt,
    required this.amount,
    required this.quantity,
  });

  // Convert to map for database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sale_id': saleId,
      'reason': reason,
      'refunded_at': refundedAt,
      'amount': amount,
      'quantity': quantity,
    };
  }

  // Create from map from database
  factory Refund.fromMap(Map<String, dynamic> map) {
    return Refund(
      id: map['id'] as int?,
      saleId: map['sale_id'] as int,
      reason: map['reason'] as String,
      refundedAt: map['refunded_at'] as String,
      amount: map['amount'] as double,
      quantity: map['quantity'] as int? ?? 0,
    );
  }

  // Copy with method for updates
  Refund copyWith({
    int? id,
    int? saleId,
    String? reason,
    String? refundedAt,
    double? amount,
    int? quantity,
  }) {
    return Refund(
      id: id ?? this.id,
      saleId: saleId ?? this.saleId,
      reason: reason ?? this.reason,
      refundedAt: refundedAt ?? this.refundedAt,
      amount: amount ?? this.amount,
      quantity: quantity ?? this.quantity,
    );
  }
}
