import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../data/products_api_client.dart';
import '../data/listings_cache.dart';
import '../../services/connectivity_service.dart';
import '../models/product_dto.dart';
import '../models/chat_message.dart';

class ProductRepository {
  final ProductsApiClient apiClient;
  final ListingsCache listingsCache;
  final ConnectivityService connectivityService;

  ProductRepository({
    required this.apiClient,
    required this.listingsCache,
    required this.connectivityService,
  });

  Future<List<ProductDto>> getPublicListings() async {
    // verificar si hay conexión antes de hacer la petición
    final isOnline = await connectivityService.isConnected;
    if (!isOnline) {
      final cachedListings = await listingsCache.getCachedPublicListings();
      if (cachedListings != null && cachedListings.isNotEmpty) {
        final stale = await listingsCache.isCacheStale(isPublic: true);
        throw CacheException(
          stale ? 'App offline - showing cached data older than 5 minutes.' : 'Connection lost.',
          cachedListings: cachedListings,
        );
      }
      throw _offlineDioException('/listings');
    }

    try {
      final listings = await apiClient.getPublicListings();
      // cachear el resultado
      await listingsCache.cachePublicListings(listings);
      return listings;
    } catch (e) {
      if (isUnauthorizedError(e)) {
        rethrow;
      }

      // Si hay error, obtener las listings cacheadas para mostrar al usuario, indicando que es un error de conexión
      final cachedListings = await listingsCache.getCachedPublicListings();
      if (cachedListings != null && cachedListings.isNotEmpty) {
        final stale = await listingsCache.isCacheStale(isPublic: true);
        throw CacheException(
          stale ? 'App offline - showing cached data older than 5 minutes.' : 'Connection lost.',
          cachedListings: cachedListings,
        );
      }
      // Si no hay cache, retornar el error original
      rethrow;
    }
  }

  Future<List<ProductDto>> getSellerProducts() async {
    // verificar si hay conexión antes de hacer la petición
    final isOnline = await connectivityService.isConnected;
    if (!isOnline) {
      final cachedListings = await listingsCache.getCachedSellerListings();
      if (cachedListings != null && cachedListings.isNotEmpty) {
        final stale = await listingsCache.isCacheStale(isPublic: false);
        throw CacheException(
          stale ? 'App offline - showing cached data older than 5 minutes.' : 'Connection lost.',
          cachedListings: cachedListings,
        );
      }
      throw _offlineDioException('/listings/my');
    }

    // implementacion de cache
    try {
      final listings = await apiClient.getMyProducts();
      // meter en cache los listings
      await listingsCache.cacheSellerListings(listings);
      return listings;
    } catch (e) {
      // Si el error es de autenticación, rethrow para que el bloc maneje el logout
      if (isUnauthorizedError(e)) {
        rethrow;
      }

      // Si hay error (no hay conexión, mostrar al usuario)
      final cachedListings = await listingsCache.getCachedSellerListings();
      if (cachedListings != null && cachedListings.isNotEmpty) {
        final stale = await listingsCache.isCacheStale(isPublic: false);
        throw CacheException(
          stale ? 'App offline - showing cached data older than 5 minutes.' : 'Connection lost.',
          cachedListings: cachedListings,
        );
      }
      // Si no hay cache, rethrow el error original para mostrar mensaje de error
      rethrow;
    }
  }

  Future<ProductDto> createProduct({
    required String title,
    required String description,
    required double price,
    required String category,
    required String condition,
    required List<String> imageUrls,
  }) async {
    return apiClient.createProduct(
      title: title,
      description: description,
      price: price,
      category: category,
      condition: condition,
      imageUrls: imageUrls,
    );
  }

  Future<ProductDto> updateProduct({
    required String productId,
    required String title,
    required String description,
    required double price,
    required String category,
    required String condition,
    List<String>? newImageUrls,
    List<int>? removedImageIds,
  }) async {
    return apiClient.updateProduct(
      productId: productId,
      title: title,
      description: description,
      price: price,
      category: category,
      condition: condition,
      newImageUrls: newImageUrls,
      removedImageIds: removedImageIds,
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

  // subir las fotos a cloudinary, obtener el url de cada foto
  Future<List<String>> uploadImages(List<File> imageFiles) async {
    final imagePaths = imageFiles.map((file) => file.path).toList();

    return compute(
      uploadImagesOnIsolate,
      CloudinaryUploadPayload(
        imagePaths: imagePaths,
        baseUrl: apiClient.dio.options.baseUrl,
        authToken: apiClient.dio.options.headers['Authorization']?.toString(),
      ),
    );
  }

  Future<void> buyProduct(String productId) async {
    return apiClient.buyProduct(productId);
  }

  // --- CHATS ---

  Future<List<ChatMessage>> getConversations() async {
    final data = await apiClient.getConversations();
    return data.map((json) {
      return ChatMessage(
        productId: (json['product_id'] ?? json['listing_id'] ?? '').toString(),
        // agregar el nombre del seller
        sellerName:
            (json['seller_name'] ?? json['other_user_name'] ?? 'Unknown')
                .toString(),
        lastMessage: (json['last_message'] ?? '').toString(),
      );
    }).toList();
  }

  Future<List<String>> getMessages(String productId) async {
    final data = await apiClient.getMessages(productId);
    return data.map((json) => (json['content'] ?? '').toString()).toList();
  }

  Future<void> sendMessage(String productId, String content) async {
    return apiClient.sendMessage(productId, content);
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

  // Verificar si el error es de autenticación
  bool isUnauthorizedError(Object error) {
    return error is DioException && error.response?.statusCode == 401;
  }

  DioException _offlineDioException(String path) {
    return DioException(
      requestOptions: RequestOptions(path: path),
      type: DioExceptionType.connectionError,
      error: 'No internet connection.',
    );
  }
}

// Excepción de conexión (se muestra en un snackbar)
class CacheException implements Exception {
  final String message;
  final List<ProductDto> cachedListings;

  CacheException(this.message, {required this.cachedListings});

  @override
  String toString() => message;
}

class CloudinaryUploadPayload {
  final List<String> imagePaths;
  final String baseUrl;
  final String? authToken;

  CloudinaryUploadPayload({
    required this.imagePaths,
    required this.baseUrl,
    required this.authToken,
  });
}

Future<List<String>> uploadImagesOnIsolate(
    CloudinaryUploadPayload payload,
    ) async {
  final dio = Dio(
    BaseOptions(
      baseUrl: payload.baseUrl,
      headers: {
        if (payload.authToken != null) 'Authorization': payload.authToken,
      },
    ),
  );

  final apiClient = ProductsApiClient(dio: dio);
  final urls = <String>[];

  for (final path in payload.imagePaths) {
    final url = await apiClient.uploadImageToCloudinary(File(path));
    urls.add(url);
  }

  return urls;
}
