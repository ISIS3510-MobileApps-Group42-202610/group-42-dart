import 'package:equatable/equatable.dart';

// esta nueva clase es el DTO de image del backend
class ProductImageDto extends Equatable {
  final int id;
  final String url;
  final bool isPrimary;
  final int sortOrder;

  const ProductImageDto({
    required this.id,
    required this.url,
    this.isPrimary = false,
    this.sortOrder = 0,
  });

  factory ProductImageDto.fromJson(Map<String, dynamic> json) {
    return ProductImageDto(
      id: json['id'] as int,
      url: (json['url'] ?? '').toString(),
      isPrimary: json['is_primary'] as bool? ?? false,
      sortOrder: json['sort_order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'is_primary': isPrimary,
      'sort_order': sortOrder,
    };
  }

  @override
  List<Object?> get props => [id, url, isPrimary, sortOrder];
}

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
  final List<ProductImageDto> images; // nueva propiedad de images

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
    this.images = const [], // nueva propiedad de images
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
    List<ProductImageDto>? images, // imagesss
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
      images: images ?? this.images, // imagess xd
    );
  }

  factory ProductDto.fromListingJson(Map<String, dynamic> json) {
    String? resolvedImageUrl;
    final List<ProductImageDto> parsedImages = [];

    final images = json['images'];
    if (images is List && images.isNotEmpty) {
      for (final img in images) {
        // extraer las images del json
        if (img is Map<String, dynamic>) {
          parsedImages.add(ProductImageDto.fromJson(img));
        }
      }
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

    // fallback para el seller name
    resolvedSellerName ??= (json['seller_name'] as String?)?.trim();

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
      images: parsedImages, // imagesss
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
      // agregar el seller
      'seller_name': sellerName,
      'images': images.map((image) => image.toJson()).toList(),
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
    images, // imagess
  ];
}
