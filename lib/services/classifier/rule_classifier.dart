import '../../core/constants/app_constants.dart';
import '../../data/models/enums.dart';
import 'transaction_classifier.dart';

/// 规则分类器：关键词/商户映射（静态 Map）→ 内置分类 UUID。
/// 命中返回内置分类 id；未命中返回 null（由上层落到「其他」）。
class RuleClassifier implements TransactionClassifier {
  /// 关键词 → 支出内置分类 id。按优先顺序匹配（商户优先于通用关键词）。
  static const Map<String, String> _expenseKeywords = <String, String>{
    // 商户/渠道
    '美团': BuiltInCategoryIds.food,
    '饿了么': BuiltInCategoryIds.food,
    '外卖': BuiltInCategoryIds.food,
    '肯德基': BuiltInCategoryIds.food,
    '麦当劳': BuiltInCategoryIds.food,
    '星巴克': BuiltInCategoryIds.food,
    '餐厅': BuiltInCategoryIds.food,
    '滴滴': BuiltInCategoryIds.transport,
    '高德': BuiltInCategoryIds.transport,
    '地铁': BuiltInCategoryIds.transport,
    '公交': BuiltInCategoryIds.transport,
    '加油': BuiltInCategoryIds.transport,
    '淘宝': BuiltInCategoryIds.shopping,
    '京东': BuiltInCategoryIds.shopping,
    '拼多多': BuiltInCategoryIds.shopping,
    '天猫': BuiltInCategoryIds.shopping,
    '超市': BuiltInCategoryIds.shopping,
    '水电': BuiltInCategoryIds.housing,
    '房租': BuiltInCategoryIds.housing,
    '物业': BuiltInCategoryIds.housing,
    '电影': BuiltInCategoryIds.entertainment,
    '游戏': BuiltInCategoryIds.entertainment,
    'KTV': BuiltInCategoryIds.entertainment,
    '医院': BuiltInCategoryIds.medical,
    '药': BuiltInCategoryIds.medical,
    '体检': BuiltInCategoryIds.medical,
    '书店': BuiltInCategoryIds.education,
    '课程': BuiltInCategoryIds.education,
    '学费': BuiltInCategoryIds.education,
  };

  static const Map<String, String> _incomeKeywords = <String, String>{
    '工资': BuiltInCategoryIds.salary,
    '薪资': BuiltInCategoryIds.salary,
    '工资条': BuiltInCategoryIds.salary,
    '理财': BuiltInCategoryIds.investment,
    '基金': BuiltInCategoryIds.investment,
    '利息': BuiltInCategoryIds.investment,
    '股票': BuiltInCategoryIds.investment,
    '奖金': BuiltInCategoryIds.bonus,
    '红包': BuiltInCategoryIds.bonus,
    '分红': BuiltInCategoryIds.bonus,
  };

  @override
  Future<String?> classify(String text, TransactionType type) async {
    final t = text.trim();
    if (t.isEmpty) return null;

    // 收入/支出用各自的关键词表。
    final keywords =
        type.isExpense ? _expenseKeywords : _incomeKeywords;

    for (final entry in keywords.entries) {
      if (t.contains(entry.key)) {
        return entry.value;
      }
    }
    return null;
  }
}
