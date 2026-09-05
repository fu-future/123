import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/app_settings.dart';
import '../services/ai/ai_client.dart';
import '../services/classifier/ai_classifier.dart';
import '../services/classifier/rule_classifier.dart';
import '../services/classifier/transaction_classifier.dart';
import 'settings_provider.dart';

/// 分类器 Provider：AI 三项配置齐全 → AiClassifier(规则兜底)；否则 RuleClassifier。
final classifierProvider = Provider<TransactionClassifier>((ref) {
  final AppSettings settings = ref.watch(settingsProvider).valueOrNull ??
      const AppSettings();
  if (settings.hasAiConfigured) {
    final client = AiClient(
      baseUrl: settings.aiBaseUrl,
      apiKey: settings.aiApiKey,
      model: settings.aiModel,
    );
    return AiClassifier(client: client, fallback: RuleClassifier());
  }
  return RuleClassifier();
});

/// AI 客户端 Provider（仅供设置页连接测试复用配置）。
final aiClientProvider = Provider<AiClient?>((ref) {
  final AppSettings settings = ref.watch(settingsProvider).valueOrNull ??
      const AppSettings();
  if (!settings.hasAiConfigured) return null;
  return AiClient(
    baseUrl: settings.aiBaseUrl,
    apiKey: settings.aiApiKey,
    model: settings.aiModel,
  );
});
