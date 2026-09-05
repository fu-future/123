import '../../data/models/enums.dart';

/// 单条解析结果（含失败原因，见 QA-F3）。
class ParsedBill {
  const ParsedBill({
    required this.amountCents,
    required this.type,
    this.date,
    this.merchant = '',
    this.note = '',
    this.suggestedCategoryId,
    this.isValid = true,
    this.parseError,
  });

  final int amountCents;
  final TransactionType type;
  final DateTime? date;
  final String merchant;
  final String note;
  final String? suggestedCategoryId;
  final bool isValid;
  final String? parseError;

  ParsedBill copyWith({
    int? amountCents,
    TransactionType? type,
    DateTime? date,
    String? merchant,
    String? note,
    String? suggestedCategoryId,
    bool? isValid,
    String? parseError,
  }) {
    return ParsedBill(
      amountCents: amountCents ?? this.amountCents,
      type: type ?? this.type,
      date: date ?? this.date,
      merchant: merchant ?? this.merchant,
      note: note ?? this.note,
      suggestedCategoryId: suggestedCategoryId ?? this.suggestedCategoryId,
      isValid: isValid ?? this.isValid,
      parseError: parseError ?? this.parseError,
    );
  }
}

/// 解析整体结果。
class ParseResult {
  const ParseResult({
    required this.bills,
    this.total = 0,
    this.succeeded = 0,
    this.skipped = 0,
    this.failed = 0,
  });

  final List<ParsedBill> bills;
  final int total;
  final int succeeded;
  final int skipped;
  final int failed;
}
