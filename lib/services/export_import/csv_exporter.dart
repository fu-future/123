import '../../core/utils/money_utils.dart';
import '../../data/models/category.dart';
import '../../data/models/enums.dart';
import '../../data/models/transaction.dart';

/// 账目导出 CSV（RFC 4180，中文字段 UTF-8）。
class CsvExporter {
  CsvExporter();

  /// [categoryMap] 用于把 categoryId 映射成分类名；缺失回退空。
  String export(List<Transaction> ts, Map<String, Category> categoryMap) {
    final buffer = StringBuffer();
    buffer.writeln('日期,类型,分类,商户,金额(元),备注');

    for (final t in ts) {
      final fields = <String>[
        '${t.date.year}-${_two(t.date.month)}-${_two(t.date.day)}',
        t.type.isExpense ? '支出' : '收入',
        categoryMap[t.categoryId]?.name ?? '',
        _escapeCsv(t.merchant),
        MoneyUtils.formatYuanPlain(t.amountCents),
        _escapeCsv(t.note),
      ];
      buffer.writeln(fields.join(','));
    }
    return buffer.toString();
  }

  String _escapeCsv(String field) {
    if (field.contains(',') ||
        field.contains('"') ||
        field.contains('\n')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }

  static String _two(int n) => n.toString().padLeft(2, '0');
}
