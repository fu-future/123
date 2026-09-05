import 'dart:ui';

/// 分类内置固定 UUID 常量，保证种子数据幂等。
class BuiltInCategoryIds {
  // ---- 支出（expense）----
  static const food = '00000000-0000-4000-8000-000000000001'; // 餐饮
  static const transport = '00000000-0000-4000-8000-000000000002'; // 交通
  static const shopping = '00000000-0000-4000-8000-000000000003'; // 购物
  static const housing = '00000000-0000-4000-8000-000000000004'; // 居住
  static const entertainment = '00000000-0000-4000-8000-000000000005'; // 娱乐
  static const medical = '00000000-0000-4000-8000-000000000006'; // 医疗
  static const education = '00000000-0000-4000-8000-000000000007'; // 教育
  static const otherExpense = '00000000-0000-4000-8000-000000000008'; // 其他(支出)

  // ---- 收入（income）----
  static const salary = '00000000-0000-4000-8000-000000000101'; // 工资
  static const investment = '00000000-0000-4000-8000-000000000102'; // 理财
  static const bonus = '00000000-0000-4000-8000-000000000103'; // 奖金
  static const otherIncome = '00000000-0000-4000-8000-000000000104'; // 其他(收入)

  /// 删除分类时的兜底迁移目标：按类型各自指向「其他」。
  static String fallbackForType(String type) =>
      type == 'income' ? otherIncome : otherExpense;
}

/// 全局应用常量。
class AppConstants {
  AppConstants._();

  static const String appName = '小账本';
  static const String defaultCurrency = 'CNY';

  /// AI 分类请求超时（毫秒）。超过即降级到规则分类器。
  static const int aiClassifyTimeoutMs = 1500;

  /// AI 洞察请求超时。
  static const int aiInsightTimeoutMs = 8000;

  /// 连接测试超时。
  static const int aiTestTimeoutMs = 5000;

  /// 账单文本解析正则模板库（占位/扩展点，见 QA-F7）。
  static const List<String> billTextPatterns = <String>[
    r'((?:[\u4e00-\u9fa5A-Za-z0-9]+?)(?:消费|支付|付款))',
  ];

  /// 可被用户选择的分类配色（数据驱动取色，非硬编码）。
  static const List<Color> selectableColors = <Color>[
    Color(0xFF8FD9A8), // 薄荷绿
    Color(0xFFF7D488), // 奶油黄
    Color(0xFFF7A8B8), // 樱花粉
    Color(0xFF9BC7F0), // 天蓝
    Color(0xFFC6A8F7), // 淡紫
    Color(0xFFF5B88C), // 杏橙
    Color(0xFF9AE0E0), // 浅青
    Color(0xFFE8C1A0), // 浅咖
    Color(0xFFB8D98A), // 草绿
    Color(0xFFF2A98A), // 珊瑚
  ];

  /// 分类图标 key 候选集（对应 Material Icons 名称映射，见 icons.dart）。
  static const List<String> categoryIconKeys = <String>[
    'restaurant', 'directions_bus', 'shopping_bag', 'home', 'movie',
    'local_hospital', 'school', 'more_horiz', 'work', 'trending_up',
    'emoji_events', 'wallet', 'fastfood', 'train', 'flight', 'pet',
    'fitness_center', 'phone_iphone', 'card_giftcard', 'payments',
  ];
}
