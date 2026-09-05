import '../../core/constants/app_constants.dart';
import '../../data/models/enums.dart';
import '../ai/ai_client.dart';
import 'rule_classifier.dart';
import 'transaction_classifier.dart';

/// AI 分类器：调用 AI，超时/失败/无法映射一律降级到规则分类器。
/// 绝不向调用方抛异常。
class AiClassifier implements TransactionClassifier {
  AiClassifier({required AiClient client, required RuleClassifier fallback})
      : _client = client,
        _fallback = fallback;

  final AiClient _client;
  final RuleClassifier _fallback;

  static const String _systemPrompt =
      '你是记账分类助手。根据用户输入的备注/商户文本，仅输出一个分类名，'
      '分类名从以下列表中选：餐饮、交通、购物、居住、娱乐、医疗、教育、其他'
      '（支出）或 工资、理财、奖金、其他（收入）。不要输出任何其他文字。';

  @override
  Future<String?> classify(String text, TransactionType type) async {
    try {
      final userPrompt = '类型：${type.isExpense ? '支出' : '收入'}\n'
          '文本：$text\n请只输出一个分类名。';
      final result = await _client
          .chatCompletion(_systemPrompt, userPrompt)
          .timeout(const Duration(milliseconds: AppConstants.aiClassifyTimeoutMs));
      final mapped = _matchCategory(result, type);
      if (mapped != null) return mapped;
      // AI 返回内容无法映射 → 规则兜底。
      return _fallback.classify(text, type);
    } catch (_) {
      // 超时 / 网络异常 / 空内容 → 规则兜底。
      return _fallback.classify(text, type);
    }
  }

  /// 将 AI 分类名映射到内置分类 UUID。
  String? _matchCategory(String name, TransactionType type) {
    final n = name.trim();
    if (n.isEmpty) return null;
    if (type.isExpense) {
      if (n.contains('餐饮') || n.contains('吃')) {
        return BuiltInCategoryIds.food;
      }
      if (n.contains('交通') || n.contains('出行')) {
        return BuiltInCategoryIds.transport;
      }
      if (n.contains('购物') || n.contains('买')) {
        return BuiltInCategoryIds.shopping;
      }
      if (n.contains('居住') || n.contains('住')) {
        return BuiltInCategoryIds.housing;
      }
      if (n.contains('娱乐')) {
        return BuiltInCategoryIds.entertainment;
      }
      if (n.contains('医疗') || n.contains('医')) {
        return BuiltInCategoryIds.medical;
      }
      if (n.contains('教育') || n.contains('学')) {
        return BuiltInCategoryIds.education;
      }
    } else {
      if (n.contains('工资') || n.contains('薪资')) {
        return BuiltInCategoryIds.salary;
      }
      if (n.contains('理财') || n.contains('基金') || n.contains('利息')) {
        return BuiltInCategoryIds.investment;
      }
      if (n.contains('奖金') || n.contains('红包')) {
        return BuiltInCategoryIds.bonus;
      }
    }
    return null;
  }
}
