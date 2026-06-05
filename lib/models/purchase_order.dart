class PurchaseOrder {
  final int? id;
  final int? supplierId;
  final int productId;
  final int quantity;
  final double buyPrice;
  final double totalCost;
  final String? deliveryDate;
  final String status;
  final String? notes;
  final String createdAt;
  final int? notificationId;

  PurchaseOrder({
    this.id,
    this.supplierId,
    required this.productId,
    required this.quantity,
    required this.buyPrice,
    required this.totalCost,
    this.deliveryDate,
    this.status = 'pending',
    this.notes,
    required this.createdAt,
    this.notificationId,
  });

  // Convert to map for database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'supplier_id': supplierId,
      'product_id': productId,
      'quantity': quantity,
      'buy_price': buyPrice,
      'total_cost': totalCost,
      'delivery_date': deliveryDate,
      'status': status,
      'notes': notes,
      'created_at': createdAt,
      'notification_id': notificationId,
    };
  }

  // Create from map from database
  factory PurchaseOrder.fromMap(Map<String, dynamic> map) {
    return PurchaseOrder(
      id: map['id'] as int?,
      supplierId: map['supplier_id'] as int?,
      productId: map['product_id'] as int,
      quantity: map['quantity'] as int,
      buyPrice: (map['buy_price'] as num).toDouble(),
      totalCost: (map['total_cost'] as num).toDouble(),
      deliveryDate: map['delivery_date'] as String?,
      status: map['status'] as String? ?? 'pending',
      notes: map['notes'] as String?,
      createdAt: map['created_at'] as String,
      notificationId: map['notification_id'] as int?,
    );
  }

  // Copy with method for updates
  PurchaseOrder copyWith({
    int? id,
    int? supplierId,
    int? productId,
    int? quantity,
    double? buyPrice,
    double? totalCost,
    String? deliveryDate,
    String? status,
    String? notes,
    String? createdAt,
    int? notificationId,
  }) {
    return PurchaseOrder(
      id: id ?? this.id,
      supplierId: supplierId ?? this.supplierId,
      productId: productId ?? this.productId,
      quantity: quantity ?? this.quantity,
      buyPrice: buyPrice ?? this.buyPrice,
      totalCost: totalCost ?? this.totalCost,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      notificationId: notificationId ?? this.notificationId,
    );
  }

  // Check if order is pending
  bool get isPending => status == 'pending';

  // Check if order is delivered
  bool get isDelivered => status == 'delivered';

  // Check if order is cancelled
  bool get isCancelled => status == 'cancelled';

  // Check if order has a delivery date
  bool get hasDeliveryDate => deliveryDate != null && deliveryDate!.isNotEmpty;

  // Check if delivery is approaching (within 2 days)
  bool get isDeliveryApproaching {
    if (!hasDeliveryDate) return false;
    final delivery = DateTime.parse(deliveryDate!);
    final now = DateTime.now();
    final difference = delivery.difference(now).inDays;
    return difference >= 0 && difference <= 2;
  }

  // Check if delivery is overdue
  bool get isDeliveryOverdue {
    if (!hasDeliveryDate) return false;
    final delivery = DateTime.parse(deliveryDate!);
    final now = DateTime.now();
    return delivery.isBefore(now) && isPending;
  }
}
