import 'dart:io';

import 'ocr_service.dart';

/// 桌面端 OCR：调用本机 tesseract 命令行（需安装 tesseract 并加入 PATH，见 docs）。
class TesseractOcrService implements OcrService {
  @override
  String get name => 'Tesseract';

  @override
  void dispose() {}

  @override
  Future<String> recognize(String imagePath) async {
    final result = await Process.run('tesseract', [imagePath, 'stdout', '-l', 'eng']);
    if (result.exitCode != 0) {
      throw Exception(
        'Tesseract OCR 失败(exit=${result.exitCode}): ${result.stderr}\n'
        '请确认已安装 tesseract 并加入 PATH（https://github.com/UB-Mannheim/tesseract/wiki）',
      );
    }
    return result.stdout as String;
  }
}