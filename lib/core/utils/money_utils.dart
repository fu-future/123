import 'package:intl/intl.dart';

/// 金额工具：所有金额以整数「分」存储，展示层唯一入口在 [formatYuan]。
class MoneyUtils {
  MoneyUtils._();

  static final NumberFormat _currency = NumberFormat.currency(
    locale: 'zh_CN',
    symbol: '¥',
    decimalDigits: 2,
  );

  /// 元 → 分。入参为 double 元，立即转 int 分，杜绝业务层 double。
  /// 说明：金额必须为正数（正整数分）；0 表示无金额，视为非法。
  static int? parseYuanToCents(double yuan) {
    if (yuan <= 0 || !yuan.isFinite) return null;
    return (yuan * 100).round();
  }

  /// 用户输入字符串（可能含 ¥ ￥ 逗号）→ 分。非法返回 null。
  static int? parseYuanStringToCents(String input) {
    final cleaned = input
        .replaceAll(RegExp(r'[¥￥,\s]'), '')
        .trim();
    if (cleaned.isEmpty) return null;
    final value = double.tryParse(cleaned);
    if (value == null) return null;
    return parseYuanToCents(value);
  }

  /// 分 → 元字符串，形如 ¥1,234.56。
  static String formatYuan(int cents) => _currency.format(cents / 100);

  /// 带符号：支出负数 → -¥12.50；收入正数 → ¥12.50。
  static String formatSigned(int cents) {
    if (cents < 0) return '-${formatYuan(-cents)}';
    return formatYuan(cents);
  }

  /// 是否为合法金额分：正整数。
  static bool isValidCents(int cents) => cents > 0;

  /// 不带符号的千分位数字文本，如 1,234.56（供图表/汇总）。
  static String formatYuanPlain(int cents) {
    final number = NumberFormat('#,##0.00').format(cents / 100);
    return number;
  }

  /// 分 → 双精度元（仅用于图表 y 轴换算等展示边界）。
  static double toYuan(int cents) => cents / 100;
}
