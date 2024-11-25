import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final _storage = const FlutterSecureStorage();
  static const String _tokenKey = 'auth_token';

  Future<void> storeAuthToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<String?> getAuthToken() async {
    return await _storage.read(key: _tokenKey);
  }
}
