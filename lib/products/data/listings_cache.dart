import 'dart:convert';
import 'package:hive/hive.dart';
import '../models/product_dto.dart';

class ListingsCache {
  static const String boxName = 'listings_cache_box';
  static const String publicListingsKey = 'cached_public_listings';
  static const String sellerListingsKey = 'cached_seller_listings';
  static const String publicLastFetchKey = 'public_listings_fetch_time';
  static const String sellerLastFetchKey = 'seller_listings_fetch_time';

  // late es una variable que no puede ser null, pero se inicializará despúes
  late Box<dynamic> box;
  bool initialized = false;

  // inicializar el cache con Hive, una sola vez (singleton esencialmente)
  Future<void> init() async {
    if (initialized) return;

    if (Hive.isBoxOpen(boxName)) {
      box = Hive.box<dynamic>(boxName);
    } else {
      box = await Hive.openBox<dynamic>(boxName);
    }

    initialized = true;
  }

  // cachear las listings
  Future<void> cachePublicListings(List<ProductDto> listings) async {
    await cacheListings(
      listings: listings,
      listingsKey: publicListingsKey,
      timestampKey: publicLastFetchKey,
    );
  }

  // cachear las listings del seller
  Future<void> cacheSellerListings(List<ProductDto> listings) async {
    await cacheListings(
      listings: listings,
      listingsKey: sellerListingsKey,
      timestampKey: sellerLastFetchKey,
    );
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
    if (!initialized) await init();

    final key = isPublic ? publicLastFetchKey : sellerLastFetchKey;
    final timestampMs = box.get(key);
    if (timestampMs is int) {
      return DateTime.fromMillisecondsSinceEpoch(timestampMs);
    }

    return null;
  }

  // borrar el cache de las listings públicas
  Future<void> clearPublicListingsCache() async {
    if (!initialized) await init();
    await box.delete(publicListingsKey);
    await box.delete(publicLastFetchKey);
  }

  // borrar el cache de las listings del seller
  Future<void> clearSellerListingsCache() async {
    if (!initialized) await init();
    await box.delete(sellerListingsKey);
    await box.delete(sellerLastFetchKey);
  }

  // función genérica para cachear listings, recibe las keys para el cache y el timestamp
  Future<void> cacheListings({
    required List<ProductDto> listings,
    required String listingsKey,
    required String timestampKey,
  }) async {
    if (!initialized) await init();

    try {
      // mapear las listings a json, jsonEncode solo acepta tipos primitivos, por eso el toJson en ProductDto
      final jsonList = listings.map((p) => p.toJson()).toList();
      // guardar el json en el cache como string
      await box.put(listingsKey, jsonEncode(jsonList));
      // guardar el timestamp de la última vez que se hizo fetch, para saber si el cache es reciente o no
      await box.put(timestampKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      print('Error caching listings ($listingsKey): $e');
    }
  }

  // función genérica para obtener listings cacheadas, recibe la key del cache
  Future<List<ProductDto>?> getCachedListings(String key) async {
    if (!initialized) await init();

    try {
      final jsonStr = box.get(key);
      // no hay cache
      if (jsonStr is! String || jsonStr.isEmpty) return null;

      // Lista de dynamic porque el jsonDecode devuelve dynamic, pero sabemos que es una lista de objetos
      final List<dynamic> jsonList = jsonDecode(jsonStr) as List<dynamic>;

      // mapear el json a ProductDto
      return jsonList
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
}
