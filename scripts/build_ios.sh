#!/usr/bin/env bash
# 构建 iOS IPA（需 macOS + Xcode + 已配置签名）
# 无签名自测: flutter build ipa --release --no-codesign
set -euo pipefail
cd "$(dirname "$0")/.."
flutter pub get
flutter build ipa --release
echo ""
echo "IPA 输出: build/ios/ipa/*.ipa"