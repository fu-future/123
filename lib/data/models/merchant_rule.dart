/// 商户→分类映射规则模型。
class MerchantRule {
  const MerchantRule({
    required this.id,
    required this.keyword,
    required this.categoryId,
    this.priority = 0,
  });

  final String id;
  final String keyword;
  final String categoryId;
  final int priority;
}
