import 'package:csv/csv.dart';

import '../../core/utils/result.dart';
import '../models/enums.dart';
import 'parse_result.dart';

/// CSV 账单解析：识别表头列（金额/时间/收支/备注），逐行映射。
/// 坏行（非数字金额/0/短行/缺列）跳过，并在 ParseResult.skipped 统计（QA-F10 约定）。
class CsvBillParser {
  CsvBillParser();

  Result<ParseResult> parseCsv(String csvContent) {
    final rows = const CsvToListConverter(
      shouldParseNumbers: false,
      eol: '\n',
    ).convert(csvContent);

    if (rows.isEmpty) {
      return Result.ok(const ParseResult(bills: []));
    }

    final header = _normalizeHeader(rows.first);
    final amountIdx = header.indexOf('金额') != -1
        ? header.indexOf('金额')
        : _findHeaderIndex(header, const ['金额', '金额(元)', 'amount', 'money']);
    final dateIdx =
        _findHeaderIndex(header, const ['时间', '日期', '交易时间', 'date', 'time']);
    final typeIdx = _findHeaderIndex(
        header, const ['收支', '类型', '收/支', 'type', 'income_expense']);
    final noteIdx = _findHeaderIndex(
        header, const ['备注', '说明', '商品', 'note', 'remark']);

    if (amountIdx == -1) {
      return Result.failure('未找到金额列');
    }

    final bills = <ParsedBill>[];
    var succeeded = 0;
    var skipped = 0;

    for (var i = 1; i < rows.length; i++) {
      final row = rows[i];
      // 表头错位/缺列等坏行跳过。
      if (row.length <= amountIdx || row.length <= (dateIdx == -1 ? amountIdx : dateIdx)) {
        skipped++;
        continue;
      }
      final amountText = row[amountIdx].toString().trim();
      final cents = _parseCents(amountText);
      if (cents == null || cents <= 0) {
        skipped++;
        continue;
      }
      final type = _parseType(typeIdx == -1 ? '' : row[typeIdx].toString());
      final date = _parseDate(dateIdx == -1 ? '' : row[dateIdx].toString());
      final note = noteIdx == -1 ? '' : row[noteIdx].toString().trim();
      bills.add(ParsedBill(
        amountCents: cents,
        type: type,
        date: date,
        note: note,
      ));
      succeeded++;
    }

    return Result.ok(ParseResult(
      bills: bills,
      total: bills.length + skipped,
      succeeded: succeeded,
      skipped: skipped,
    ));
  }

  List<String> _normalizeHeader(List<dynamic> first) =>
      first.map((e) => e.toString().trim()).toList();

  int _findHeaderIndex(List<String> header, List<String> candidates) {
    for (var i = 0; i < header.length; i++) {
      final h = header[i].toLowerCase();
      if (candidates.any((c) => h.contains(c.toLowerCase()))) {
        return i;
      }
    }
    return -1;
  }

  int? _parseCents(String text) {
    final cleaned = text.replaceAll(RegExp(r'[¥￥,\s]'), '').trim();
    final value = double.tryParse(cleaned);
    if (value == null) return null;
    return (value * 100).round();
  }

  /// 无收支列时默认支出（QA-F10 现状约定）。
  TransactionType _parseType(String typeText) {
    final t = typeText.toLowerCase();
    if (t.contains('收入') || t.contains('收') || t.contains('income')) {
      return TransactionType.income;
    }
    if (t.contains('支出') || t.contains('支') || t.contains('expense')) {
      return TransactionType.expense;
    }
    return TransactionType.expense;
  }

  DateTime? _parseDate(String text) {
    final t = text.trim();
    if (t.isEmpty) return null;
    // 支持 2024-01-05 10:00、2024/1/5、2024年1月5日、20240105
    var m = RegExp(r'(\d{4})[年/\-.](\d{1,2})[月/\-.](\d{1,2})').firstMatch(t);
    if (m != null) {
      return DateTime(int.parse(m.group(1)!), int.parse(m.group(2)!),
          int.parse(m.group(3)!));
    }
    m = RegExp(r'(\d{4})(\d{2})(\d{2})').firstMatch(t);
    if (m != null) {
      return DateTime(int.parse(m.group(1)!), int.parse(m.group(2)!),
          int.parse(m.group(3)!));
    }
    return null;
  }
}
