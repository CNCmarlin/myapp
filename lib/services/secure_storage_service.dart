import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  const SecureStorageService();
  final _storage = const FlutterSecureStorage();

  static const _geminiKey = 'GEMINI_API_KEY';
  static const _aiProvider = 'SELECTED_AI_PROVIDER';

  Future<void> saveGeminiKey(String key) async {
    await _storage.write(key: _geminiKey, value: key);
  }

  Future<String?> getGeminiKey() async {
    return await _storage.read(key: _geminiKey);
  }

  // 🛡️ SHIELD: Allow user to switch between AI providers
  Future<void> setProvider(String provider) async {
    await _storage.write(key: _aiProvider, value: provider);
  }

  Future<String> getProvider() async {
    return await _storage.read(key: _aiProvider) ?? 'gemini';
  }
}
