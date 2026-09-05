import '../../data/models/enums.dart';

/// 分类器抽象接口：备注/商户文本 → categoryId（可 null = 默认其他）。
abstract interface class TransactionClassifier {
  Future<String?> classify(String text, TransactionType type);
}
