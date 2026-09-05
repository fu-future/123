import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../../core/constants/app_constants.dart';
import '../models/category.dart';
import '../models/enums.dart';
import '../models/transaction.dart';
import 'tables.dart';

part 'database.g.dart';

/// 本地唯一数据源：Drift(SQLite)。连接经 [driftDatabase] 初始化，三端可用。
/// 注意：DAO 与数据库声明在同一文件(同一库)，保证 drift 生成的
/// $xxxTable / xxxCompanion / xxxRow 等符号对 DAO 可见。
@DriftDatabase(
  tables: [
    Transactions,
    Categories,
    MerchantRules,
  ],
  daos: [
    TransactionDao,
    CategoryDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await categoryDao.seedBuiltInCategories();
        },
      );

  /// 便捷工厂：三端（Android/iOS/Windows）默认连接。
  static AppDatabase create() {
    return AppDatabase(driftDatabase(name: 'ledger_app'));
  }
}

// ====================================================================
// TransactionDao
// ====================================================================

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
  const TrendPoint({
    required this.dayEpoch,
    required this.type,
    required this.totalCents,
  });
  final int dayEpoch;
  final String type;
  final int totalCents;
}

/// 月度概览。
class MonthlySummary {
  const MonthlySummary({
    required this.incomeCents,
    required this.expenseCents,
  });
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
      final catOk = categoryId == null
          ? const Constant(true)
          : t.categoryId.equals(categoryId);
      final typeOk =
          type == null ? const Constant(true) : t.type.equals(type.code);
      return inRange & catOk & typeOk;
    });
    return query.watch().map((rows) => rows.map(_rowToTransaction).toList());
  }

  /// 月度概览：本月收入合计 / 支出合计 / 结余（CASE WHEN 下推聚合）。
  /// 注意：drift 的 dateTime 列默认按「秒」存储，原生 SQL 必须用秒比较。
  Stream<MonthlySummary> watchMonthlySummary(int year, int month) {
    final start =
        DateTime(year, month, 1).toUtc().millisecondsSinceEpoch ~/ 1000;
    final next =
        DateTime(year, month + 1, 1).toUtc().millisecondsSinceEpoch ~/ 1000;
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
    final s = start.toUtc().millisecondsSinceEpoch ~/ 1000;
    final e = end.toUtc().millisecondsSinceEpoch ~/ 1000;
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
      readsFrom: {transactions, attachedDatabase.categories},
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

  /// 趋势聚合：按「天」分组（drift 日期列为秒，取天键后换算成毫秒供图表展示）。
  Stream<List<TrendPoint>> watchTrendAggregation(
    DateTime start,
    DateTime end,
  ) {
    final s = start.toUtc().millisecondsSinceEpoch ~/ 1000;
    final e = end.toUtc().millisecondsSinceEpoch ~/ 1000;
    final query = customSelect(
      '''
      SELECT
        CAST(date / 86400 AS INTEGER) AS dayKey,
        type AS txType,
        SUM(amount_cents) AS totalCents
      FROM transactions
      WHERE date >= ? AND date < ?
      GROUP BY CAST(date / 86400 AS INTEGER), type
      ORDER BY CAST(date / 86400 AS INTEGER) ASC
      ''',
      variables: [Variable(s), Variable(e)],
      readsFrom: {transactions},
    );
    return query.watch().map((rows) {
      final map = <String, Map<String, int>>{};
      for (final row in rows) {
        final day = row.read<int>('dayKey') ?? 0;
        final type = row.read<String>('txType') ?? 'expense';
        final cents = row.read<int>('totalCents') ?? 0;
        map.putIfAbsent(day.toString(), () => {'expense': 0, 'income': 0});
        map[day.toString()]![type] = (map[day.toString()]![type] ?? 0) + cents;
      }
      final result = <TrendPoint>[];
      map.forEach((key, values) {
        // 天键(UTC 日序号) → 当天 0 点的毫秒时间戳，供图表取「几号」。
        final dayMs = int.parse(key) * 86400000;
        result.add(TrendPoint(
          dayEpoch: dayMs,
          type: 'expense',
          totalCents: values['expense'] ?? 0,
        ));
        result.add(TrendPoint(
          dayEpoch: dayMs,
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

// ====================================================================
// CategoryDao
// ====================================================================

@DriftAccessor(tables: [Categories])
class CategoryDao extends DatabaseAccessor<AppDatabase> with _$CategoryDaoMixin {
  CategoryDao(super.db);

  /// 监听某类型（或全部）分类，按 sortOrder 升序。
  Stream<List<Category>> watchAll([TransactionType? type]) {
    final query = select(categories)
      ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]);
    if (type != null) {
      query.where((t) => t.type.equals(type.code));
    }
    return query.watch().map(
          (rows) => rows.map(_toModel).toList(),
        );
  }

  Future<List<Category>> getAll([TransactionType? type]) async {
    final query = select(categories)
      ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]);
    if (type != null) {
      query.where((t) => t.type.equals(type.code));
    }
    final rows = await query.get();
    return rows.map(_toModel).toList();
  }

  Future<void> insertCategory(Category c) {
    return into(categories).insert(
      CategoriesCompanion(
        id: Value(c.id),
        name: Value(c.name),
        type: Value(c.type.code),
        iconKey: Value(c.iconKey),
        colorValue: Value(c.colorValue),
        sortOrder: Value(c.sortOrder),
        isBuiltIn: Value(c.isBuiltIn),
      ),
    );
  }

  Future<void> updateCategory(Category c) {
    return (update(categories)..where((t) => t.id.equals(c.id))).write(
      CategoriesCompanion(
        name: Value(c.name),
        iconKey: Value(c.iconKey),
        colorValue: Value(c.colorValue),
        sortOrder: Value(c.sortOrder),
      ),
    );
  }

  Future<void> deleteCategory(String id) =>
      (delete(categories)..where((t) => t.id.equals(id))).go();

  /// 删除分类：先迁移该分类下的账目到 [fallbackCategoryId]，再删除分类。
  Future<void> deleteWithFallback(String id, String fallbackCategoryId) async {
    await transaction(() async {
      await (update(attachedDatabase.transactions)
            ..where((t) => t.categoryId.equals(id)))
          .write(TransactionsCompanion(categoryId: Value(fallbackCategoryId)));
      await (delete(categories)..where((t) => t.id.equals(id))).go();
    });
  }

  /// 该分类下账目数（用于删除前校验）。
  Future<int> countTransactions(String categoryId) {
    final tx = attachedDatabase.transactions;
    final countExpr = tx.id.count();
    return (selectOnly(tx)
          ..addColumns([countExpr])
          ..where(tx.categoryId.equals(categoryId)))
        .map((row) => row.read(countExpr) ?? 0)
        .getSingle();
  }

  /// 写入内置分类种子（首次启动；固定 UUID + insertOrIgnore 幂等）。
  Future<void> seedBuiltInCategories() async {
    final rows = <CategoriesCompanion>[
      // 支出
      _seed('餐饮', TransactionType.expense, BuiltInCategoryIds.food,
          'restaurant', 0xFFFFB3BA),
      _seed('交通', TransactionType.expense, BuiltInCategoryIds.transport,
          'directions_bus', 0xFF9BC7F0),
      _seed('购物', TransactionType.expense, BuiltInCategoryIds.shopping,
          'shopping_bag', 0xFFC6A8F7),
      _seed('居住', TransactionType.expense, BuiltInCategoryIds.housing,
          'home', 0xFFF5B88C),
      _seed('娱乐', TransactionType.expense, BuiltInCategoryIds.entertainment,
          'movie', 0xFF9AE0E0),
      _seed('医疗', TransactionType.expense, BuiltInCategoryIds.medical,
          'local_hospital', 0xFFF2A98A),
      _seed('教育', TransactionType.expense, BuiltInCategoryIds.education,
          'school', 0xFFB8D98A),
      _seed('其他', TransactionType.expense, BuiltInCategoryIds.otherExpense,
          'more_horiz', 0xFFE8C1A0),
      // 收入
      _seed('工资', TransactionType.income, BuiltInCategoryIds.salary,
          'work', 0xFF8FD9A8),
      _seed('理财', TransactionType.income, BuiltInCategoryIds.investment,
          'trending_up', 0xFFF7D488),
      _seed('奖金', TransactionType.income, BuiltInCategoryIds.bonus,
          'emoji_events', 0xFFF7A8B8),
      _seed('其他', TransactionType.income, BuiltInCategoryIds.otherIncome,
          'wallet', 0xFF9BC7F0),
    ];
    await batch((b) {
      b.insertAll(categories, rows, mode: InsertMode.insertOrIgnore);
    });
  }

  CategoriesCompanion _seed(String name, TransactionType type, String id,
      String iconKey, int color) {
    return CategoriesCompanion.insert(
      id: id,
      name: name,
      type: type.code,
      iconKey: Value(iconKey),
      colorValue: Value(color),
      sortOrder: Value(type.isExpense ? 0 : 100),
      isBuiltIn: const Value(true),
    );
  }

  Category _toModel(CategoryRow row) => Category(
        id: row.id,
        name: row.name,
        type: TransactionType.fromCode(row.type),
        iconKey: row.iconKey,
        colorValue: row.colorValue,
        sortOrder: row.sortOrder,
        isBuiltIn: row.isBuiltIn,
      );
}
