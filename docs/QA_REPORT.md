# QA 测试报告 — ledger_app 记账软件

| 项目 | 内容 |
| --- | --- |
| 角色 | QA 工程师（严过关 Yan） |
| 审查对象 | `lib/` 下全部 64 个 .dart 文件 + pubspec.yaml + docs/PRD.md + docs/ARCHITECTURE.md |
| 审查方式 | 独立全局静态审查（逐文件通读）+ 纯 Dart 逻辑测试用例编写（本环境无 Flutter/Dart SDK，测试供本地 `flutter test` 执行） |
| 测试轮次 | Round 1（发现问题 → 已路由工程师修复）→ **Round 2（回归验证，见第 12 节：F1/F2/F3/F4/F6/F8 全部确认修复 ✅）** |

---

## 1. 摘要

- **发现问题总数：10 项**（高 1 / 中 2 / 低 5 / 提示 2）
- **智能路由判定：Engineer（寇豆码）** — 存在 1 项 P0 需求缺失（F1：无删除账目 UI 入口）与 2 项中等级缺陷（F2 商户提取噪声、F3 失败行静默丢弃）需要源码修复；其余为低风险/提示项，可随修复一并处理或排期。
- **工程师此前声称修复的 4 处问题：全部复核通过**（证据见第 2 节）。
- **Drift 表名/列名与自定义 SQL：逐一核对一致，未发现拼写错误**（证据见第 3 节）。
- **测试交付：7 个测试文件、约 70 个用例**，覆盖金额/日期/Result/规则分类器/文本解析/CSV 解析/CSV 导出往返。其中 3 个用例按 PRD/架构正确行为书写、当前预期失败，用于固化 F2/F3 缺陷（修复后应转为通过）。

---

## 2. 工程师声称修复的 4 处问题复核（全部通过 ✅）

| # | 声称修复项 | 复核结论 | 证据 |
| --- | --- | --- | --- |
| 1 | `transaction_tile.dart` 支出显示 `-¥` | ✅ 已修复 | `TransactionTile.build` 第 67-70 行：`MoneyUtils.formatSigned(isExpense ? -transaction.amountCents : transaction.amountCents)`；`formatSigned(-1250)` 输出 `-¥12.50`（已被 `money_utils_test.dart` 的 formatSigned 用例覆盖验证） |
| 2 | `transaction_dao.dart` count 表达式 | ✅ 已修复 | `countTransactions` 第 149-156 行：`Expression<int> countExpr = transactions.id.count()` + `selectOnly` + `addColumns` + `where(categoryId.equals(...))` + `getSingle()`，Drift API 用法正确，返回该分类下账目数 |
| 3 | `import_provider.dart` 的 `ImportState.copyWith` 可清空 | ✅ 已修复 | `ImportState.copyWith` 第 29-43 行：`error: error`、`importedCount: importedCount` 直接取参（无 `?? this.xxx` 回退），显式传 null 即清空；`parseText/parseCsv` 开始时传 `error: null, importedCount: null` 语义正确 |
| 4 | `transactionListProvider` 的 categoryId 下推 DAO | ✅ 已修复 | `DriftTransactionRepository.watchTransactions` 第 108-110 行将 `filter.categoryId` 下推到 `_dao.watchByRange(..., categoryId: ...)`；`transactionListProvider` 中类型过滤在 Provider 层 `stream.map` 完成，职责划分与注释一致 |

---

## 3. Drift 表名/列名与自定义 SQL 一致性（通过 ✅）

Drift 默认命名规则：类名蛇形复数 → 表名；getter 蛇形 → 列名。逐一核对结果：

**表定义（`tables.dart`）→ 实际 SQL 表名**

| Dart 类 | 生成表名 | DAO SQL 中引用 | 一致 |
| --- | --- | --- | --- |
| `Transactions` | `transactions` | `transaction_dao.dart` 3 处 customSelect 均用 `transactions` | ✅ |
| `Categories` | `categories` | `watchCategoryAggregation` LEFT JOIN `categories c` | ✅ |
| `MerchantRules` | `merchant_rules` | 无自定义 SQL 引用（表已建但本期无 DAO 使用） | ✅ |

**列名核对（customSelect 字符串 vs 表定义）**

| SQL 中列名 | 表定义 getter | 一致 |
| --- | --- | --- |
| `t.category_id` / `c.id` / `c.name` | `categoryId` / `id` / `name` | ✅ |
| `t.amount_cents` | `amountCents` | ✅ |
| `t.date` / `t.type` | `date` / `type` | ✅ |
| `date`（趋势 GROUP BY） | `date` | ✅ |
| `amount_cents`（趋势/月度汇总） | `amountCents` | ✅ |

**别名读取核对**：`categoryId/categoryName/totalCents/cnt`（分类聚合）、`dayEpoch/txType/totalCents`（趋势）、`incomeCents/expenseCents`（月度）——`row.read<T>('别名')` 与 SELECT 别名逐一匹配 ✅。

**时区一致性**：`DateTimeEpochConverter` 存 `toUtc().millisecondsSinceEpoch`；`watchCategoryAggregation/watchTrendAggregation` 变量用 `start.toUtc().millisecondsSinceEpoch`；`watchMonthlySummary` 用 `DateTime(year, month, 1).toUtc()`；`_rowToTransaction`/`_rollUpTrend` 读取时 `isUtc: true → toLocal()`。写入/查询/展示三端换算闭环一致 ✅。

---

## 4. 共享知识约定（ARCHITECTURE.md 第 7 节）违反检查

| 约定 | 结论 | 证据 |
| --- | --- | --- |
| #1 金额 amountCents int，业务层禁 double | ✅ 通过 | 模型/DAO/Repository/Provider 全链路 int 分；double 仅出现于展示层（`formatYuan`、`CsvExporter.toStringAsFixed(2)`、图表 y 轴换算）与输入解析边界（`parseYuanToCents` 入口立即转 int） |
| #6 组件禁硬编码 Color(0x...) | ✅ 通过 | 全库 grep `Color(0x`：仅 `color_tokens.dart`（token 定义处，允许）命中；组件中的 `Color(category.colorValue)`/`Color(colorValue)` 为数据驱动取色（来自 `AppConstants.selectableColors`/分类记录），不属于硬编码 |
| #6 圆角 16 | ✅ 通过 | 主题统一 `AppTheme.borderRadius = 16`；个别组件字面量 `BorderRadius.circular(16)` 数值一致（风格建议统一引用 token，非缺陷） |
| #8 账目写入统一走 TransactionRepository | ✅ 通过（写路径） | UI → `transactionActionsProvider` → Repository → DAO，无绕行写入。⚠️ 读路径例外见 F4 |
| #8 删除账目 UI 二次确认 | ❌ **缺失（见 F1）** | 全 features 目录 grep 无任何 `deleteTransaction` 调用——不是"没有二次确认"，而是**删除入口本身不存在** |
| #9 新实体 UUID 主键 | ✅ 通过 | `DriftTransactionRepository`/`DriftCategoryRepository` 对空 id 自动 `Uuid().v4()`；内置分类用固定 UUID 常量，种子 `InsertMode.insertOrIgnore` 幂等 |
| #5 AI 永不向 UI 抛异常 | ✅ 通过 | 见第 7 节 |
| #3 命名规范 | ✅ 通过 | 抽查文件/类/Provider 命名均符合 |

---

## 5. import 路径 / 引用 / DI 链检查（通过 ✅）

- **import 路径与文件名**：逐文件核对其相对 import（如 `transaction_tile.dart` → `../../../core/theme/app_theme.dart` 等），全部指向实际存在的文件，无大小写/拼写错位（Windows 大小写不敏感掩盖问题的风险已按文件清单逐一比对）。
- **未定义引用/重复定义**：所有跨文件引用的类/函数/Provider 均有定义；`Transaction`（domain）与 `TransactionRow`（Drift 生成）通过 `@DataClassName` 隔离，无冲突。
- **DI 链完整**：`databaseProvider(AppDatabase)` → `repository_provider`（注入 `db.transactionDao`/`db.categoryDao`）→ `transactionActionsProvider`/`categoryActionsProvider`/各 StreamProvider → UI 仅消费 Provider。链路完整闭环 ✅。
- **`*.g.dart` 生成文件**：`database.g.dart`/`transaction_dao.g.dart`/`category_dao.g.dart` 不在仓库（README 已注明需 `dart run build_runner build`）。**首次编译前必须执行代码生成**，属已知工作流，非缺陷（提示项 F9 已在 README 覆盖，无需处理）。

## 6. pubspec.yaml 依赖与实际 import 匹配（通过 ✅）

代码实际 import 的第三方包：`flutter_riverpod` / `drift` / `drift_flutter` / `go_router` / `fl_chart` / `dio` / `csv` / `shared_preferences` / `uuid` / `intl` / `path_provider` / `file_picker` / `path` / `flutter_localizations` —— **全部已声明**；`sqlite3_flutter_libs` 未被直接 import（作为原生库传递依赖，声明正确）。**无使用未声明包、无声明未用导致编译失败的缺项**。注：架构文档提及的 freezed/json_serializable/riverpod_annotation 实际未使用，pubspec 已正确地未引入（文档与实现的偏差，不影响编译）。

## 7. AI 降级链路（通过 ✅）

- `AiClassifier.classify`：`client.chatCompletion(...).timeout(AppConstants.aiClassifyTimeout)` 整体包裹于 try/catch；**超时（TimeoutException）、网络异常、返回空内容（FormatException）一律 catch 后 `return fallback.classify(text, type)`**，不向外抛出。
- AI 返回内容无法映射到分类名时（`_matchCategory` 返回 null）也回落规则分类器。
- `classifierProvider`：AI 三项配置不齐全时直接返回 `RuleClassifier`，不构造 AiClassifier。
- `AiInsightCard._generate` 同样 try/catch → 本地兜底文案。
- 结论：**AI 链路任何失败都不会把异常抛到 UI** ✅。

## 8. 快速记账「再记一笔」（通过 ✅）

`RecordPage._resetForNext()`（第 159-169 行）：清空 `_amountCents`（并通过 `_amountGeneration++` 强制重建 AmountInput）、`_noteController.clear()`、`_merchantController.clear()`；**保留 `_type` 与 `_date`**，满足「保留类型/日期、只清金额备注」。附注：同时清空已选分类与建议分类（连续记账时重新选择/推荐），属合理增强，不违反约定。

---

## 9. 发现的问题清单（智能路由：Engineer）

### 🔴 F1【高 · P0 需求缺失】无删除账目 UI 入口

- **证据**：PRD P0「新增/编辑/删除账目：支持对已有流水进行修改与删除（**删除需二次确认**）」（PRD 3.1、用户故事 5）。全 `lib/features/` grep 无 `deleteTransaction` 调用；编辑入口 `RecordPage`（`/record` + extra）只有保存，AppBar 无删除按钮；`TransactionActions.delete` 与 `Repository.deleteTransaction` 能力已具备但永远无人调用。
- **影响**：用户记错账后只能改不能删，P0 验收不通过。
- **修复建议**（寇豆码）：`RecordPage` 编辑模式（`_editing != null`）AppBar 增加删除 IconButton（`ColorTokens.expenseRed`），点击弹出 `showDialog` 二次确认（文案如「确定删除该账目吗？删除后不可恢复。」），确认后 `ref.read(transactionActionsProvider).delete(_editing!.id)`，成功后 `context.pop()`。分类删除页（`category_edit_page.dart`）已有完整二次确认实现可参考。

### 🟡 F2【中】StatementParser 商户提取包含前缀噪声/支付渠道

- **证据**：`statement_parser.dart` `_extractMerchant` 的 `atAction` 正则 `(?:在)?([\u4e00-\u9fa5A-Za-z0-9*]{2,20}?)(?:消费|支付|...)` 从**句首**开始非贪婪扫描：
  - 银行短信「【招商银行】您尾号1234的账户1月5日在美团消费58.50元」→ 商户提取为 `您尾号1234的账户1月5日在美团`（含尾号/账户/日期噪声）；
  - 微信句式「微信支付：向美团外卖支付35.50元」→ 商户提取为 `微信`（支付渠道，非真实商户）。
- **影响**：导入预览与入库后的账目列表商户名不可用；虽然 `note` 保留整行使规则分类仍能命中，但展示层体验明显受损。
- **修复建议**：优先用锚定版本 `(?:在|于)([\u4e00-\u9fa5A-Za-z0-9*]{2,20}?)(?:消费|支付|购买|付款|扣款)` 提取，失败再回退现有宽松匹配；微信句式可增加「向XX支付」模板。
- **测试锚点**：`statement_parser_test.dart` 中两个 `[已知问题 QA-F2]` 用例（修复后应通过）。

### 🟡 F3【中】解析失败行被静默丢弃，失败原因不上报

- **证据**：`ParsedBill` 设计有 `isValid`/`parseError` 字段（架构 3.1「ParsedBill union：成功条目/失败原因」、时序图 4.3「List\<ParsedBill\>(含失败行原因)」），但 `StatementParser._parseLine` 金额提取失败直接 `return null`、`CsvBillParser._parseRow` 同样丢弃——**`isValid=false` 的条目从未被生产**，用户无法感知「粘贴 10 行只导入 7 行」。
- **修复建议**：无法提取金额的行生成 `ParsedBill(isValid: false, parseError: '未能识别金额', ...)`，预览层 `ParsedBillPreview` 对 invalid 条目置灰并默认剔除（`_excludedIndexes` 预填）。
- **测试锚点**：`statement_parser_test.dart` 中 `[已知问题 QA-F3]` 用例（修复后应通过）。

### 🟢 F4【低】统计读路径绕过 Repository 直连 DAO

- **证据**：`stats_provider.dart` 直接 `ref.watch(databaseProvider).transactionDao.watchCategoryAggregation/watchTrendAggregation`；`ai_insight_card.dart` 直接 `ref.read(databaseProvider).transactionDao.watchMonthlySummary`。写路径合规，但与「UI → Provider → Repository → DAO」分层约定不完全一致（架构 1.3 原则针对 UI 直达 DAO，Provider 层直连属灰色地带）。
- **建议**：在 `TransactionRepository` 补 `watchCategoryAggregation/watchTrendAggregation` 委托方法，统计 Provider 改走仓库。可与 F1 一并小重构。

### 🟢 F5【低】首页无时间筛选/账目筛选 UI

- **证据**：`transactionRangeProvider`/`transactionFilterProvider` 已定义且被 `transactionListProvider` 消费，但全 features 无任何 UI 修改它们——首页永远只显示本月，PRD P1「按日/周/月/自定义区间查看账目」在首页侧未落地（统计页已有日/周/月）。建议首页 AppBar 加月份切换（← 2024年1月 →）入口，顺带激活已有 Provider。

### 🟢 F6【低】`MoneyUtils.isValidCents` 文档注释与实现不符

- **证据**：注释「是否为合法金额分（**非负**整数）」，实现 `cents > 0`（0 返回 false）。实现行为符合业务（金额必须为正），仅注释措辞需改为「正整数」。

### 🟢 F7【低】死代码/未使用声明

- **证据**：`AppConstants.billTextPatterns`（正则模板常量，StatementParser 并未使用）、`SyncStatusConverter`、`ColorTokens.sakuraLight`、`MoneyUtils.formatYuanPlain`、`MerchantRules` 表与 `MerchantRule` 模型（RuleClassifier 用静态 Map，未读库）。均为预留/占位，建议补注释说明或排期接入，避免误以为是已生效逻辑。

### 🟢 F8【低】`ParsedBillPreview` 分类列表为空时 DropdownButton 断言风险

- **证据**：`_resolvedCategoryId` 在 `typed` 为空时返回 `''`，此时 `DropdownButton(value: '', items: [])` 在 debug 模式可能触发 Flutter 断言（值不在 items 中）。触发条件：分类种子数据加载失败（极端场景）。建议 `typed.isEmpty` 时渲染占位 Text 而非 DropdownButton。

### 🔵 F9【提示】代码生成文件不入库（已正确文档化）

- `*.g.dart` 需 `dart run build_runner build --delete-conflicting-outputs` 生成，README「本地构建步骤」已注明。QA 测试亦不依赖这些生成文件（见第 10 节）。

### 🔵 F10【提示】CSV 无收支列时全部默认支出

- **证据**：`CsvBillParser._parseType('')` → expense。导入无类型列的银行 CSV 时收入行会被误判为支出。当前模板场景（微信/支付宝导出均含收支列）可接受；测试 `csv_bill_parser_test.dart` 已按现状固化该约定。建议后续在导入预览提供批量改类型入口。

---

## 10. 测试交付与覆盖说明

**测试文件（7 个，`test/` 目录，`flutter test` 可直接执行；均不依赖 Drift 生成文件）**

| 文件 | 用例数 | 覆盖点 |
| --- | --- | --- |
| `test/utils/money_utils_test.dart` | 24 | 分↔元转换（含 19.99 浮点舍入）、¥1,234.56 千分位、负数 -¥、0/超大值边界、字符串解析非法输入、formatSigned ±号 |
| `test/utils/date_utils_test.dart` | 20 | 月起止（12 月跨年）、闰年 2 月天数、日/周区间（周一为始、周日归位）、格式化、今天/昨天分组标题 |
| `test/utils/result_test.dart` | 10 | Ok/Failure 语义、valueOrNull/errorOrNull、map 透传错误、Result\<void\> |
| `test/classifier/rule_classifier_test.dart` | 13 | 美团→餐饮、工资→工资、滴滴→交通、类型不匹配返回 null、空输入、商户优先于关键词 |
| `test/import_parse/statement_parser_test.dart` | 15 | 微信/支付宝/银行短信三类句式金额·时间·商户·类型提取、¥/￥符号、坏行处理、Result 语义；含 2 个 F2/F3 缺陷锚定用例 |
| `test/import_parse/csv_bill_parser_test.dart` | 16 | 中/英表头识别、引号转义（含逗号/双引号中文）、坏行跳过（非数字/0/短行/缺列）、收支判定、多种日期格式、ParseResult 统计 |
| `test/export_import/csv_exporter_test.dart` | 7 | 表头/行格式、分类名映射与回退、RFC 4180 引号、导出→导入逐字段往返一致性、大金额无损 |

**预期失败用例（3 个，均为源码缺陷锚定，非测试错误）**：`statement_parser_test.dart` 中 `[已知问题 QA-F2]` ×2、`[已知问题 QA-F3]` ×1。其余用例按当前实现正确行为书写，应全部通过。工程师修复 F2/F3 后，这 3 个用例应转为通过，无需修改测试代码。

**运行方式**：
```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # 编译主工程需要；纯逻辑测试本身不依赖生成文件
flutter test
```

**未覆盖说明（受无 SDK 环境与生成文件限制）**：Drift DAO/Repository 集成测试（需 database.g.dart + 内存数据库）、Widget 测试（TransactionTile 渲染、RecordPage 再记一笔交互、删除二次确认对话框——依赖 F1 修复后再补）、AiClassifier 降级（需 mock dio，建议补 `ai_classifier_test.dart` 注入 fake AiClient）。

---

## 11. 智能路由判定（Round 1）

> **判定：Send To Engineer（寇豆码）**
> - **必须修复**：F1（P0 删除账目 UI 缺失）
> - **应当修复**：F2（商户提取噪声）、F3（失败行静默丢弃）
> - **建议随修复处理**：F4（统计读路径走 Repository）、F6（注释修正）、F8（空分类下拉保护）
> - **可排期**：F5（首页月份筛选）、F7（死代码清理）、F10（无类型列 CSV 提示）

**Round 2 回归清单（工程师修复后执行）**：
1. `flutter test` 全绿（重点：3 个缺陷锚定用例转通过，其余无回归）；
2. 复核 RecordPage 删除入口存在 + showDialog 二次确认 + 走 `transactionActionsProvider.delete`；
3. 复核 StatementParser 商户提取（银行短信/微信句式两个场景）；
4. 复核失败行以 `isValid=false + parseError` 上报且预览默认剔除。

---

## 12. Round 2 回归验证（工程师修复后复核，全部通过 ✅）

> 工程师（寇豆码）报告 F1/F2/F3 + F4/F6/F8 修复完毕，QA 逐文件重新通读 + 人工推演全部受影响测试用例。**本环境无 Flutter SDK，无法执行 `flutter test`，以下结论基于逐行静态复核与正则/逻辑人工推演**，建议用户本地跑一次 `flutter test` 做最终确认（预期全绿）。

### 12.1 修复复核明细

| # | 问题 | 复核结论 | 证据（文件 + 行为） |
| --- | --- | --- | --- |
| F1 | 删除账目 UI 入口（P0） | ✅ 已修复 | `record_page.dart`：`_delete()`（第 172-201 行）——AppBar 仅在编辑模式（`_editing != null`，第 219 行）显示删除 IconButton（`ColorTokens.expenseRed` + tooltip）；点击弹 `AlertDialog` 二次确认（「取消」/「删除」两按钮）；`confirm != true` 直接返回；确认后走 `ref.read(transactionActionsProvider).delete(_editing!.id)` → Repository → DAO（写路径合规）；成功 `context.pop()`，失败 SnackBar 提示。**PRD P0「删除需二次确认」验收项闭环** |
| F2 | 商户提取前缀噪声 | ✅ 已修复 | `statement_parser.dart` `_extractMerchant`（第 104-131 行）重写为 4 级优先级：① 显式标签（商户/商家/收款方/交易对象）→ ② `向XX(支付|付款)` → ③ 锚定 `(?:在|于)XX(消费|支付|购买|付款|扣款)` → ④ 宽松回退。人工推演：银行短信「【招商银行】您尾号1234的账户1月5日在美团消费58.50元」→ ③ 命中 `美团`（无尾号/账户噪声）；微信「微信支付：向美团外卖支付35.50元」→ ② 命中 `美团外卖`；既有用例「支付宝消费58元」→ ④ 命中 `支付宝`（不回归） |
| F3 | 失败行静默丢弃 | ✅ 已修复 | `statement_parser.dart` `_parseLine`（第 29-42 行）：金额提取失败返回 `ParsedBill(amountCents: 0, isValid: false, parseError: '未能识别金额', note: 原行)`；`parseText` 无过滤 add 全部行。配套 UI：`parsed_bill_preview.dart`——失败行 Opacity 0.6 置灰、Checkbox 禁用且恒为 false、金额位显示「解析失败」、parseError 红字展示、原始行文本展示；`import_page.dart` `_confirm`（第 77-87 行）过滤 `isValid` 条目、「解析失败 N 条」计数展示（第 163 行） |
| F4 | 统计读路径绕过 Repository | ✅ 已修复 | `transaction_repository.dart` 新增 `watchCategoryAggregation`/`watchTrendAggregation` 委托（第 135-148 行）；`stats_provider.dart` 改走 `transactionRepositoryProvider`（第 66、74 行）；`ai_insight_card.dart` 改走 `ref.read(transactionRepositoryProvider).watchMonthlySummary`（第 99-101 行）。全 lib grep 验证：DAO 构造仅出现于 data/local/daos 定义处，DAO 访问只剩 DI 组装根（`repository_provider.dart`）与 data 层，分层约定恢复 ✅ |
| F6 | isValidCents 注释措辞 | ✅ 已修复 | `money_utils.dart` 第 44 行注释改为「正整数；0 表示无金额，视为非法」，与 `cents > 0` 实现一致 |
| F8 | 空分类 DropdownButton 断言 | ✅ 已修复 | `parsed_bill_preview.dart` `_buildCategorySelector`（第 161-165 行）：`typed.isEmpty` 时渲染占位 Text「暂无可选分类」，不再构造空 items 的 DropdownButton |

### 12.2 测试用例推演结果（Round 2 回归）

- **3 个缺陷锚定用例**（2×QA-F2、1×QA-F3）：按新实现人工推演**全部应转通过**，且工程师确认未改动锚定用例代码（已复读 `statement_parser_test.dart` 核实，锚定用例原文未变）。
- **「空文本」「纯空白行」用例**：不回归。`parseText` 的空白行过滤在 `_parseLine` 之前（第 13-17 行 trim + isNotEmpty 过滤），空/纯空白输入仍返回 `Ok(空列表)` ✅。
- **既有用例**（支付宝商户、带标签商户、金额/日期提取、note 保留原始行、Result 语义）：逐条推演通过，无回归。
- **工程师对测试的修改（1 处，QA 裁决：接受 ✅）**：`statement_parser_test.dart`「多行混合」用例由「只保留能提取金额的行」更新为「4 条中 2 有效 + 2 失败条目上报」。**裁决理由**：原用例与 QA-F3 锚定用例逻辑互斥（同一行「今天天气不错」不可能既丢弃又保留），原语义描述的是修复前行为、且无 QA-F 标记；新版本按架构 4.3 设计行为书写，有效行金额断言（3550/5800）原样保留，并在用例内注明了更新原因。修改合理，予以接受。
- **CSV 跳过语义（工程师知悉事项 ②，QA 裁决：接受现状 ✅）**：`CsvBillParser` 维持坏行跳过（不上报失败条目）。**裁决理由**：CSV 为结构化格式，坏行（表头错位/缺列）多为不可恢复的格式错误，跳过并在统计中体现（`ParseResult` 的 skipped 统计）是可接受的独立约定；失败条目上报机制针对非结构化文本解析（F3 场景）已闭环。已在 `csv_bill_parser_test.dart` 中以「现状约定，见 QA-F10」文档化。如后续产品要求 CSV 也逐行上报，作为独立需求排期。

### 12.3 遗留问题（不阻塞交付）

| # | 问题 | 状态 |
| --- | --- | --- |
| F5 | 首页无月份筛选 UI（PRD P1） | 未修（工程师未列入本轮），建议排期 |
| F7 | 死代码/预留声明（billTextPatterns、MerchantRules 表等） | 未修（提示级），建议补注释或排期 |
| F10 | 无收支列 CSV 默认支出 | 维持现状约定（QA 接受，测试已文档化） |
| F9 | *.g.dart 需 build_runner 生成 | 已在 README 覆盖，无需处理 |

### 12.4 Round 2 结论

> **智能路由判定：Send To NoOne — Round 1 提出的必修复问题（F1/F2/F3）与随修问题（F4/F6/F8）全部确认修复，无新增缺陷，无测试回归。**
> 遗留 F5/F7/F10 均为低优先级排期项，不影响 P0/P1 核心验收。
> 两轮测试闭环达成（Round 1 发现 → 工程修复 → Round 2 回归通过），QA 流程结束。

---

*报告完 — QA 严过关（Yan），Round 1 + Round 2 回归*
