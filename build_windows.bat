@echo off
REM ============================================================
REM  ledger_app 一键构建脚本（需本机已安装 Flutter SDK）
REM  用法:  build_windows.bat   ->  生成 Windows 桌面可执行程序
REM  前置:  flutter --version 可用; 已安装 Visual Studio C++ 桌面开发
REM ============================================================
cd /d "%~dp0"

echo [1/4] 生成缺失的平台脚手架 (android/ios/windows) ...
call flutter create --platforms=android,ios,windows --org com.example --project-name ledger_app . || goto :err

echo [2/4] 拉取依赖 ...
call flutter pub get || goto :err

echo [3/4] 生成代码 (drift/json 等 *.g.dart) ...
call dart run build_runner build --delete-conflicting-outputs || goto :err

echo [4/4] 构建 Windows Release ...
call flutter build windows --release || goto :err

echo.
echo 构建成功！产物目录: build\windows\x64\runner\Release\ledger_app.exe
exit /b 0

:err
echo.
echo 构建失败，请检查上方错误信息。
exit /b 1
