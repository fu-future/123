import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/import_parse/csv_bill_parser.dart';
import '../data/import_parse/parse_result.dart';
import '../data/import_parse/statement_parser.dart';

/// 导入流程状态。
class ImportState {
  const ImportState({
    this.bills = const [],
    this.error,
    this.importedCount,
    this.skippedCount = 0,
    this.excludedIndexes = const <int>{},
  });

  final List<ParsedBill> bills;
  final String? error;
  final int? importedCount;
  final int skippedCount;
  final Set<int> excludedIndexes;

  ImportState copyWith({
    List<ParsedBill>? bills,
    String? error,
    bool clearError = false,
    int? importedCount,
    int? skippedCount,
    Set<int>? excludedIndexes,
  }) {
    return ImportState(
      bills: bills ?? this.bills,
      error: clearError ? null : (error ?? this.error),
      importedCount: importedCount ?? this.importedCount,
      skippedCount: skippedCount ?? this.skippedCount,
      excludedIndexes: excludedIndexes ?? this.excludedIndexes,
    );
  }

  /// 显式清空（allow 清空，见 QA 复核 #3）。
  ImportState reset() => const ImportState();
}

class ImportController extends AsyncNotifier<ImportState> {
  final _textParser = StatementParser();
  final _csvParser = CsvBillParser();

  @override
  Future<ImportState> build() async => const ImportState();

  /// 解析文本账单。
  Future<void> parseText(String raw) async {
    final current = state.valueOrNull ?? const ImportState();
    final result = _textParser.parseText(raw);
    if (result.isFailure) {
      state = AsyncValue.data(current.copyWith(
        error: result.errorOrNull,
        clearError: true,
      ));
      return;
    }
    final bills = result.valueOrNull!;
    // QA-F3：失败行默认剔除。
    final excluded = <int>{};
    for (var i = 0; i < bills.length; i++) {
      if (!bills[i].isValid) excluded.add(i);
    }
    state = AsyncValue.data(current.copyWith(
      bills: bills,
      excludedIndexes: excluded,
      clearError: true,
    ));
  }

  /// 解析 CSV。
  Future<void> parseCsv(String raw) async {
    final current = state.valueOrNull ?? const ImportState();
    final result = _csvParser.parseCsv(raw);
    if (result.isFailure) {
      state = AsyncValue.data(current.copyWith(
        error: result.errorOrNull,
        clearError: true,
      ));
      return;
    }
    final parsed = result.valueOrNull!;
    final excluded = <int>{};
    for (var i = 0; i < parsed.bills.length; i++) {
      if (!parsed.bills[i].isValid) excluded.add(i);
    }
    state = AsyncValue.data(current.copyWith(
      bills: parsed.bills,
      excludedIndexes: excluded,
      skippedCount: parsed.skipped,
      clearError: true,
    ));
  }

  void toggleExclude(int index) {
    final s = state.valueOrNull ?? const ImportState();
    final set = Set<int>.from(s.excludedIndexes);
    if (!set.add(index)) set.remove(index);
    state = AsyncValue.data(s.copyWith(excludedIndexes: set));
  }

  void setSuggestedCategory(int index, String categoryId) {
    final s = state.valueOrNull ?? const ImportState();
    final bills = List<ParsedBill>.from(s.bills);
    bills[index] = bills[index].copyWith(suggestedCategoryId: categoryId);
    state = AsyncValue.data(s.copyWith(bills: bills));
  }

  Future<void> confirmImport() async {
    // 实际入库动作在 UI 层通过 transactionActionsProvider.addBatch 完成，
    // 此处在确认后清理状态避免重复触发。
    state = AsyncValue.data(const ImportState());
  }

  Future<void> clear() async {
    state = AsyncValue.data(const ImportState());
  }
}

final importProvider =
    AsyncNotifierProvider<ImportController, ImportState>(
  ImportController.new,
);
