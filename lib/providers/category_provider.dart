import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/category.dart';
import '../data/models/enums.dart';
import 'repository_provider.dart';

/// 某类型（或全部）分类 Stream。
final categoryListProvider =
    StreamProvider.family<List<Category>, TransactionType?>((ref, type) {
  return ref.watch(categoryRepositoryProvider).watchCategories(type);
});

/// 全部分类 Stream（图表/导入用，含 color/icon）。
final allCategoriesProvider = StreamProvider<List<Category>>(
  (ref) => ref.watch(categoryRepositoryProvider).watchCategories(),
);

/// 用 categoryId 快速查分类对象（供列表渲染 icon/颜色）。依赖 allCategoriesProvider。
final categoryByIdProvider =
    Provider.family<Category?, String>((ref, id) {
  final list = ref.watch(allCategoriesProvider).valueOrNull ?? const [];
  for (final c in list) {
    if (c.id == id) return c;
  }
  return null;
});

/// 分类增删改动作。
class CategoryActions extends AsyncNotifier<String?> {
  @override
  Future<String?> build() async => null;

  Future<String?> _run(Future<Object?> Function() fn) async {
    final r = await fn();
    return r is String && r.isNotEmpty ? r : null;
  }

  Future<String?> add(Category c) async {
    return _run(() async {
      final r = await ref.read(categoryRepositoryProvider).addCategory(c);
      return r.errorOrNull;
    });
  }

  Future<String?> update(Category c) async {
    return _run(() async {
      final r = await ref.read(categoryRepositoryProvider).updateCategory(c);
      return r.errorOrNull;
    });
  }

  Future<String?> delete(Category c, String fallbackId) async {
    return _run(() async {
      final r = await ref
          .read(categoryRepositoryProvider)
          .deleteCategory(c.id, fallbackId);
      return r.errorOrNull;
    });
  }
}

final categoryActionsProvider = AsyncNotifierProvider<CategoryActions, String?>(
  CategoryActions.new,
);
