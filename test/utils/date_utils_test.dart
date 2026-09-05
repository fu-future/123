import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_app/core/utils/date_utils.dart';

void main() {
  group('monthStart/monthEnd', () {
    test('普通月', () {
      final m = DateTime(2024, 5, 15);
      expect(DateUtilsEx.monthStart(m), DateTime(2024, 5, 1));
      expect(DateUtilsEx.monthEnd(m), DateTime(2024, 5, 31));
    });
    test('12月跨年', () {
      final m = DateTime(2024, 12, 20);
      expect(DateUtilsEx.monthEnd(m), DateTime(2024, 12, 31));
    });
    test('闰年2月29天', () {
      expect(DateUtilsEx.monthEnd(DateTime(2024, 2, 10)),
          DateTime(2024, 2, 29));
      expect(DateUtilsEx.monthEnd(DateTime(2023, 2, 10)),
          DateTime(2023, 2, 28));
    });
  });

  group('dayStart/dayEnd', () {
    test('起止', () {
      final d = DateTime(2024, 1, 5, 13, 30);
      expect(DateUtilsEx.dayStart(d), DateTime(2024, 1, 5));
      expect(DateUtilsEx.dayEnd(d), DateTime(2024, 1, 6));
    });
  });

  group('weekRange（周一为始）', () {
    test('周一本身', () {
      final d = DateTime(2024, 1, 1); // 周一
      expect(DateUtilsEx.weekStart(d), DateTime(2024, 1, 1));
      expect(DateUtilsEx.weekEnd(d), DateTime(2024, 1, 8));
    });
    test('周日归位到本周一', () {
      final d = DateTime(2024, 1, 7); // 周日
      expect(DateUtilsEx.weekStart(d), DateTime(2024, 1, 1));
    });
  });

  group('friendlyDate', () {
    test('今天/昨天/其他', () {
      final now = DateTime(2024, 1, 10, 9);
      expect(DateUtilsEx.friendlyDate(DateTime(2024, 1, 10), now: now), '今天');
      expect(DateUtilsEx.friendlyDate(DateTime(2024, 1, 9), now: now), '昨天');
      expect(DateUtilsEx.friendlyDate(DateTime(2024, 1, 1), now: now),
          '2024-01-01');
    });
  });
}
