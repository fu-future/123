import 'dart:convert';
import 'dart:io';

import '../../data/models/category.dart';
import '../../data/models/enums.dart';
import '../../data/models/transaction.dart';

/// 导入结果。
class ImportResult {
  const ImportResult({
    required this.transactions,
    required this.categories,
    this.transactionsImported = 0,
    this.categoriesImported = 0,
  });

  final List<Transaction> transactions;
  final List<Category> categories;
  final int transactionsImported;
  final int categoriesImported;
}

/// 全量 JSON 导出/导入（备份恢复 + 同步载体）。
class JsonBackupService {
  JsonBackupService();

  String buildJson(List<Transaction> ts, List<Category> cs) {
    return jsonEncode(<String, Object>{
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'categories': cs
          .map((c) => {
                'id': c.id,
                'name': c.name,
                'type': c.type.code,
                'iconKey': c.iconKey,
                'colorValue': c.colorValue,
                'sortOrder': c.sortOrder,
                'isBuiltIn': c.isBuiltIn,
              })
          .toList(),
      'transactions': ts.map(_txToJson).toList(),
    });
  }

  ImportResult parseJson(String content) {
    final map = jsonDecode(content) as Map<String, dynamic>;
    final categories = (map['categories'] as List<dynamic>? ?? [])
        .map((e) {
          final m = e as Map<String, dynamic>;
          return Category(
            id: m['id'] as String,
            name: m['name'] as String,
            type: TransactionType.fromCode(m['type'] as String),
            iconKey: (m['iconKey'] as String?) ?? 'more_horiz',
            colorValue: (m['colorValue'] as num?)?.toInt() ?? 0xFF8FD9A8,
            sortOrder: (m['sortOrder'] as num?)?.toInt() ?? 0,
            isBuiltIn: (m['isBuiltIn'] as bool?) ?? false,
          );
        })
        .toList();
    final transactions = (map['transactions'] as List<dynamic>? ?? [])
        .map((e) => _txFromJson(e as Map<String, dynamic>))
        .toList();
    return ImportResult(
      transactions: transactions,
      categories: categories,
      transactionsImported: transactions.length,
      categoriesImported: categories.length,
    );
  }

  Map<String, Object?> _txToJson(Transaction t) => {
        'id': t.id,
        'amountCents': t.amountCents,
        'type': t.type.code,
        'categoryId': t.categoryId,
        'date': t.date.toIso8601String(),
        'note': t.note,
        'merchant': t.merchant,
        'currency': t.currency,
        'source': t.source.code,
      };

  Transaction _txFromJson(Map<String, dynamic> m) => Transaction(
        id: m['id'] as String,
        amountCents: (m['amountCents'] as num).toInt(),
        type: TransactionType.fromCode(m['type'] as String),
        categoryId: m['categoryId'] as String,
        date: DateTime.parse(m['date'] as String),
        note: (m['note'] as String?) ?? '',
        merchant: (m['merchant'] as String?) ?? '',
        currency: (m['currency'] as String?) ?? 'CNY',
        source: TransactionSource.fromCode(m['source'] as String?),
      );

  // ---------- 文件 IO ----------
  Future<void> exportToFile(
    File file,
    List<Transaction> ts,
    List<Category> cs,
  ) async {
    await file.writeAsString(buildJson(ts, cs), encoding: utf8);
  }

  Future<ImportResult> importFromFile(File file) async {
    final content = await file.readAsString(encoding: utf8);
    return parseJson(content);
  }
}
