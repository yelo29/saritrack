class Product {
  final int? id;
  final String name;
  final int quantity;
  final int refundedStock;
  final double buyPrice;
  final double sellPrice;
  final int reorderLevel;
  final String? photoPath;
  final int? supplierId;
  final String? expirationDate;

  Product({
    this.id,
    required this.name,
    required this.quantity,
    this.refundedStock = 0,
    required this.buyPrice,
    required this.sellPrice,
    required this.reorderLevel,
    this.photoPath,
    this.supplierId,
    this.expirationDate,
  });

  // Convert to map for database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'refunded_stock': refundedStock,
      'buy_price': buyPrice,
      'sell_price': sellPrice,
      'reorder_level': reorderLevel,
      'photo_path': photoPath,
      'supplier_id': supplierId,
      'expiration_date': expirationDate,
    };
  }

  // Create from map from database
  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as int?,
      name: map['name'] as String,
      quantity: map['quantity'] as int,
      refundedStock: map['refunded_stock'] as int? ?? 0,
      buyPrice: map['buy_price'] as double,
      sellPrice: map['sell_price'] as double,
      reorderLevel: map['reorder_level'] as int,
      photoPath: map['photo_path'] as String?,
      supplierId: map['supplier_id'] as int?,
      expirationDate: map['expiration_date'] as String?,
    );
  }

  // Copy with method for updates
  Product copyWith({
    int? id,
    String? name,
    int? quantity,
    int? refundedStock,
    double? buyPrice,
    double? sellPrice,
    int? reorderLevel,
    String? photoPath,
    int? supplierId,
    String? expirationDate,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      refundedStock: refundedStock ?? this.refundedStock,
      buyPrice: buyPrice ?? this.buyPrice,
      sellPrice: sellPrice ?? this.sellPrice,
      reorderLevel: reorderLevel ?? this.reorderLevel,
      photoPath: photoPath ?? this.photoPath,
      supplierId: supplierId ?? this.supplierId,
      expirationDate: expirationDate ?? this.expirationDate,
    );
  }

  // Check if stock is low
  bool get isLowStock {
    return quantity <= reorderLevel;
  }

  // Check if product is expired
  bool get isExpired {
    if (expirationDate == null) return false;
    final expDate = DateTime.parse(expirationDate!);
    return expDate.isBefore(DateTime.now());
  }

  // Check if product is expiring soon (within 7 days)
  bool get isExpiringSoon {
    if (expirationDate == null) return false;
    final expDate = DateTime.parse(expirationDate!);
    final daysUntilExpiry = expDate.difference(DateTime.now()).inDays;
    return daysUntilExpiry >= 0 && daysUntilExpiry <= 7;
  }
}
