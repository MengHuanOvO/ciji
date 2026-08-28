import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/import/import_service.dart';
import '../../core/import/ocr_service.dart';
import '../../data/repositories/word_repository.dart';
import '../../widgets/candidate_sheet.dart';

/// 导入页：拍照 OCR / 相册 OCR / 粘贴文本 / 文章难词提取。
class ImportPage extends StatefulWidget {
  const ImportPage({super.key});

  @override
  State<ImportPage> createState() => _ImportPageState();
}

class _ImportPageState extends State<ImportPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  final TextEditingController _pasteController = TextEditingController();
  final TextEditingController _articleController = TextEditingController();
  final ImportService _importService = ImportService(WordRepository.instance);
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    _pasteController.dispose();
    _articleController.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _pickImage(ImageSource source, String importType) async {
    final file = await ImagePicker().pickImage(
      source: source,
      maxWidth: 2400,
      maxHeight: 2400,
      imageQuality: 90,
    );
    if (file == null) return;
    setState(() => _busy = true);
    try {
      final ocr = createOcrService();
      final text = await ocr.recognize(file.path);
      ocr.dispose();
      if (text.trim().isEmpty) {
        _snack('未识别到文字，请换一张更清晰的照片');
        return;
      }
      final candidates = await _importService.extractCandidates(text);
      final added = await showCandidateSheet(
        context,
        words: candidates.words,
        importType: importType,
        sourceText: text,
      );
      if (added != null && added > 0) _snack('已添加 $added 个生词');
    } catch (e) {
      _snack('OCR 失败：$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _fromText(String text, String importType,
      {bool difficultFirst = false}) async {
    if (text.trim().isEmpty) {
      _snack('请输入内容');
      return;
    }
    setState(() => _busy = true);
    try {
      final candidates = await _importService.extractCandidates(text);
      final list = difficultFirst ? candidates.difficultWords : candidates.words;
      final added = await showCandidateSheet(
        context,
        words: list,
        importType: importType,
        sourceText: text,
      );
      if (added != null && added > 0) _snack('已添加 $added 个生词');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _bigAction({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.all(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: _busy ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 56, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 12),
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 6),
              Text(subtitle,
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('导入单词'),
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(text: '拍照'),
            Tab(text: '相册'),
            Tab(text: '粘贴'),
            Tab(text: '文章'),
          ],
        ),
      ),
      body: Stack(
        children: [
          TabBarView(
            controller: _tab,
            children: [
              _bigAction(
                icon: Icons.camera_alt,
                title: '拍照提取',
                subtitle: '拍摄纸质单词表 / 教材，自动 OCR 提取生词',
                onTap: () => _pickImage(ImageSource.camera, 'ocr_photo'),
              ),
              _bigAction(
                icon: Icons.photo_library,
                title: '相册提取',
                subtitle: '选择已有图片，自动 OCR 提取生词',
                onTap: () => _pickImage(ImageSource.gallery, 'ocr_gallery'),
              ),
              ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text('粘贴单词 / 文本（空格、换行、逗号分隔均可）'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _pasteController,
                    maxLines: 8,
                    decoration: const InputDecoration(
                      hintText: '例如：apple banana 或者一段英文……',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _busy
                        ? null
                        : () => _fromText(_pasteController.text, 'paste'),
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('提取候选词'),
                  ),
                ],
              ),
              ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text('粘贴英文文章，自动提取难词（越长/越生僻越靠前）'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _articleController,
                    maxLines: 10,
                    decoration: const InputDecoration(
                      hintText: '粘贴一篇英文文章……',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _busy
                        ? null
                        : () => _fromText(_articleController.text, 'article',
                            difficultFirst: true),
                    icon: const Icon(Icons.psychology),
                    label: const Text('提取难词'),
                  ),
                ],
              ),
            ],
          ),
          if (_busy)
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(),
            ),
        ],
      ),
    );
  }
}