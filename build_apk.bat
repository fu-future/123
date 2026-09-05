@echo off
REM ============================================================
REM  ledger_app 构建 Android APK（需已装 Flutter SDK + Android SDK）
REM ============================================================
cd /d "%~dp0"

echo [1/4] 生成 Android 平台脚手架（缺失时）...
if not exist android call flutter create --platforms=android --org com.example --project-name ledger_app .

echo [2/4] 拉取依赖 ...
call flutter pub get || goto :err

echo [3/4] 生成代码 ...
call dart run build_runner build --delete-conflicting-outputs || goto :err

echo [4/4] 构建 APK ...
call flutter build apk --release || goto :err

echo.
echo 构建成功！产物: build\app\outputs\flutter-apk\app-release.apk
exit /b 0

:err
echo 构建失败，请检查上方错误信息。
exit /b 1
