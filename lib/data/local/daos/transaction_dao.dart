import 'package:drift/drift.dart';

import '../../models/enums.dart';
import '../../models/transaction.dart';
import '../database.dart';
import '../tables.dart';

part 'transaction_dao.g.dart';

/// 分类聚合结果。
class CategoryAggregation {
  const CategoryAggregation({
    required this.categoryId,
    required this.categoryName,
    required this.iconKey,
    required this.colorValue,
    required this.totalCents,
    required this.count,
  });

  final String categoryId;
  final String categoryName;
  final String iconKey;
  final int colorValue;
  final int totalCents;
  final int count;
}

/// 趋势点（按时间桶聚合）。
class TrendPoint {
  const TrendPoint({required this.dayEpoch, required this.type, required this.totalCents});
  final int dayEpoch;
  final String type;
  final int totalCents;
}

/// 月度概览。
class MonthlySummary {
  const MonthlySummary({required this.incomeCents, required this.expenseCents});
  final int incomeCents;
  final int expenseCents;

  int get balanceCents => incomeCents - expenseCents;
}

@DriftAccessor(tables: [Transactions])
class TransactionDao extends DatabaseAccessor<AppDatabase>
    with _$TransactionDaoMixin {
  TransactionDao(super.db);

  // ---------- CRUD ----------

  Future<void> insertTransaction(Transaction t) => insertAll([t]);

  Future<void> insertAll(List<Transaction> ts) {
    return batch((b) {
      b.insertAll(
        transactions,
        ts.map(_toCompanion).toList(),
        mode: InsertMode.insertOrIgnore,
      );
    });
  }

  Future<void> updateTransaction(Transaction t, {DateTime? updatedAt}) {
    return (update(transactions)..where((row) => row.id.equals(t.id))).write(
      TransactionsCompanion(
        amountCents: Value(t.amountCents),
        type: Value(t.type.code),
        categoryId: Value(t.categoryId),
        date: Value(t.date),
        note: Value(t.note),
        merchant: Value(t.merchant),
        updatedAt: Value(updatedAt ?? DateTime.now()),
      ),
    );
  }

  Future<void> deleteTransaction(String id) =>
      (delete(transactions)..where((row) => row.id.equals(id))).go();

  // ---------- 响应式查询 ----------

  /// 全量账目（一次性，供导出/备份），按日期倒序。
  Future<List<Transaction>> getAll() async {
    final rows = await (select(transactions)
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .get();
    return rows.map(_rowToTransaction).toList();
  }

  /// 时间区间流水（倒序：日期新→旧，同日按创建倒序）。
  Stream<List<Transaction>> watchByRange(
    DateTime start,
    DateTime end, {
    String? categoryId,
    TransactionType? type,
  }) {
    final query = select(transactions)
      ..orderBy([
        (t) => OrderingTerm.desc(t.date),
        (t) => OrderingTerm.desc(t.createdAt),
      ]);
    query.where((t) {
      final inRange = t.date.isBiggerOrEqualValue(start) &
          t.date.isSmallerThanValue(end);
      final catOk = categoryId == null ? const Constant(true) : t.categoryId.equals(categoryId);
      final typeOk = type == null ? const Constant(true) : t.type.equals(type.code);
      return inRange & catOk & typeOk;
    });
    return query.watch().map((rows) => rows.map(_rowToTransaction).toList());
  }

  /// 月度概览：本月收入合计 / 支出合计 / 结余（CASE WHEN 下推聚合）。
  Stream<MonthlySummary> watchMonthlySummary(int year, int month) {
    final start = DateTime(year, month, 1).toUtc().millisecondsSinceEpoch;
    final next = DateTime(year, month + 1, 1).toUtc().millisecondsSinceEpoch;
    final query = customSelect(
      '''
      SELECT
        COALESCE(SUM(CASE WHEN type = 'income' THEN amount_cents ELSE 0 END), 0) AS incomeCents,
        COALESCE(SUM(CASE WHEN type = 'expense' THEN amount_cents ELSE 0 END), 0) AS expenseCents
      FROM transactions
      WHERE date >= ? AND date < ?
      ''',
      variables: [Variable(start), Variable(next)],
      readsFrom: {transactions},
    );
    return query.watch().map((rows) {
      final row = rows.isEmpty ? null : rows.first;
      return MonthlySummary(
        incomeCents: row?.read<int>('incomeCents') ?? 0,
        expenseCents: row?.read<int>('expenseCents') ?? 0,
      );
    });
  }

  // ---------- 聚合（下推 SQL GROUP BY） ----------

  /// 分类占比聚合：某区间 + 类型。
  Stream<List<CategoryAggregation>> watchCategoryAggregation(
    DateTime start,
    DateTime end,
    TransactionType type,
  ) {
    final s = start.toUtc().millisecondsSinceEpoch;
    final e = end.toUtc().millisecondsSinceEpoch;
    final query = customSelect(
      '''
      SELECT
        t.category_id AS categoryId,
        c.name AS categoryName,
        c.icon_key AS iconKey,
        c.color_value AS colorValue,
        SUM(t.amount_cents) AS totalCents,
        COUNT(t.id) AS cnt
      FROM transactions t
      LEFT JOIN categories c ON c.id = t.category_id
      WHERE t.type = ? AND t.date >= ? AND t.date < ?
      GROUP BY t.category_id, c.name, c.icon_key, c.color_value
      ORDER BY totalCents DESC
      ''',
      variables: [Variable(type.code), Variable(s), Variable(e)],
      readsFrom: {transactions, categories},
    );
    return query.watch().map((rows) {
      return rows.map((row) {
        return CategoryAggregation(
          categoryId: row.read<String>('categoryId'),
          categoryName: row.read<String>('categoryName') ?? '未分类',
          iconKey: row.read<String>('iconKey') ?? 'more_horiz',
          colorValue: row.read<int>('colorValue') ?? 0xFFCCCCCC,
          totalCents: row.read<int>('totalCents') ?? 0,
          count: row.read<int>('cnt') ?? 0,
        );
      }).toList();
    });
  }

  /// 趋势聚合：按「天」分组（period 由上层折叠）。
  Stream<List<TrendPoint>> watchTrendAggregation(
    DateTime start,
    DateTime end,
  ) {
    final s = start.toUtc().millisecondsSinceEpoch;
    final e = end.toUtc().millisecondsSinceEpoch;
    final query = customSelect(
      '''
      SELECT
        date AS dayEpoch,
        type AS txType,
        SUM(amount_cents) AS totalCents
      FROM transactions
      WHERE date >= ? AND date < ?
      GROUP BY date, type
      ORDER BY date ASC
      ''',
      variables: [Variable(s), Variable(e)],
      readsFrom: {transactions},
    );
    return query.watch().map((rows) {
      final map = <String, Map<String, int>>{};
      for (final row in rows) {
        final day = row.read<int>('dayEpoch') ?? 0;
        final type = row.read<String>('txType') ?? 'expense';
        final cents = row.read<int>('totalCents') ?? 0;
        map.putIfAbsent(day.toString(), () => {'expense': 0, 'income': 0});
        map[day.toString()]![type] = (map[day.toString()]![type] ?? 0) + cents;
      }
      final result = <TrendPoint>[];
      map.forEach((key, values) {
        result.add(TrendPoint(
          dayEpoch: int.parse(key),
          type: 'expense',
          totalCents: values['expense'] ?? 0,
        ));
        result.add(TrendPoint(
          dayEpoch: int.parse(key),
          type: 'income',
          totalCents: values['income'] ?? 0,
        ));
      });
      result.sort((a, b) => a.dayEpoch.compareTo(b.dayEpoch));
      return result;
    });
  }

  Future<int> countByCategory(String categoryId) =>
      (selectOnly(transactions)
            ..addColumns([transactions.id.count()])
            ..where(transactions.categoryId.equals(categoryId)))
          .map((row) => row.read(transactions.id.count()) ?? 0)
          .getSingle();

  // ---------- 映射 ----------

  TransactionsCompanion _toCompanion(Transaction t) {
    final now = DateTime.now();
    return TransactionsCompanion(
      id: Value(t.id),
      amountCents: Value(t.amountCents),
      type: Value(t.type.code),
      categoryId: Value(t.categoryId),
      date: Value(t.date),
      note: Value(t.note),
      merchant: Value(t.merchant),
      currency: Value(t.currency),
      source: Value(t.source.code),
      createdAt: Value(t.createdAt ?? now),
      updatedAt: Value(t.updatedAt ?? now),
      syncVersion: Value(t.syncVersion),
    );
  }

  Transaction _rowToTransaction(TransactionRow row) => Transaction(
        id: row.id,
        amountCents: row.amountCents,
        type: TransactionType.fromCode(row.type),
        categoryId: row.categoryId,
        date: row.date,
        note: row.note,
        merchant: row.merchant,
        currency: row.currency,
        source: TransactionSource.fromCode(row.source),
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
        syncVersion: row.syncVersion,
      );
}
