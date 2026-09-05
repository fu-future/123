import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_app/services/export_import/csv_exporter.dart';
import 'package:ledger_app/data/models/category.dart';
import 'package:ledger_app/data/models/enums.dart';
import 'package:ledger_app/data/models/transaction.dart';

Category _cat(String id, String name) => Category(
      id: id,
      name: name,
      type: TransactionType.expense,
      iconKey: 'restaurant',
      colorValue: 0xFF8FD9A8,
    );

void main() {
  final exporter = CsvExporter();

  test('表头', () {
    final csv = exporter.export([], {});
    expect(csv.split('\n').first, '日期,类型,分类,商户,金额(元),备注');
  });

  test('行格式与分类名映射', () {
    final cat = _cat('c1', '餐饮');
    final t = Transaction(
      id: 'id1',
      amountCents: 3550,
      type: TransactionType.expense,
      categoryId: 'c1',
      date: DateTime(2024, 1, 5),
      merchant: '美团',
      note: '午餐',
    );
    final csv = exporter.export([t], {'c1': cat});
    final lines = csv.trim().split('\n');
    expect(lines[1], '2024-01-05,支出,餐饮,美团,35.50,午餐');
  });

  test('分类缺失回退空', () {
    final t = Transaction(
      id: 'x',
      amountCents: 500,
      type: TransactionType.income,
      categoryId: 'gone',
      date: DateTime(2024, 2, 3),
    );
    final csv = exporter.export([t], {});
    expect(csv, contains('2024-02-03,收入,,,5.00,'));
  });

  test('RFC 4180 引号转义', () {
    final t = Transaction(
      id: 'q',
      amountCents: 100,
      type: TransactionType.expense,
      categoryId: 'c1',
      date: DateTime(2024, 1, 1),
      note: '含,逗号"和引号',
    );
    final csv = exporter.export([t], {});
    expect(csv, contains('"含,逗号""和引号"'));
  });

  test('大金额无损往返', () {
    final t = Transaction(
      id: 'big',
      amountCents: 1000000000,
      type: TransactionType.expense,
      categoryId: 'c1',
      date: DateTime(2024, 1, 1),
    );
    final csv = exporter.export([t], {});
    expect(csv, contains('10,000,000.00'));
  });
}
