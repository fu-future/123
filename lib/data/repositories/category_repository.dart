import 'dart:async';

import 'package:uuid/uuid.dart';

import '../../core/utils/result.dart';
import '../local/database.dart';
import '../models/category.dart';
import '../models/enums.dart';

abstract interface class CategoryRepository {
  Stream<List<Category>> watchCategories([TransactionType? type]);
  Future<List<Category>> getAll([TransactionType? type]);
  Future<Result<Category>> addCategory(Category c);
  Future<Result<void>> updateCategory(Category c);

  /// 删除分类：账目迁移到 [fallbackCategoryId] 后再删，保证数据完整。
  Future<Result<void>> deleteCategory(String id, String fallbackCategoryId);
}

class DriftCategoryRepository implements CategoryRepository {
  DriftCategoryRepository(this._db);
  final AppDatabase _db;

  CategoryDao get _dao => _db.categoryDao;

  @override
  Stream<List<Category>> watchCategories([TransactionType? type]) =>
      _dao.watchAll(type);

  @override
  Future<List<Category>> getAll([TransactionType? type]) =>
      _dao.getAll(type);

  @override
  Future<Result<Category>> addCategory(Category c) async {
    try {
      final model = c.id.isEmpty
          ? Category(
              id: const Uuid().v4(),
              name: c.name,
              type: c.type,
              iconKey: c.iconKey,
              colorValue: c.colorValue,
              sortOrder: c.sortOrder,
              isBuiltIn: false,
            )
          : c;
      await _dao.insertCategory(model);
      return Result.ok(model);
    } catch (e) {
      return Result.failure('新增分类失败：$e');
    }
  }

  @override
  Future<Result<void>> updateCategory(Category c) async {
    try {
      await _dao.updateCategory(c);
      return Result.ok(null);
    } catch (e) {
      return Result.failure('更新分类失败：$e');
    }
  }

  @override
  Future<Result<void>> deleteCategory(
    String id,
    String fallbackCategoryId,
  ) async {
    try {
      // 事务迁移 + 删除逻辑在 CategoryDao 内实现（需访问生成的 companion 类型）。
      await _dao.deleteWithFallback(id, fallbackCategoryId);
      return Result.ok(null);
    } catch (e) {
      return Result.failure('删除分类失败：$e');
    }
  }
}
