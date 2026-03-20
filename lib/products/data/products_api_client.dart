import 'package:dio/dio.dart';
import '../models/product_dto.dart';

class ProductsApiClient {
  final Dio dio;

  ProductsApiClient({required this.dio});

  Future<List<ProductDto>> getPublicListings() async {
    final response = await dio.get('/listings');
    final data = response.data;

    if (data is List) {
      return data
          .map((item) => ProductDto.fromListingJson(item as Map<String, dynamic>))
          .toList();
    }

    if (data is Map<String, dynamic> && data['data'] is List) {
      return (data['data'] as List)
          .map((item) => ProductDto.fromListingJson(item as Map<String, dynamic>))
          .toList();
    }

    throw Exception('Invalid public listings response format.');
  }

  Future<void> buyProduct(String productId) async {
    // Intentamos convertir a int para evitar el error "numeric string is expected"
    final dynamic numericId = int.tryParse(productId) ?? productId;

    await dio.post('/transactions', data: {
      'listing_id': numericId, 
    });
  }


  Future<List<ProductDto>> getMyProducts() async {
    final response = await dio.get('/listings/my');
    final data = response.data;

    if (data is Map<String, dynamic>) {
      final active = (data['active'] as List<dynamic>? ?? []);
      final sold = (data['sold'] as List<dynamic>? ?? []);
      final all = [...active, ...sold];

      return all
          .map(
            (item) => ProductDto.fromListingJson(
          item as Map<String, dynamic>,
        ),
      )
          .toList();
    }

    throw Exception('Invalid my listings response format.');
  }

  Future<ProductDto> createProduct({
    required String title,
    required String description,
    required double price,
    required String category,
    required String condition,
  }) async {
    final response = await dio.post(
      '/listings',
      data: {
        'title': title,
        'product': description,
        'category': _mapCategory(category),
        'condition': _mapCondition(condition),
        'selling_price': price,
      },
    );

    final data = response.data;
    if (data is Map<String, dynamic>) {
      return ProductDto.fromListingJson(data);
    }

    throw Exception('Invalid create listing response format.');
  }

  Future<ProductDto> updateProduct({
    required String productId,
    required String title,
    required String description,
    required double price,
    required String category,
    required String condition,
  }) async {
    final response = await dio.patch(
      '/listings/$productId',
      data: {
        'title': title,
        'product': description,
        'category': _mapCategory(category),
        'condition': _mapCondition(condition),
        'selling_price': price,
      },
    );

    final data = response.data;
    if (data is Map<String, dynamic>) {
      return ProductDto.fromListingJson(data);
    }

    throw Exception('Invalid update listing response format.');
  }

  Future<void> deleteProduct(String productId) async {
    await dio.delete('/listings/$productId');
  }

  Future<ProductDto> markAsSold(String productId) async {
    final response = await dio.patch(
      '/listings/$productId',
      data: {'active': false},
    );

    final data = response.data;
    if (data is Map<String, dynamic>) {
      return ProductDto.fromListingJson(data);
    }

    throw Exception('Invalid mark as sold response format.');
  }

  Future<ProductDto> markAsAvailable(String productId) async {
    final response = await dio.patch(
      '/listings/$productId',
      data: {'active': true},
    );

    final data = response.data;
    if (data is Map<String, dynamic>) {
      return ProductDto.fromListingJson(data);
    }

    throw Exception('Invalid mark as available response format.');
  }

  String _mapCategory(String uiCategory) {
    switch (uiCategory.toLowerCase()) {
      case 'books':
        return 'textbook';
      case 'electronics':
        return 'electronics';
      case 'other':
        return 'other';
      default:
        return 'other';
    }
  }

  String _mapCondition(String uiCondition) {
    switch (uiCondition.toLowerCase()) {
      case 'new':
        return 'new';
      case 'like new':
        return 'like_new';
      case 'good':
        return 'good';
      case 'fair':
        return 'fair';
      default:
        return 'good';
    }
  }
}
