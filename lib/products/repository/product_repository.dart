import 'package:dio/dio.dart';
import '../data/products_api_client.dart';
import '../models/product_dto.dart';

class ProductRepository {
  final ProductsApiClient apiClient;

  ProductRepository({required this.apiClient});

  Future<List<ProductDto>> getPublicListings() async {
    return apiClient.getPublicListings();
  }

  Future<List<ProductDto>> getSellerProducts() async {
    return apiClient.getMyProducts();
  }

  Future<ProductDto> createProduct({
    required String title,
    required String description,
    required double price,
    required String category,
  }) async {
    return apiClient.createProduct(
      title: title,
      description: description,
      price: price,
      category: category,
    );
  }

  Future<ProductDto> updateProduct({
    required String productId,
    required String title,
    required String description,
    required double price,
    required String category,
  }) async {
    return apiClient.updateProduct(
      productId: productId,
      title: title,
      description: description,
      price: price,
      category: category,
    );
  }

  Future<void> deleteProduct(String productId) async {
    return apiClient.deleteProduct(productId);
  }

  Future<ProductDto> markProductAsSold(String productId) async {
    return apiClient.markAsSold(productId);
  }

  Future<ProductDto> markProductAsAvailable(String productId) async {
    return apiClient.markAsAvailable(productId);
  }

  String extractMessage(Object error) {
    if (error is DioException) {
      final response = error.response;

      if (response != null) {
        final data = response.data;

        if (data is Map) {
          final message = data['message'];
          if (message is List) return message.join('\n');
          if (message is String) return message;
        }

        if (data is String && data.isNotEmpty) {
          return data;
        }

        switch (response.statusCode) {
          case 400:
            return 'Invalid listing request.';
          case 401:
            return 'Unauthorized. Please log in again.';
          case 403:
            return 'You do not have permission to perform this action.';
          case 404:
            return 'Listing not found.';
          default:
            return 'Server error (${response.statusCode}). Please try again.';
        }
      }

      return 'Connection error. Please check your internet connection.';
    }

    return 'An unexpected error occurred.';
  }
}