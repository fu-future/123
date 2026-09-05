import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_app/core/constants/app_constants.dart';
import 'package:ledger_app/data/models/enums.dart';
import 'package:ledger_app/services/classifier/rule_classifier.dart';

void main() {
  final classifier = RuleClassifier();

  test('美团 → 餐饮(支出)', () async {
    final id = await classifier.classify('美团外卖 订单', TransactionType.expense);
    expect(id, BuiltInCategoryIds.food);
  });
  test('工资 → 工资(收入)', () async {
    final id = await classifier.classify('工资入账', TransactionType.income);
    expect(id, BuiltInCategoryIds.salary);
  });
  test('滴滴 → 交通(支出)', () async {
    final id = await classifier.classify('滴滴出行', TransactionType.expense);
    expect(id, BuiltInCategoryIds.transport);
  });
  test('类型不匹配返回 null', () async {
    final id = await classifier.classify('工资入账', TransactionType.expense);
    expect(id, isNull);
  });
  test('空输入返回 null', () async {
    expect(await classifier.classify('', TransactionType.expense), isNull);
  });
  test('关键词命中优先于商户', () async {
    final id = await classifier.classify('美团外卖', TransactionType.expense);
    expect(id, BuiltInCategoryIds.food);
  });
}
