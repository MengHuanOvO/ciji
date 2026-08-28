# 从开源 qwerty-learner 仓库重新下载内置词书到 assets\wordbooks
$base = Split-Path -Parent $PSScriptRoot
$dir = Join-Path $base "assets\wordbooks"
New-Item -ItemType Directory -Force -Path $dir | Out-Null

$files = @("GaoKao_3500.json", "CET4_T.json", "CET6_T.json", "IELTS_3_T.json")
foreach ($f in $files) {
  $url = "https://raw.githubusercontent.com/kaiyiwing/qwerty-learner/master/public/dicts/$f"
  Invoke-WebRequest -Uri $url -OutFile (Join-Path $dir $f)
  Write-Host "已下载 $f"
}
Write-Host "完成。注意：重新下载会覆盖现有词书，请勿在未备份时执行。"