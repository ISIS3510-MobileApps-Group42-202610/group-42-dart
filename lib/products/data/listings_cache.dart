import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import '../models/product_dto.dart';

class ListingsCache {
  static const String publicListingsKey = 'cached_public_listings';
  static const String sellerListingsKey = 'cached_seller_listings';
  static const Duration staleAfter = Duration(minutes: 5); // verificar si el cache es reciente

  static final CacheManager cacheManager = CacheManager(
    Config(
      'listings_cache_manager',
      stalePeriod: staleAfter,
      maxNrOfCacheObjects: 2,
    ),
  );

  bool initialized = false;

  Future<void> init() async {
    initialized = true;
  }

  // cachear las listings
  Future<void> cachePublicListings(List<ProductDto> listings) async {
    await cacheListings(listings: listings, listingsKey: publicListingsKey);
  }

  // cachear las listings del seller
  Future<void> cacheSellerListings(List<ProductDto> listings) async {
    await cacheListings(listings: listings, listingsKey: sellerListingsKey);
  }

  // obtener las listings cacheadas
  Future<List<ProductDto>?> getCachedPublicListings() async {
    return getCachedListings(publicListingsKey);
  }

  // obtener las listings cacheadas del seller
  Future<List<ProductDto>?> getCachedSellerListings() async {
    return getCachedListings(sellerListingsKey);
  }

  // obtener el timestamp de la última vez que se hizo fetch, para saber si el cache es reciente o no
  Future<DateTime?> getLastFetchTime({required bool isPublic}) async {
    final key = isPublic ? publicListingsKey : sellerListingsKey;
    final payload = await readPayload(key);
    if (payload == null) return null;

    final fetchedAt = payload['fetchedAt'];
    if (fetchedAt is String && fetchedAt.isNotEmpty) {
      return DateTime.tryParse(fetchedAt);
    }

    return null;
  }

  // borrar el cache de las listings públicas
  Future<void> clearPublicListingsCache() async {
    await cacheManager.removeFile(publicListingsKey);
  }

  // borrar el cache de las listings del seller
  Future<void> clearSellerListingsCache() async {
    await cacheManager.removeFile(sellerListingsKey);
  }

  // borrar el cache de las listings, se llama al cerrar sesión para evitar problemas con los datos del usuario anterior
  Future<void> clearSessionCache() async {
    await cacheManager.emptyCache();
  }

  // función genérica para cachear listings, recibe las keys para el cache y el timestamp
  Future<void> cacheListings({
    required List<ProductDto> listings,
    required String listingsKey,
  }) async {
    try {
      final payload = <String, dynamic>{
        'fetchedAt': DateTime.now().toIso8601String(),
        'listings': listings.map((p) => p.toJson()).toList(),
      };

      await cacheManager.putFile(
        listingsKey,
        Uint8List.fromList(utf8.encode(jsonEncode(payload))),
        fileExtension: 'json',
      );
    } catch (e) {
      print('Error caching listings ($listingsKey): $e');
    }
  }

  // verificar si el cache es reciente o no
  bool isStale(String? fetchedAtIso) {
    if (fetchedAtIso == null) return true;
    final fetchedAt = DateTime.tryParse(fetchedAtIso);
    if (fetchedAt == null) return true;
    return DateTime.now().difference(fetchedAt) >= staleAfter;
  }

  // Convenience method so the repository can check staleness without reading the payload twice
  Future<bool> isCacheStale({required bool isPublic}) async {
    final lastFetch = await getLastFetchTime(isPublic: isPublic);
    return isStale(lastFetch?.toIso8601String());
  }

  // función genérica para obtener listings cacheadas, recibe la key del cache
  // Always returns cached data regardless of age — callers decide what to do with stale data.
  Future<List<ProductDto>?> getCachedListings(String key) async {
    try {
      final payload = await readPayload(key);
      if (payload == null) return null;

      final rawListings = payload['listings'];
      if (rawListings is! List || rawListings.isEmpty) return null;

      return rawListings
          .map(
            (item) => ProductDto.fromListingJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
    } catch (e) {
      print('Error retrieving cached listings ($key): $e');
      return null;
    }
  }

  // Funcion para leer el payload en cache
  Future<Map<String, dynamic>?> readPayload(String key) async {
    final fileInfo = await cacheManager.getFileFromCache(key);
    if (fileInfo == null) return null;

    final jsonStr = await fileInfo.file.readAsString();
    if (jsonStr.isEmpty) return null;

    final decoded = jsonDecode(jsonStr);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
    return null;
  }
}
