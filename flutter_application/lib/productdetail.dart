class Product {
  final String? id;
  final String? name;
  final double? price;
  final int? inStock;
  final List<String>? images;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.inStock,
    required this.images,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String?,
      name: json['name'] as String?,
      price: (json['price'] as num?)?.toDouble(),
      inStock: json['inStock'] as int?,
      images: List<String>.from(json['images'] as Iterable),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['id'] = id;
    data['name'] = name;
    data['price'] = price;
    data['inStock'] = inStock;
    data['images'] = images;
    return data;
  }
}
