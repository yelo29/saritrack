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
  final String? barcode;
  final String? discountType; // 'percentage' or 'fixed'
  final double discountValue;
  final double vatRate; // VAT rate as percentage (e.g., 12 for 12%)

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
    this.barcode,
    this.discountType,
    this.discountValue = 0,
    this.vatRate = 0,
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
      'barcode': barcode,
      'discount_type': discountType,
      'discount_value': discountValue,
      'vat_rate': vatRate,
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
      barcode: map['barcode'] as String?,
      discountType: map['discount_type'] as String?,
      discountValue: (map['discount_value'] as num?)?.toDouble() ?? 0,
      vatRate: (map['vat_rate'] as num?)?.toDouble() ?? 0,
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
    String? barcode,
    String? discountType,
    double? discountValue,
    double? vatRate,
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
      barcode: barcode ?? this.barcode,
      discountType: discountType ?? this.discountType,
      discountValue: discountValue ?? this.discountValue,
      vatRate: vatRate ?? this.vatRate,
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

  // Check if product has a discount
  bool get hasDiscount {
    return discountType != null && discountValue > 0;
  }

  // Get the discounted price
  double get discountedPrice {
    if (!hasDiscount) return sellPrice;
    
    if (discountType == 'percentage') {
      return sellPrice - (sellPrice * (discountValue / 100));
    } else if (discountType == 'fixed') {
      return sellPrice - discountValue;
    }
    
    return sellPrice;
  }

  // Get the discount amount
  double get discountAmount {
    return sellPrice - discountedPrice;
  }

  // Check if product has VAT
  bool get hasVat {
    return vatRate > 0;
  }

  // Get the VAT amount for the discounted price
  double get vatAmount {
    if (!hasVat) return 0;
    return discountedPrice * (vatRate / 100);
  }

  // Get the price including VAT (VAT-inclusive pricing)
  double get priceWithVat {
    return discountedPrice + vatAmount;
  }

  // Get the price excluding VAT (for VAT-exclusive pricing)
  double get priceWithoutVat {
    if (!hasVat) return discountedPrice;
    return discountedPrice / (1 + (vatRate / 100));
  }
}
