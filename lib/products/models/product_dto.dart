import 'package:equatable/equatable.dart';

class ProductDto extends Equatable {
  final String id;
  final String title;
  final String description;
  final double price;
  final String category;
  final bool active;
  final String condition;
  final String? imageUrl;
  final String? sellerName;

  const ProductDto({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.category,
    required this.active,
    required this.condition,
    this.imageUrl,
    this.sellerName,
  });

  bool get isSold => !active;

  ProductDto copyWith({
    String? id,
    String? title,
    String? description,
    double? price,
    String? category,
    bool? active,
    String? condition,
    String? imageUrl,
    String? sellerName,
  }) {
    return ProductDto(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      category: category ?? this.category,
      active: active ?? this.active,
      condition: condition ?? this.condition,
      imageUrl: imageUrl ?? this.imageUrl,
      sellerName: sellerName ?? this.sellerName,
    );
  }

  factory ProductDto.fromListingJson(Map<String, dynamic> json) {
    String? resolvedImageUrl;
    final images = json['images'];
    if (images is List && images.isNotEmpty) {
      final first = images.first;
      if (first is Map<String, dynamic>) {
        resolvedImageUrl = first['url'] as String?;
      }
    }

    String? resolvedSellerName;
    final seller = json['seller'];
    if (seller is Map<String, dynamic>) {
      final user = seller['user'];
      if (user is Map<String, dynamic>) {
        final name = (user['name'] ?? '').toString().trim();
        final lastName = (user['last_name'] ?? '').toString().trim();
        final fullName = '$name $lastName'.trim();
        resolvedSellerName = fullName.isEmpty ? null : fullName;
      }
    }

    return ProductDto(
      id: json['id'].toString(),
      title: (json['title'] ?? '').toString(),
      description: (json['product'] ?? '').toString(),
      price: (json['selling_price'] as num?)?.toDouble() ?? 0,
      category: (json['category'] ?? 'other').toString(),
      active: json['active'] as bool? ?? true,
      condition: (json['condition'] ?? 'good').toString(),
      imageUrl: json['image_url'] as String? ?? resolvedImageUrl,
      sellerName: resolvedSellerName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'product': description,
      'selling_price': price,
      'category': category,
      'active': active,
      'condition': condition,
      'image_url': imageUrl,
      'sellerName': sellerName,
    };
  }

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    price,
    category,
    active,
    condition,
    imageUrl,
    sellerName,
  ];
}