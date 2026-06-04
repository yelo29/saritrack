class Customer {
  final int? id;
  final String name;
  final String? contact;
  final String? address;
  final double creditLimit;
  final double currentBalance;

  Customer({
    this.id,
    required this.name,
    this.contact,
    this.address,
    this.creditLimit = 0,
    this.currentBalance = 0,
  });

  // Convert to map for database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'contact': contact,
      'address': address,
      'credit_limit': creditLimit,
      'current_balance': currentBalance,
    };
  }

  // Create from map from database
  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'] as int?,
      name: map['name'] as String,
      contact: map['contact'] as String?,
      address: map['address'] as String?,
      creditLimit: map['credit_limit'] as double? ?? 0,
      currentBalance: map['current_balance'] as double? ?? 0,
    );
  }

  // Copy with method for updates
  Customer copyWith({
    int? id,
    String? name,
    String? contact,
    String? address,
    double? creditLimit,
    double? currentBalance,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      contact: contact ?? this.contact,
      address: address ?? this.address,
      creditLimit: creditLimit ?? this.creditLimit,
      currentBalance: currentBalance ?? this.currentBalance,
    );
  }
}
