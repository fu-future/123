import 'package:drift/drift.dart';

import '../../../core/constants/app_constants.dart';
import '../../models/category.dart';
import '../../models/enums.dart';
import '../tables.dart';

part 'category_dao.g.dart';

@DriftAccessor(tables: [Categories])
class CategoryDao extends DatabaseAccessor<AppDatabase>
    with _$CategoryDaoMixin {
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

  /// 该分类下账目数（用于删除前校验）。
  Future<int> countTransactions(String categoryId) {
    final countExpr = transactions.id.count();
    return (selectOnly(transactions)
          ..addColumns([countExpr])
          ..where(transactions.categoryId.equals(categoryId)))
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
      iconKey: iconKey,
      colorValue: color,
      sortOrder: type.isExpense ? 0 : 100,
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
