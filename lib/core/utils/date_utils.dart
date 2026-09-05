import 'package:intl/intl.dart';

/// 日期工具：DB 存 UTC epoch，展示按本地时区；周以周一为始。
class DateUtilsEx {
  DateUtilsEx._();

  static final DateFormat _ymd = DateFormat('yyyy-MM-dd');

  /// 某年月的起止（含边界），已考虑跨年/2月天数。
  static DateTime monthStart(DateTime month) => DateTime(month.year, month.month, 1);
  static DateTime monthEnd(DateTime month) =>
      DateTime(month.year, month.month + 1, 0);

  /// 给定某天的起止。
  static DateTime dayStart(DateTime day) => DateTime(day.year, day.month, day.day);
  static DateTime dayEnd(DateTime day) => dayStart(day).add(const Duration(days: 1));

  /// 给定某天所在周的周一（一周之始）与周日。
  static DateTime weekStart(DateTime day) {
    final mondayDelta = (day.weekday - DateTime.monday) % 7;
    return dayStart(day).subtract(Duration(days: mondayDelta));
  }

  static DateTime weekEnd(DateTime day) => weekStart(day).add(const Duration(days: 7));

  /// 周区间（周一为始，周日归位）。
  static (DateTime, DateTime) weekRange(DateTime day) => (weekStart(day), weekEnd(day));

  /// 自然语言日期：今天 / 昨天 / yyyy-MM-dd。
  static String friendlyDate(DateTime date, {DateTime? now}) {
    final n = (now ?? DateTime.now());
    final d0 = dayStart(date);
    final today = dayStart(n);
    final diff = today.difference(d0).inDays;
    if (diff == 0) return '今天';
    if (diff == 1) return '昨天';
    return _ymd.format(date);
  }

  static String ymd(DateTime date) => _ymd.format(date);
}
