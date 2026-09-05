import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_app/core/utils/result.dart';

void main() {
  group('Result 语义', () {
    test('Ok', () {
      const r = Result<int>.ok(5);
      expect(r.isOk, isTrue);
      expect(r.isFailure, isFalse);
      expect(r.valueOrNull, 5);
      expect(r.errorOrNull, isNull);
    });
    test('Failure', () {
      const r = Result<int>.failure('boom');
      expect(r.isOk, isFalse);
      expect(r.isFailure, isTrue);
      expect(r.valueOrNull, isNull);
      expect(r.errorOrNull, 'boom');
    });
  });

  group('map', () {
    test('成功透传变换', () {
      const r = Result<int>.ok(4);
      expect(r.map((v) => v * 2).valueOrNull, 8);
    });
    test('失败透传错误', () {
      const r = Result<int>.failure('x');
      final mapped = r.map((v) => v * 2);
      expect(mapped.errorOrNull, 'x');
      expect(mapped.isFailure, isTrue);
    });
  });

  group('Result<void>', () {
    test('void ok 值', () {
      const r = Result<void>.ok(null);
      expect(r.isOk, isTrue);
    });
  });
}
