class ProductVariant {
  final int? id;
  final int productId;
  final String name;
  final int quantity;
  final double sellPrice;
  final double buyPrice;
  final String? barcode;

  ProductVariant({
    this.id,
    required this.productId,
    required this.name,
    required this.quantity,
    required this.sellPrice,
    required this.buyPrice,
    this.barcode,
  });

  // Convert to map for database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product_id': productId,
      'name': name,
      'quantity': quantity,
      'sell_price': sellPrice,
      'buy_price': buyPrice,
      'barcode': barcode,
    };
  }

  // Create from map from database
  factory ProductVariant.fromMap(Map<String, dynamic> map) {
    return ProductVariant(
      id: map['id'] as int?,
      productId: map['product_id'] as int,
      name: map['name'] as String,
      quantity: map['quantity'] as int,
      sellPrice: (map['sell_price'] as num).toDouble(),
      buyPrice: (map['buy_price'] as num).toDouble(),
      barcode: map['barcode'] as String?,
    );
  }

  // Copy with method for updates
  ProductVariant copyWith({
    int? id,
    int? productId,
    String? name,
    int? quantity,
    double? sellPrice,
    double? buyPrice,
    String? barcode,
  }) {
    return ProductVariant(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      sellPrice: sellPrice ?? this.sellPrice,
      buyPrice: buyPrice ?? this.buyPrice,
      barcode: barcode ?? this.barcode,
    );
  }

  // Check if variant is low stock (less than 5)
  bool get isLowStock => quantity < 5;

  // Check if variant is out of stock
  bool get isOutOfStock => quantity <= 0;

  // Check if variant has barcode
  bool get hasBarcode => barcode != null && barcode!.isNotEmpty;
}
