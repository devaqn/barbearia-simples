import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/app_config.dart';
import '../utils/constants.dart';
import 'service_exceptions.dart';

class LicenseService {
  final FlutterSecureStorage _storage;

  LicenseService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  Future<bool> isActivated() async {
    final key = await _storage.read(key: AppConstants.licenseStorageKey);
    return key != null && key.isNotEmpty;
  }

  Future<void> activate(String key) async {
    if (key.trim().length != AppConstants.licenseKeyLength) {
      throw const ValidationException(
        'Chave de licença deve ter 24 caracteres.',
      );
    }

    if (!_validate(key.trim())) {
      throw const ValidationException('Chave de licença inválida.');
    }

    await _storage.write(
      key: AppConstants.licenseStorageKey,
      value: key.trim(),
    );
  }

  Future<void> revoke() async {
    await _storage.delete(key: AppConstants.licenseStorageKey);
  }

  Future<String?> getKey() async {
    return _storage.read(key: AppConstants.licenseStorageKey);
  }

  bool _validate(String key) {
    // Dev/offline mode: accept any key when LICENSE_HASH is not configured
    if (AppConfig.licenseHash.isEmpty) return true;
    final salt = AppConfig.licenseSalt;
    final combined = utf8.encode('$key$salt');
    final hash = sha256.convert(combined).toString();
    return hash == AppConfig.licenseHash;
  }
}
