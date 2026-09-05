import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utils/date_utils.dart';
import '../data/local/daos/transaction_dao.dart';
import '../data/models/transaction.dart';
import '../data/repositories/transaction_repository.dart';
import 'repository_provider.dart';

/// 当前查看的年月（首页默认本月）。
final currentMonthProvider =
    StateProvider<DateTime>((ref) => DateTime.now());

/// 首页流水过滤（类型/分类），默认全部。
final transactionFilterProvider = StateProvider<TransactionFilter>(
  (ref) => const TransactionFilter(),
);

/// 时间范围推导：取 currentMonth 所在月（[月初, 下月初)）。
final currentRangeProvider = Provider<DateRange>((ref) {
  final month = ref.watch(currentMonthProvider);
  final start = DateUtilsEx.monthStart(month);
  final end = DateUtilsEx.monthEnd(month).add(const Duration(days: 1));
  return DateRange(start, end);
});

/// 账目列表 Stream（当前月 + 过滤）。
final transactionListProvider = StreamProvider<List<Transaction>>((ref) {
  final range = ref.watch(currentRangeProvider);
  final filter = ref.watch(transactionFilterProvider);
  return ref
      .watch(transactionRepositoryProvider)
      .watchTransactions(range, filter);
});

/// 本月概览 Stream。
final monthlySummaryProvider = StreamProvider<MonthlySummary>((ref) {
  final month = ref.watch(currentMonthProvider);
  return ref
      .watch(transactionRepositoryProvider)
      .watchMonthlySummary(month.year, month.month);
});

/// 账目增删改动作入口（UI 只调这里；错误以 String? 返回供 SnackBar 提示）。
class TransactionActions extends AsyncNotifier<String?> {
  @override
  Future<String?> build() async => null;

  Future<String?> _run(Future<Object?> Function() fn) async {
    final result = await fn();
    if (result is String && result.isNotEmpty) {
      return result; // 已封装的失败消息
    }
    return null; // 成功
  }

  Future<String?> add(Transaction t) {
    return _run(() async {
      final r = await ref.read(transactionRepositoryProvider).addTransaction(t);
      return r.errorOrNull;
    });
  }

  /// 保存修改。命名避开 riverpod 2.6 中 AsyncNotifierBase.update 的同名冲突。
  Future<String?> save(Transaction t) {
    return _run(() async {
      final r =
          await ref.read(transactionRepositoryProvider).updateTransaction(t);
      return r.errorOrNull;
    });
  }

  Future<String?> delete(String id) {
    return _run(() async {
      final r = await ref.read(transactionRepositoryProvider).deleteTransaction(id);
      return r.errorOrNull;
    });
  }

  Future<String?> addBatch(List<Transaction> ts) {
    return _run(() async {
      final r =
          await ref.read(transactionRepositoryProvider).addTransactionsBatch(ts);
      return r.errorOrNull;
    });
  }
}

final transactionActionsProvider =
    AsyncNotifierProvider<TransactionActions, String?>(
  TransactionActions.new,
);
