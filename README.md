# ledger_app — 清新可爱的记账软件

一套代码覆盖 **Android / iOS / Windows** 的记账应用：快速记账、分类管理、收支统计图表、
账单导入（文本/CSV）、可选 AI 智能分类。本工程由 PRD + 架构文档 + QA 报告驱动落地，
并已包含 QA Round 2 复核通过的全部修复（F1/F2/F3/F4/F6/F8）。

- `docs/`：PRD.md / ARCHITECTURE.md / QA_REPORT.md（设计依据）
- `lib/`：Flutter(Dart) 源码，分层架构（UI → Provider → Repository → Drift/Services）
- `test/`：纯 Dart 逻辑单元测试（~70 用例），运行不依赖 `*.g.dart`

## 技术栈

Flutter 3.29+ / Dart 3.5+；Riverpod、Drift(SQLite)、go_router、fl_chart、dio、csv。

> 本工程 `android/`、`ios/`、`windows/` 等平台脚手架未入库。构建前请先执行
> `flutter create --platforms=android,ios,windows .` 补齐，再进入下方步骤。

## 本地构建 / 打包

前置：已安装 **Flutter SDK**；打包 Windows 还需 **Visual Studio（C++ 桌面开发）**，
打包 Android 还需 **Android SDK**。（本文档所述打包需在具备工具链的机器上执行，
可参考 `build_windows.bat` 与 `build_apk.bat` 一键脚本。）

```bash
# 1. 补齐平台脚手架（生成 android/ios/windows 目录）
flutter create --platforms=android,ios,windows --org com.example --project-name ledger_app .

# 2. 拉取依赖
flutter pub get

# 3. 生成代码（Drift 表访问器、json 等 *.g.dart —— 编译必需）
dart run build_runner build --delete-conflicting-outputs

# 4a. Windows 桌面可执行程序
flutter build windows --release
#     产物: build\windows\x64\runner\Release\ledger_app.exe

# 4b. Android APK
flutter build apk --release
#     产物: build\app\outputs\flutter-apk\app-release.apk

# 4c. 快速跑起来预览
flutter run -d windows   # 或 -d chrome / -d <android-device>
```

## 运行单元测试

```bash
flutter pub get
flutter test
```

覆盖：金额/日期工具、Result、规则分类器、短信/CSV 解析（含 QA-F2/F3 锚定用例）、CSV 导出往返。

## 目录结构（要点）

```
lib/
├── main.dart / app.dart          # 入口 + MaterialApp/路由/主题
├── core/                         # constants / theme / utils
├── data/
│   ├── local/                    # Drift 表·库·DAO（金额分、UUID、聚合下推）
│   ├── models/                   # Transaction / Category / MerchantRule / AppSettings
│   ├── repositories/             # ★统一写入入口（事务边界）
│   └── import_parse/             # 文本/CSV 账单解析（ParsedBill 含失败原因）
├── services/
│   ├── classifier/               # TransactionClassifier + 规则/AI 实现
│   ├── ai/                       # OpenAI 兼容 client + 洞察
│   ├── export_import/            # CSV 导出 + JSON 备份恢复
│   └── sync/                     # SyncService 接口 + Noop 占位
├── providers/                    # Riverpod（数据库/仓库/设置/分类器/账目/统计/导入）
├── features/                     # home / record / stats / categories / import_bill / settings
└── router/                       # go_router 路由表 + 底部导航壳
```

## 关键业务约定（来自架构共享知识）

- 金额一律以**整数分**存储，展示统一走 `MoneyUtils.formatYuan()`。
- 账目写入必须经 `TransactionRepository`（`source` 必填），删除账目/分类均二次确认。
- 主键 UUID；`updatedAt`/`syncVersion` 为云同步预留。
- 分类删除不级联删账目，自动迁移到「其他」。
- AI 任何失败一律降级规则分类器，绝不抛异常到 UI。
