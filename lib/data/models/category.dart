import 'enums.dart';

/// 分类模型：图标 key、颜色、类型、排序。
class Category {
  const Category({
    required this.id,
    required this.name,
    required this.type,
    required this.iconKey,
    required this.colorValue,
    this.sortOrder = 0,
    this.isBuiltIn = false,
  });

  final String id;
  final String name;
  final TransactionType type;
  final String iconKey;
  final int colorValue;
  final int sortOrder;
  final bool isBuiltIn;

  Category copyWith({
    String? name,
    TransactionType? type,
    String? iconKey,
    int? colorValue,
    int? sortOrder,
  }) {
    return Category(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      iconKey: iconKey ?? this.iconKey,
      colorValue: colorValue ?? this.colorValue,
      sortOrder: sortOrder ?? this.sortOrder,
      isBuiltIn: isBuiltIn,
    );
  }
}
