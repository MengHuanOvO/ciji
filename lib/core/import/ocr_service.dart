import 'dart:io';

import 'ocr_mlkit.dart';
import 'ocr_tesseract.dart';

/// OCR 抽象：移动端(iOS/Android)用 Google ML Kit，桌面端(Windows/Linux)用 Tesseract。
abstract class OcrService {
  String get name;
  Future<String> recognize(String imagePath);
  void dispose() {}
}

/// 按平台选择 OCR 实现。
OcrService createOcrService() {
  if (Platform.isWindows || Platform.isLinux) {
    return TesseractOcrService();
  }
  return MlKitOcrService();
}