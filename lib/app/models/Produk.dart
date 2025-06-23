
class Product {
  final int? id;
  final String name;
  final double price;
  final int stock;
  final String description;
  final String imageUrl;
  final String? createdAt;
  final String? updatedAt;

  Product({
    this.id,
    required this.name,
    required this.price,
    required this.stock,
    required this.description,
    required this.imageUrl,
    this.createdAt,
    this.updatedAt,
  });

  // Convert Product to Map untuk database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'stock': stock,
      'description': description,
      'image_url': imageUrl,
      'created_at': createdAt ?? DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  // Convert Map to Product dari database
  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      name: map['name'],
      price: map['price'].toDouble(),
      stock: map['stock'],
      description: map['description'],
      imageUrl: map['image_url'],
      createdAt: map['created_at'],
      updatedAt: map['updated_at'],
    );
  }

  // Copy dengan perubahan
  Product copyWith({
    int? id,
    String? name,
    double? price,
    int? stock,
    String? description,
    String? imageUrl,
    String? createdAt,
    String? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Product{id: $id, name: $name, price: $price, stock: $stock}';
  }
}
