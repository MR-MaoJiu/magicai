import 'package:shared_preferences/shared_preferences.dart';

class ConfigService {
  static const String _keyApiKey = 'api_key';
  static const String _keyApiModel = 'api_model';
  static const String _keyApiBaseUrl = 'api_base_url';

  final SharedPreferences _prefs;

  ConfigService(this._prefs);

  static Future<ConfigService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return ConfigService(prefs);
  }

  String? get apiKey => _prefs.getString(_keyApiKey);
  String get apiModel => _prefs.getString(_keyApiModel) ?? 'gpt-4o';
  String get baseUrl =>
      _prefs.getString(_keyApiBaseUrl) ?? 'https://api.xty.app/v1';

  Future<void> saveConfig({
    required String apiKey,
    String? apiModel,
    String? baseUrl,
  }) async {
    await _prefs.setString(_keyApiKey, apiKey);
    if (apiModel != null) await _prefs.setString(_keyApiModel, apiModel);
    if (baseUrl != null) await _prefs.setString(_keyApiBaseUrl, baseUrl);
  }

  bool get isConfigured => apiKey != null;
}
