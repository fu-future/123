/// 应用设置：AI 配置与主题偏好。
class AppSettings {
  const AppSettings({
    this.aiBaseUrl = '',
    this.aiApiKey = '',
    this.aiModel = '',
    this.themeMode = 'light',
    this.defaultCurrency = 'CNY',
  });

  final String aiBaseUrl;
  final String aiApiKey;
  final String aiModel;
  final String themeMode;
  final String defaultCurrency;

  bool get hasAiConfigured =>
      aiBaseUrl.trim().isNotEmpty &&
      aiApiKey.trim().isNotEmpty &&
      aiModel.trim().isNotEmpty;

  AppSettings copyWith({
    String? aiBaseUrl,
    String? aiApiKey,
    String? aiModel,
    String? themeMode,
    String? defaultCurrency,
  }) {
    return AppSettings(
      aiBaseUrl: aiBaseUrl ?? this.aiBaseUrl,
      aiApiKey: aiApiKey ?? this.aiApiKey,
      aiModel: aiModel ?? this.aiModel,
      themeMode: themeMode ?? this.themeMode,
      defaultCurrency: defaultCurrency ?? this.defaultCurrency,
    );
  }
}
