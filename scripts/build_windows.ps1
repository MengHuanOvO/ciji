# 构建 Windows EXE（需 VS2022 C++ 桌面工作负载 + Flutter Windows 支持）
# 用法: powershell -File scripts\build_windows.ps1 -Installer
param(
  [switch]$Installer
)
$ErrorActionPreference = "Stop"

flutter pub get
flutter build windows --release

Write-Host ""
Write-Host "EXE 输出: build\windows\x64\runner\Release\ciji.exe"

if ($Installer) {
  $iscc = @(
    "C:\Program Files (x86)\Inno Setup 6\ISCC.exe",
    "C:\Program Files\Inno Setup 6\ISCC.exe"
  ) | Where-Object { Test-Path $_ } | Select-Object -First 1
  if (-not $iscc) {
    throw "未找到 ISCC.exe，请安装 Inno Setup 6（https://jrsoftware.org/isdl.php）后重试，或跳过 -Installer 手动打包"
  }
  & $iscc "installer\wordease.iss"
  Write-Host ""
  Write-Host "安装包输出: outputs\CijiSetup-*.exe"
}