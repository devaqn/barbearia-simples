import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/constants.dart';

class FirebaseContextService {
  final FlutterSecureStorage _storage;
  String? _cachedShopId;

  FirebaseContextService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  Future<String> getShopId() async {
    if (_cachedShopId != null) return _cachedShopId!;
    final id = await _storage.read(key: AppConstants.shopIdStorageKey);
    if (id == null || id.isEmpty) throw StateError('Shop ID not configured');
    _cachedShopId = id;
    return id;
  }

  Future<void> setShopId(String id) async {
    await _storage.write(key: AppConstants.shopIdStorageKey, value: id);
    _cachedShopId = id;
  }

  void clearCache() => _cachedShopId = null;

  Future<CollectionReference<Map<String, dynamic>>> col(String name) async {
    final shopId = await getShopId();
    return FirebaseFirestore.instance
        .collection(AppConstants.colBarbearias)
        .doc(shopId)
        .collection(name);
  }

  Future<DocumentReference<Map<String, dynamic>>> doc(
    String collection,
    String docId,
  ) async {
    final shopId = await getShopId();
    return FirebaseFirestore.instance
        .collection(AppConstants.colBarbearias)
        .doc(shopId)
        .collection(collection)
        .doc(docId);
  }
}
