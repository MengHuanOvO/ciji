import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import 'ocr_service.dart';

/// 移动端 OCR：Google ML Kit（离线、免费、iOS/Android）。
class MlKitOcrService implements OcrService {
  MlKitOcrService({TextRecognizer? recognizer})
      : _recognizer = recognizer ?? TextRecognizer(script: TextRecognitionScript.latin);

  final TextRecognizer _recognizer;

  @override
  String get name => 'ML Kit';

  @override
  Future<String> recognize(String imagePath) async {
    try {
      final input = InputImage.fromFilePath(imagePath);
      final result = await _recognizer.processImage(input);
      return result.text;
    } catch (e) {
      throw Exception('ML Kit OCR 失败: $e');
    }
  }

  @override
  void dispose() => _recognizer.close();
}