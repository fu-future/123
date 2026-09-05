import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_app/data/import_parse/csv_bill_parser.dart';
import 'package:ledger_app/data/models/enums.dart';

void main() {
  final parser = CsvBillParser();

  test('中文表头识别', () {
    final csv = '时间,金额,类型,备注\n'
        '2024-01-05 12:00,35.50,支出,午餐\n'
        '2024-01-06 13:00,10000,收入,工资';
    final r = parser.parseCsv(csv).valueOrNull!;
    expect(r.succeeded, 2);
    expect(r.bills[0].amountCents, 3550);
    expect(r.bills[0].type, TransactionType.expense);
    expect(r.bills[1].type, TransactionType.income);
    expect(r.bills[1].amountCents, 1000000);
  });

  test('英文表头识别', () {
    final csv = 'date,amount,type,note\n'
        '2024/1/5,12.00,expense,coffee';
    final r = parser.parseCsv(csv).valueOrNull!;
    expect(r.bills.single.amountCents, 1200);
    expect(r.bills.single.type, TransactionType.expense);
  });

  test('引号转义（含逗号/中文）', () {
    final csv = '时间,金额,类型,备注\n'
        '2024-01-05,5.00,支出,"备注,含逗号"';
    final r = parser.parseCsv(csv).valueOrNull!;
    expect(r.bills.single.note, '备注,含逗号');
  });

  test('坏行跳过', () {
    final csv = '时间,金额,类型,备注\n'
        'a,b,c,d\n'
        '2024-01-05,0,支出,x\n'
        '2024-01-06,5.00,支出,y';
    final r = parser.parseCsv(csv).valueOrNull!;
    expect(r.succeeded, 1);
    expect(r.skipped, 2);
  });

  test('无收支列默认支出（QA-F10 约定）', () {
    final csv = '时间,金额,备注\n2024-01-05,50.00,x';
    final r = parser.parseCsv(csv).valueOrNull!;
    expect(r.bills.single.type, TransactionType.expense);
  });

  test('多种日期格式', () {
    final csv = '时间,金额\n2024年1月5日,10.00\n20240106,20.00';
    final r = parser.parseCsv(csv).valueOrNull!;
    expect(r.bills[0].date, DateTime(2024, 1, 5));
    expect(r.bills[1].date, DateTime(2024, 1, 6));
  });

  test('缺金额列失败', () {
    final csv = '备注,x\nfoo,bar';
    final r = parser.parseCsv(csv);
    expect(r.isFailure, isTrue);
  });
}
