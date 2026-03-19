import 'dart:io';

import 'package:dio/dio.dart';
import '../models/product_dto.dart';

class ProductsApiClient {
  final Dio dio;

  ProductsApiClient({required this.dio});

  // Liostings

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
    required List<String> imageUrls, // nuevo item de image urls
  }) async {
    final images = imageUrls.asMap().entries.map((e) => { // mappear las images
      'url': e.value,
      'is_primary': e.key == 0,
      'sort_order': e.key,
    }).toList();

    final response = await dio.post(
      '/listings',
      data: {
        'title': title,
        'product': description,
        'category': _mapCategory(category),
        'condition': _mapCondition(condition),
        'selling_price': price,
        'images': images,
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
    List<String>? newImageUrls,
    List<int>? removedImageIds,
  }) async {
    final body = <String, dynamic>{
      'title': title,
      'product': description,
      'category': _mapCategory(category),
      'condition': _mapCondition(condition),
      'selling_price': price,
    };

    // poder actualizar las images
    if (newImageUrls != null && newImageUrls.isNotEmpty) {
      body['images'] = newImageUrls.map((url) => {'url': url}).toList();
    }

    if (removedImageIds != null && removedImageIds.isNotEmpty) {
      body['removed_image_ids'] = removedImageIds;
    }

    final response = await dio.patch(
      '/listings/$productId',
      data: body,
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

  // Cloudinary (lo de las fotos xd)

  // Request de la firma para el upload a cloudinary
  Future<Map<String, dynamic>> getCloudinarySignature({
    String? folder,
  }) async {
    final response = await dio.post(
      '/uploads/cloudinary-signature',
      data: {
        if (folder != null) 'folder': folder,
      },
    );

    final data = response.data;
    if (data is Map<String, dynamic>) return data;

    throw Exception('Invalid cloudinary signature response.');
  }

  // Directamente subir la img a cloudinary (firmado por el back)
  Future<String> uploadImageToCloudinary(File imageFile) async {
    final sig = await getCloudinarySignature(folder: 'unimarket/listings'); // obtener firma antes de subir

    // extraer datos de la firma por el back
    final cloudName = sig['cloud_name'] ?? sig['cloudName'];
    final apiKey = sig['api_key'] ?? sig['apiKey'];
    final timestamp = sig['timestamp'];
    final signature = sig['signature'];
    final folder = sig['folder'];

    final uploadDio = Dio();
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        imageFile.path,
        filename: imageFile.path.split('/').last,
      ),
      'api_key': apiKey,
      'timestamp': timestamp,
      'signature': signature,
      if (folder != null) 'folder': folder,
    });

    final uploadResponse = await uploadDio.post(
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
      data: formData,
    );

    final uploadData = uploadResponse.data;
    if (uploadData is Map<String, dynamic>) {
      return (uploadData['secure_url'] ?? uploadData['url']) as String;
    }

    throw Exception('Invalid Cloudinary upload response.');
  }

  // Categoria y condiciom

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
