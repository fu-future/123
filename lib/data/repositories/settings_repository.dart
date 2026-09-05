import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_settings.dart';

class SettingsRepository {
  static const _kBaseUrl = 'ai_base_url';
  static const _kApiKey = 'ai_api_key';
  static const _kModel = 'ai_model';
  static const _kTheme = 'theme_mode';
  static const _kCurrency = 'default_currency';

  Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return AppSettings(
      aiBaseUrl: prefs.getString(_kBaseUrl) ?? '',
      aiApiKey: prefs.getString(_kApiKey) ?? '',
      aiModel: prefs.getString(_kModel) ?? '',
      themeMode: prefs.getString(_kTheme) ?? 'light',
      defaultCurrency: prefs.getString(_kCurrency) ?? 'CNY',
    );
  }

  Future<void> save(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kBaseUrl, settings.aiBaseUrl);
    await prefs.setString(_kApiKey, settings.aiApiKey);
    await prefs.setString(_kModel, settings.aiModel);
    await prefs.setString(_kTheme, settings.themeMode);
    await prefs.setString(_kCurrency, settings.defaultCurrency);
  }
}
