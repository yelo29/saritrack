class Supplier {
  final int? id;
  final String name;
  final String? contact;
  final String? address;
  final String? lastRestockDate;

  Supplier({
    this.id,
    required this.name,
    this.contact,
    this.address,
    this.lastRestockDate,
  });

  // Convert to map for database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'contact': contact,
      'address': address,
      'last_restock_date': lastRestockDate,
    };
  }

  // Create from map from database
  factory Supplier.fromMap(Map<String, dynamic> map) {
    return Supplier(
      id: map['id'] as int?,
      name: map['name'] as String,
      contact: map['contact'] as String?,
      address: map['address'] as String?,
      lastRestockDate: map['last_restock_date'] as String?,
    );
  }

  // Copy with method for updates
  Supplier copyWith({
    int? id,
    String? name,
    String? contact,
    String? address,
    String? lastRestockDate,
  }) {
    return Supplier(
      id: id ?? this.id,
      name: name ?? this.name,
      contact: contact ?? this.contact,
      address: address ?? this.address,
      lastRestockDate: lastRestockDate ?? this.lastRestockDate,
    );
  }
}
