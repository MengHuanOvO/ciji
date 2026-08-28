# 词迹 ciji - 在装有 Flutter 的机器上补齐平台目录（android/ios/windows）
# 用法: powershell -File scripts\bootstrap.ps1
param(
  [string]$Org = "com.wordlab"
)
$ErrorActionPreference = "Stop"

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
  throw "未找到 flutter，请先安装 Flutter SDK（见 docs/05-开发环境搭建.md）"
}

flutter create --org $Org --project-name ciji --platforms=android,ios,windows .
flutter pub get

Write-Host ""
Write-Host "完成：已生成 android/ios/windows 平台目录。"
Write-Host "下一步："
Write-Host "  - Windows EXE: powershell -File scripts\build_windows.ps1 -Installer"
Write-Host "  - iOS IPA: 在 macOS 上运行 bash scripts/build_ios.sh（或 GitHub Actions）"