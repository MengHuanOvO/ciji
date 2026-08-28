# 词迹 Ciji · 英语背单词

跨平台（Android APK + iOS IPA + Windows EXE）英语背单词应用，基于 Flutter。

## 功能
- **多方式导入单词**
  - 拍照 OCR 提取（移动端 Google ML Kit，离线）
  - 相册图片 OCR 提取
  - 粘贴文本/单词列表导入
  - 英文文章难词自动提取（按长度/生僻度评分排序）
  - 自动去停用词、去已收录词、自动查释义
- **艾宾浩斯遗忘曲线复习**：经典间隔 1/2/4/7/15/30 天，认识/模糊/忘记三档评价，忘记自动回到第 1 天重学；每日自动生成「到期复习 + 新学配额」队列
- **内置词书**（开源数据，qwerty-learner，MIT）：
  - 高中 3500 词（3893 词）
  - 大学英语四级（2607 词）
  - 大学英语六级（2345 词）
  - 雅思核心（3575 词）
- **词书管理**：启用/停用词书（决定是否进入每日新学）、学习进度、查看单词
- **本地存储**：SQLite（iOS/Android 原生 sqflite；Windows/Linux ffi），无账号、全离线

## 目录结构
```
lib/
  core/          # 与 UI 无关的核心：模型、数据库、艾宾浩斯调度器、导入/OCR、词库索引
    srs/ebbinghaus_scheduler.dart   # 艾宾浩斯调度（纯 Dart，可单测）
    import/                          # 分词、难词评分、OCR 抽象（ML Kit / Tesseract）
  data/repositories/                 # 词库/复习仓库
  features/                          # 首页、复习、单词本、导入、词书、设置
  widgets/                           # 候选词选择弹层等
assets/wordbooks/                    # 内置词书 JSON
test/                                # 单元测试（调度器/分词/难词）
scripts/                             # bootstrap、Windows 打包、iOS 打包、词库下载
installer/wordease.iss               # Inno Setup 安装包脚本
.github/workflows/build.yml          # 双端自动打包 CI
```

## 快速开始
1. 安装 Flutter SDK（见 `docs/05-开发环境搭建.md`）
2. 补齐平台目录：`powershell -File scripts\bootstrap.ps1`
3. 运行：`flutter run -d windows`（桌面）或 `flutter run`（已连手机）

## 打包
- **Windows EXE**：`powershell -File scripts\build_windows.ps1 -Installer` → `outputs\CijiSetup-0.1.0.exe`（详见 `docs/02-打包-EXE-Windows.md`）
- **Android APK**：`flutter build apk --release` → `build\app\outputs\flutter-apk\app-release.apk`
- **Android APK**：`flutter build apk --release`，或推 tag 触发 GitHub Actions
- **iOS IPA**：在 macOS 上 `bash scripts/build_ios.sh`，或推 tag 触发 GitHub Actions（详见 `docs/03-打包-IPA-iOS.md`）

## 技术栈
Flutter 3 · sqflite + sqflite_common_ffi · google_mlkit_text_recognition（移动端 OCR）· Tesseract（桌面端 OCR）· image_picker · Inno Setup 6（EXE 安装包）

## 数据来源
内置词书来自开源项目 [qwerty-learner](https://github.com/kaiyiwing/qwerty-learner)（MIT License）的词库 JSON。

## License
MIT（本项目代码）；内置词库版权归原项目，请遵守其 License。