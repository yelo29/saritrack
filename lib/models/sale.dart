class Sale {
  final int? id;
  final int productId;
  final int qtySold;
  final double total;
  final String createdAt;
  final bool isResold;
  final double? amountPaid;
  final double? changeGiven;
  final String? discountType;
  final double discountValue;
  final double originalPrice;

  Sale({
    this.id,
    required this.productId,
    required this.qtySold,
    required this.total,
    required this.createdAt,
    this.isResold = false,
    this.amountPaid,
    this.changeGiven,
    this.discountType,
    this.discountValue = 0,
    required this.originalPrice,
  });

  // Convert to map for database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product_id': productId,
      'qty_sold': qtySold,
      'total': total,
      'created_at': createdAt,
      'is_resold': isResold ? 1 : 0,
      'amount_paid': amountPaid,
      'change_given': changeGiven,
      'discount_type': discountType,
      'discount_value': discountValue,
      'original_price': originalPrice,
    };
  }

  // Create from map from database
  factory Sale.fromMap(Map<String, dynamic> map) {
    return Sale(
      id: map['id'] as int?,
      productId: map['product_id'] as int,
      qtySold: map['qty_sold'] as int,
      total: map['total'] as double,
      createdAt: map['created_at'] as String,
      isResold: (map['is_resold'] as int? ?? 0) == 1,
      amountPaid: map['amount_paid'] as double?,
      changeGiven: map['change_given'] as double?,
      discountType: map['discount_type'] as String?,
      discountValue: (map['discount_value'] as num?)?.toDouble() ?? 0,
      originalPrice: (map['original_price'] as num?)?.toDouble() ?? map['total'] as double,
    );
  }

  // Copy with method for updates
  Sale copyWith({
    int? id,
    int? productId,
    int? qtySold,
    double? total,
    String? createdAt,
    bool? isResold,
    double? amountPaid,
    double? changeGiven,
    String? discountType,
    double? discountValue,
    double? originalPrice,
  }) {
    return Sale(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      qtySold: qtySold ?? this.qtySold,
      total: total ?? this.total,
      createdAt: createdAt ?? this.createdAt,
      isResold: isResold ?? this.isResold,
      amountPaid: amountPaid ?? this.amountPaid,
      changeGiven: changeGiven ?? this.changeGiven,
      discountType: discountType ?? this.discountType,
      discountValue: discountValue ?? this.discountValue,
      originalPrice: originalPrice ?? this.originalPrice,
    );
  }

  // Check if sale has a discount
  bool get hasDiscount {
    return discountType != null && discountValue > 0;
  }
}
