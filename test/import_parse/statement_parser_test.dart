import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_app/data/import_parse/statement_parser.dart';
import 'package:ledger_app/data/models/enums.dart';

void main() {
  final parser = StatementParser();

  group('支付宝/微信句式', () {
    test('支付宝消费', () {
      final r = parser.parseText('支付宝消费58元');
      final b = r.valueOrNull!.single;
      expect(b.isValid, isTrue);
      expect(b.amountCents, 5800);
      expect(b.type, TransactionType.expense);
      expect(b.merchant, '支付宝');
    });
    test('带标签商户', () {
      final r = parser.parseText('商户：海底捞消费200元');
      expect(r.valueOrNull!.single.merchant, '海底捞');
    });
    test('向XX支付提取商户(微信)', () {
      final r = parser.parseText('微信支付：向美团外卖支付35.50元');
      expect(r.valueOrNull!.single.merchant, '美团外卖');
      expect(r.valueOrNull!.single.amountCents, 3550);
    });
  });

  group('银行短信句式', () {
    test('尾号/账户噪声去除（QA-F2）', () {
      final r =
          parser.parseText('【招商银行】您尾号1234的账户1月5日在美团消费58.50元');
      final b = r.valueOrNull!.single;
      expect(b.isValid, isTrue);
      expect(b.merchant, '美团');
      expect(b.amountCents, 5850);
      expect(b.date, isNotNull);
    });
    test('收入识别', () {
      final r = parser.parseText('【工行】您尾号1234收入转账存入10000元');
      expect(r.valueOrNull!.single.type, TransactionType.income);
    });
  });

  group('金额/时间提取', () {
    test('千分位与小数', () {
      final r = parser.parseText('消费￥1,234.56');
      expect(r.valueOrNull!.single.amountCents, 123456);
    });
    test('日期 yyyy-MM-dd', () {
      final r = parser.parseText('2024-01-05 消费58元');
      expect(r.valueOrNull!.single.date, DateTime(2024, 1, 5));
    });
  });

  group('坏行处理（QA-F3）', () {
    test('无金额行上报失败条目而非丢弃', () {
      final r = parser.parseText('今天天气不错');
      final b = r.valueOrNull!.single;
      expect(b.isValid, isFalse);
      expect(b.parseError, isNotNull);
      expect(r.valueOrNull!.length, 1);
    });
    test('空文本返回空列表', () {
      expect(parser.parseText('').valueOrNull, isEmpty);
      expect(parser.parseText('   ').valueOrNull, isEmpty);
    });
    test('多行混合：有效+失败条目上报', () {
      final r = parser.parseText('消费35.50元\n买东西\n支付宝消费58元\n周末散步');
      final bills = r.valueOrNull!;
      expect(bills.length, 4);
      final valid = bills.where((b) => b.isValid).toList();
      expect(valid.map((b) => b.amountCents), containsAll([3550, 5800]));
      expect(bills.where((b) => !b.isValid).length, 2);
    });
  });
}
