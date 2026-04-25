import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/pending_listing_operation.dart';

List<PendingListingOperation> decodePendingOperationsOnIsolate(String jsonStr) {
  final decoded = jsonDecode(jsonStr);
  if (decoded is! List) return [];

  return decoded
      .map((item) => PendingListingOperation.fromJson(
    Map<String, dynamic>.from(item as Map),
  ))
      .toList();
}

String encodePendingOperationsOnIsolate(
    List<PendingListingOperation> operations,
    ) {
  return jsonEncode(operations.map((operation) => operation.toJson()).toList());
}

class PendingListingOperationsStorage {
  static const String pendingListingsKey = 'pending_listing_operations';

  final FlutterSecureStorage storage;

  PendingListingOperationsStorage({FlutterSecureStorage? storage})
      : storage = storage ?? const FlutterSecureStorage();

  Future<List<PendingListingOperation>> getPendingOperations() async {
    final raw = await storage.read(key: pendingListingsKey);
    if (raw == null || raw.isEmpty) return [];

    try {
      return compute(decodePendingOperationsOnIsolate, raw);
    } catch (_) {
      return [];
    }
  }

  Future<void> savePendingOperation(PendingListingOperation operation) async {
    final operations = await getPendingOperations();
    operations.add(operation);
    await _saveAll(operations);
  }

  Future<void> removePendingOperation(String id) async {
    final operations = await getPendingOperations();
    operations.removeWhere((operation) => operation.id == id);
    await _saveAll(operations);
  }

  Future<void> clear() async {
    await storage.delete(key: pendingListingsKey);
  }

  Future<void> _saveAll(List<PendingListingOperation> operations) async {
    final encoded = await compute(encodePendingOperationsOnIsolate, operations);
    await storage.write(key: pendingListingsKey, value: encoded);
  }
}