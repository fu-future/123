import '../../core/utils/result.dart';
import '../models/enums.dart';
import 'parse_result.dart';

/// 非结构化账单文本解析（短信/流水句式）。纯 Dart，可独立单元测试。
///
/// 修复项：
/// - QA-F2：商户提取 4 级优先级，去除「尾号/账户/日期」等前缀噪声与支付渠道。
/// - QA-F3：金额提取失败的行生成 `isValid=false + parseError` 条目上报，而非静默丢弃。
class StatementParser {
  StatementParser();

  // 金额（优先「...元」，避免误抓尾号/日期等无单位数字）。
  static final RegExp _amountWithUnit = RegExp(
      r'(?:¥|￥)?([0-9][0-9,]*(?:\.[0-9]{1,2})?)元');
  static final RegExp _amountGeneric = RegExp(
      r'(?:¥|￥)?([0-9][0-9,]*(?:\.[0-9]{1,2})?)');

  // 时间：yyyy-MM-dd / yyyy年M月d日 / M月d日（无年份默认今年）。
  static final RegExp _datePattern = RegExp(
    r'(20\d{2})[年/\-.](\d{1,2})[月/\-.](\d{1,2})日?'
    r'|(\d{1,2})月(\d{1,2})日',
  );

  static final RegExp _tagMerchant = RegExp(
      r'(?:商户|商家|收款方|交易对象)[:：\s]*([\u4e00-\u9fa5A-Za-z0-9*]{2,20}?)'
      r'(?=消费|支付|购买|付款|扣款|支出|元|[0-9]|$)');
  static final RegExp _toMerchant = RegExp(
      r'向([\u4e00-\u9fa5A-Za-z0-9*]{2,20}?)(?:支付|付款|转账)');
  static final RegExp _anchorMerchant = RegExp(
      r'(?:在|于)([\u4e00-\u9fa5A-Za-z0-9*]{2,20}?)(?:消费|支付|购买|付款|扣款|支出)');
  static final RegExp _looseMerchant = RegExp(
      r'([\u4e00-\u9fa5A-Za-z0-9*]{2,20}?)(?:消费|支付|购买|付款|扣款)');

  static final RegExp _incomeHint = RegExp(r'收入|入账|存入|工资入账|转[入来]');
  static final RegExp _incomePlus = RegExp(r'\+');

  Result<List<ParsedBill>> parseText(String rawText) {
    final lines = rawText
        .split('\n')
        .where((l) => l.trim().isNotEmpty)
        .toList();
    final bills = <ParsedBill>[];
    for (final line in lines) {
      bills.add(_parseLine(line.trim()));
    }
    return Result.ok(bills);
  }

  ParsedBill _parseLine(String line) {
    final amountWithUnit = _amountWithUnit.firstMatch(line);
    final amountMatch = amountWithUnit ?? _amountGeneric.firstMatch(line);
    // QA-F3：无金额行上报失败条目，不再静默丢弃。
    if (amountMatch == null) {
      return ParsedBill(
        amountCents: 0,
        type: TransactionType.expense,
        note: line,
        isValid: false,
        parseError: '未能识别金额',
      );
    }
    final amountCents = _toCents(amountMatch.group(1)!);
    final date = _extractDate(line);
    final type = _incomeHint.hasMatch(line) || _incomePlus.hasMatch(line)
        ? TransactionType.income
        : TransactionType.expense;
    final merchant = _extractMerchant(line);
    return ParsedBill(
      amountCents: amountCents,
      type: type,
      date: date,
      merchant: merchant,
      note: line,
    );
  }

  /// QA-F2：4 级优先级提取商户。
  String _extractMerchant(String line) {
    final tag = _tagMerchant.firstMatch(line);
    if (tag != null) return tag.group(1)!;
    final to = _toMerchant.firstMatch(line);
    if (to != null) return to.group(1)!;
    final anchor = _anchorMerchant.firstMatch(line);
    if (anchor != null) return anchor.group(1)!;
    final loose = _looseMerchant.firstMatch(line);
    if (loose != null) return loose.group(1)!;
    return '';
  }

  DateTime? _extractDate(String line) {
    final m = _datePattern.firstMatch(line);
    if (m == null) return null;
    if (m.group(1) != null) {
      return DateTime(int.parse(m.group(1)!), int.parse(m.group(2)!),
          int.parse(m.group(3)!));
    }
    return DateTime(DateTime.now().year, int.parse(m.group(4)!),
        int.parse(m.group(5)!));
  }

  int _toCents(String amount) {
    final cleaned = amount.replaceAll(',', '');
    final value = double.tryParse(cleaned) ?? 0;
    return (value * 100).round();
  }
}
