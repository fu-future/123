import 'package:uuid/uuid.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/result.dart';
import '../local/database.dart';
import '../models/enums.dart';
import '../models/transaction.dart';

/// 时间范围（半开区间 [start, end)）。
class DateRange {
  const DateRange(this.start, this.end);
  final DateTime start;
  final DateTime end;
}

/// 账目过滤条件。
class TransactionFilter {
  const TransactionFilter({this.categoryId, this.type});
  final String? categoryId;
  final TransactionType? type;
}

/// ★统一写入入口（手动/导入/未来原生监听都走这里）。
abstract interface class TransactionRepository {
  Future<Result<String>> addTransaction(Transaction t);
  Future<Result<void>> updateTransaction(Transaction t);
  Future<Result<void>> deleteTransaction(String id);
  Future<Result<int>> addTransactionsBatch(List<Transaction> ts);

  Stream<List<Transaction>> watchTransactions(
    DateRange range,
    TransactionFilter filter,
  );
  Stream<MonthlySummary> watchMonthlySummary(int year, int month);
  Stream<List<CategoryAggregation>> watchCategoryAggregation(
    DateTime start,
    DateTime end,
    TransactionType type,
  );
  Stream<List<TrendPoint>> watchTrendAggregation(DateTime start, DateTime end);

  /// 全量账目（一次性，供导出/备份）。
  Future<List<Transaction>> exportAll();
}

/// Drift 实现。
class DriftTransactionRepository implements TransactionRepository {
  DriftTransactionRepository(this._db);
  final AppDatabase _db;

  TransactionDao get _dao => _db.transactionDao;

  @override
  Future<Result<String>> addTransaction(Transaction t) async {
    try {
      final id = t.id.isEmpty ? const Uuid().v4() : t.id;
      final now = DateTime.now();
      final model = Transaction(
        id: id,
        amountCents: t.amountCents,
        type: t.type,
        categoryId: t.categoryId,
        date: t.date,
        note: t.note,
        merchant: t.merchant,
        currency: t.currency.isEmpty
            ? AppConstants.defaultCurrency
            : t.currency,
        source: t.source,
        createdAt: t.createdAt ?? now,
        updatedAt: t.updatedAt ?? now,
      );
      await _dao.insertTransaction(model);
      return Result.ok(id);
    } catch (e) {
      return Result.failure('保存失败：$e');
    }
  }

  @override
  Future<Result<void>> updateTransaction(Transaction t) async {
    try {
      // 保证 updatedAt 刷新以支持未来增量同步。
      await _dao.updateTransaction(t, updatedAt: DateTime.now());
      return Result.ok(null);
    } catch (e) {
      return Result.failure('更新失败：$e');
    }
  }

  @override
  Future<Result<void>> deleteTransaction(String id) async {
    try {
      await _dao.deleteTransaction(id);
      return Result.ok(null);
    } catch (e) {
      return Result.failure('删除失败：$e');
    }
  }

  @override
  Future<Result<int>> addTransactionsBatch(List<Transaction> ts) async {
    if (ts.isEmpty) return Result.ok(0);
    try {
      final now = DateTime.now();
      final models = ts
          .map((t) => Transaction(
                id: t.id.isEmpty ? const Uuid().v4() : t.id,
                amountCents: t.amountCents,
                type: t.type,
                categoryId: t.categoryId,
                date: t.date,
                note: t.note,
                merchant: t.merchant,
                currency: t.currency.isEmpty
                    ? AppConstants.defaultCurrency
                    : t.currency,
                source: t.source,
                createdAt: t.createdAt ?? now,
                updatedAt: t.updatedAt ?? now,
              ))
          .toList();
      // dao.insertAll 内部使用 batch，天然单事务，失败整体回滚。
      await _dao.insertAll(models);
      return Result.ok(models.length);
    } catch (e) {
      return Result.failure('批量导入失败：$e');
    }
  }

  @override
  Stream<List<Transaction>> watchTransactions(
    DateRange range,
    TransactionFilter filter,
  ) {
    return _dao.watchByRange(
      range.start,
      range.end,
      categoryId: filter.categoryId,
      type: filter.type,
    );
  }

  @override
  Stream<MonthlySummary> watchMonthlySummary(int year, int month) =>
      _dao.watchMonthlySummary(year, month);

  @override
  Stream<List<CategoryAggregation>> watchCategoryAggregation(
    DateTime start,
    DateTime end,
    TransactionType type,
  ) =>
      _dao.watchCategoryAggregation(start, end, type);

  @override
  Stream<List<TrendPoint>> watchTrendAggregation(
    DateTime start,
    DateTime end,
  ) =>
      _dao.watchTrendAggregation(start, end);

  @override
  Future<List<Transaction>> exportAll() => _dao.getAll();
}
