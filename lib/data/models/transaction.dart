import 'enums.dart';

/// 账目不可变领域模型。金额以「分」整数存储。
class Transaction {
  const Transaction({
    required this.id,
    required this.amountCents,
    required this.type,
    required this.categoryId,
    required this.date,
    this.note = '',
    this.merchant = '',
    this.currency = 'CNY',
    this.source = TransactionSource.manual,
    this.createdAt,
    this.updatedAt,
    this.syncVersion,
  });

  final String id;
  final int amountCents;
  final TransactionType type;
  final String categoryId;

  /// 记账日期（本地语义，存取转 UTC epoch）。
  final DateTime date;
  final String note;
  final String merchant;
  final String currency;
  final TransactionSource source;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? syncVersion;

  Transaction copyWith({
    int? amountCents,
    TransactionType? type,
    String? categoryId,
    DateTime? date,
    String? note,
    String? merchant,
    String? currency,
    TransactionSource? source,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? Function()? syncVersion,
  }) {
    return Transaction(
      id: id,
      amountCents: amountCents ?? this.amountCents,
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      date: date ?? this.date,
      note: note ?? this.note,
      merchant: merchant ?? this.merchant,
      currency: currency ?? this.currency,
      source: source ?? this.source,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncVersion:
          syncVersion != null ? syncVersion() : this.syncVersion,
    );
  }
}
