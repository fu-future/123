import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_app/core/utils/money_utils.dart';

void main() {
  group('parseYuanToCents', () {
    test('整数与小数', () {
      expect(MoneyUtils.parseYuanToCents(12.5), 1250);
      expect(MoneyUtils.parseYuanToCents(19.99), 1999);
    });
    test('非正非法', () {
      expect(MoneyUtils.parseYuanToCents(0), isNull);
      expect(MoneyUtils.parseYuanToCents(-1), isNull);
    });
  });

  group('parseYuanStringToCents', () {
    test('符号与逗号清洗', () {
      expect(MoneyUtils.parseYuanStringToCents('¥1,234.56'), 123456);
      expect(MoneyUtils.parseYuanStringToCents('￥12.5'), 1250);
    });
    test('非法输入', () {
      expect(MoneyUtils.parseYuanStringToCents('abc'), isNull);
      expect(MoneyUtils.parseYuanStringToCents(''), isNull);
    });
  });

  group('formatYuan', () {
    test('千分位', () {
      expect(MoneyUtils.formatYuan(123456), '¥1,234.56');
      expect(MoneyUtils.formatYuan(1250), '¥12.50');
    });
    test('超大值', () {
      expect(MoneyUtils.formatYuan(100000000000), '¥1,000,000,000.00');
    });
  });

  group('formatSigned', () {
    test('带符号', () {
      expect(MoneyUtils.formatSigned(-1250), '-¥12.50');
      expect(MoneyUtils.formatSigned(1250), '¥12.50');
    });
  });

  group('isValidCents', () {
    test('正整数合法', () {
      expect(MoneyUtils.isValidCents(100), isTrue);
      expect(MoneyUtils.isValidCents(0), isFalse);
      expect(MoneyUtils.isValidCents(-1), isFalse);
    });
  });
}
