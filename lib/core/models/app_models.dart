class User {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? position;
  final String? station;
  final String? avatar;
  final DateTime? joinDate;
  final String? address;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.position,
    this.station,
    this.avatar,
    this.joinDate,
    this.address,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['user_id'] ?? json['id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      position: json['position'],
      station: json['station'],
      avatar: json['avatar'],
      joinDate: json['join_date'] != null 
          ? DateTime.parse(json['join_date']) 
          : null,
      address: json['address'],
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'position': position,
      'station': station,
      'avatar': avatar,
      'join_date': joinDate?.toIso8601String(),
      'address': address,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? position,
    String? station,
    String? avatar,
    DateTime? joinDate,
    String? address,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      position: position ?? this.position,
      station: station ?? this.station,
      avatar: avatar ?? this.avatar,
      joinDate: joinDate ?? this.joinDate,
      address: address ?? this.address,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class Sale {
  final String id;
  final String userId;
  final String? customerName;
  final String fuelType;
  final double quantity;
  final double pricePerLiter;
  final double totalAmount;
  final String? paymentMethod;
  final DateTime saleDate;
  final DateTime createdAt;
  final bool synced;

  Sale({
    required this.id,
    required this.userId,
    this.customerName,
    required this.fuelType,
    required this.quantity,
    required this.pricePerLiter,
    required this.totalAmount,
    this.paymentMethod,
    required this.saleDate,
    required this.createdAt,
    this.synced = false,
  });

  factory Sale.fromJson(Map<String, dynamic> json) {
    return Sale(
      id: json['sale_id'] ?? json['id'],
      userId: json['user_id'],
      customerName: json['customer_name'],
      fuelType: json['fuel_type'],
      quantity: (json['quantity'] as num).toDouble(),
      pricePerLiter: (json['price_per_liter'] as num).toDouble(),
      totalAmount: (json['total_amount'] as num).toDouble(),
      paymentMethod: json['payment_method'],
      saleDate: DateTime.parse(json['sale_date']),
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      synced: (json['synced'] ?? 0) == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sale_id': id,
      'user_id': userId,
      'customer_name': customerName,
      'fuel_type': fuelType,
      'quantity': quantity,
      'price_per_liter': pricePerLiter,
      'total_amount': totalAmount,
      'payment_method': paymentMethod,
      'sale_date': saleDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'synced': synced ? 1 : 0,
    };
  }
}

class Inventory {
  final String fuelType;
  final double currentStock;
  final double minimumStock;
  final double maximumCapacity;
  final DateTime lastUpdated;
  final String stationId;
  final DateTime createdAt;

  Inventory({
    required this.fuelType,
    required this.currentStock,
    required this.minimumStock,
    required this.maximumCapacity,
    required this.lastUpdated,
    required this.stationId,
    required this.createdAt,
  });

  factory Inventory.fromJson(Map<String, dynamic> json) {
    return Inventory(
      fuelType: json['fuel_type'],
      currentStock: (json['current_stock'] as num).toDouble(),
      minimumStock: (json['minimum_stock'] as num).toDouble(),
      maximumCapacity: (json['maximum_capacity'] as num).toDouble(),
      lastUpdated: DateTime.parse(json['last_updated']),
      stationId: json['station_id'],
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fuel_type': fuelType,
      'current_stock': currentStock,
      'minimum_stock': minimumStock,
      'maximum_capacity': maximumCapacity,
      'last_updated': lastUpdated.toIso8601String(),
      'station_id': stationId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  double get stockPercentage => (currentStock / maximumCapacity) * 100;
  bool get isLowStock => currentStock <= minimumStock;
  bool get isCriticalStock => currentStock <= (minimumStock * 0.5);
}

class Activity {
  final String id;
  final String type;
  final String title;
  final String? description;
  final String? userId;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  Activity({
    required this.id,
    required this.type,
    required this.title,
    this.description,
    this.userId,
    required this.timestamp,
    this.metadata,
    required this.createdAt,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['activity_id'] ?? json['id'],
      type: json['type'],
      title: json['title'],
      description: json['description'],
      userId: json['user_id'],
      timestamp: DateTime.parse(json['timestamp']),
      metadata: json['metadata'] != null 
          ? Map<String, dynamic>.from(json['metadata']) 
          : null,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'activity_id': id,
      'type': type,
      'title': title,
      'description': description,
      'user_id': userId,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

enum FuelType {
  essence('Essence'),
  diesel('Diesel'),
  superFuel('Super'),
  premium('Premium'),
  sansPlomb('Sans Plomb');

  const FuelType(this.displayName);
  final String displayName;
}

enum PaymentMethod {
  cash('Espèces'),
  card('Carte'),
  credit('Crédit'),
  mobile('Mobile');

  const PaymentMethod(this.displayName);
  final String displayName;
}

enum ActivityType {
  sale('sale'),
  delivery('delivery'),
  inventory('inventory'),
  user('user'),
  system('system');

  const ActivityType(this.value);
  final String value;
}
