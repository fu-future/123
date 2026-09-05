import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utils/date_utils.dart';
import '../data/local/daos/transaction_dao.dart';
import '../data/models/enums.dart';
import 'repository_provider.dart';

/// 统计时间粒度。
enum StatsPeriod { day, week, month }

final statsPeriodProvider = StateProvider<StatsPeriod>((ref) {
  // 默认空；由 UI 根据所选粒度计算。此处仅承载粒度选择，range 用 state 派生。
  return StatsPeriod.month;
});

/// 统计锚点日期（默认今天）。
final statsAnchorProvider = StateProvider<DateTime>((ref) => DateTime.now());

/// 根据粒度 + 锚点推导时间范围（半开 [start,end)）。
class StatsRange {
  const StatsRange(this.start, this.end, this.label);
  final DateTime start;
  final DateTime end;
  final String label;
}

final statsRangeProvider = Provider<StatsRange>((ref) {
  final period = ref.watch(statsPeriodProvider);
  final anchor = ref.watch(statsAnchorProvider);
  final now = DateTime.now();
  switch (period) {
    case StatsPeriod.day:
      final s = DateUtilsEx.dayStart(anchor);
      return StatsRange(s, s.add(const Duration(days: 1)), '今日');
    case StatsPeriod.week:
      final (s, e) = DateUtilsEx.weekRange(anchor);
      return StatsRange(s, e, '本周');
    case StatsPeriod.month:
      return StatsRange(
        DateUtilsEx.monthStart(anchor),
        DateUtilsEx.monthStart(anchor).add(const Duration(days: 30)),
        '本月',
      );
  }
});

/// 支出分类占比聚合（只统计支出）。
final expenseCategoryAggProvider =
    StreamProvider<List<CategoryAggregation>>((ref) {
  final range = ref.watch(statsRangeProvider);
  return ref
      .watch(transactionRepositoryProvider)
      .watchCategoryAggregation(range.start, range.end, TransactionType.expense);
});

/// 趋势（日粒度收支合计）。
final trendProvider = StreamProvider<List<TrendPoint>>((ref) {
  final range = ref.watch(statsRangeProvider);
  return ref
      .watch(transactionRepositoryProvider)
      .watchTrendAggregation(range.start, range.end);
});

/// 当前月概览（统计页 AI 洞察用）。
final statsMonthlySummaryProvider = StreamProvider<MonthlySummary>((ref) {
  final now = DateTime.now();
  return ref
      .watch(transactionRepositoryProvider)
      .watchMonthlySummary(now.year, now.month);
});
