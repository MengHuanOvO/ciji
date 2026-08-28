import 'package:flutter/material.dart';

import '../../core/import/import_service.dart';
import '../../data/repositories/word_repository.dart';

/// 候选单词选择弹层；返回成功添加的数量。
Future<int?> showCandidateSheet(
  BuildContext context, {
  required List<CandidateWord> words,
  required String importType,
  String? sourceText,
}) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _CandidateSheet(
      words: words,
      importType: importType,
      sourceText: sourceText,
    ),
  );
}

class _CandidateSheet extends StatefulWidget {
  final List<CandidateWord> words;
  final String importType;
  final String? sourceText;
  const _CandidateSheet({
    required this.words,
    required this.importType,
    this.sourceText,
  });

  @override
  State<_CandidateSheet> createState() => _CandidateSheetState();
}

class _CandidateSheetState extends State<_CandidateSheet> {
  final Set<String> _selected = {};
  bool _saving = false;

  bool get _allSelected =>
      widget.words.isNotEmpty && _selected.length == widget.words.length;

  void _toggle(String word) {
    setState(() {
      if (_selected.contains(word)) {
        _selected.remove(word);
      } else {
        _selected.add(word);
      }
    });
  }

  void _toggleAll() {
    setState(() {
      if (_allSelected) {
        _selected.clear();
      } else {
        _selected.addAll(widget.words.map((w) => w.word));
      }
    });
  }

  Future<void> _add() async {
    if (_selected.isEmpty) return;
    setState(() => _saving = true);
    final added = await WordRepository.instance.addWordsFromImport(
      _selected.toList(),
      importType: widget.importType,
      sourceText: widget.sourceText,
    );
    if (!mounted) return;
    Navigator.of(context).pop(added.length);
  }

  @override
  Widget build(BuildContext context) {
    final words = widget.words;
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.72,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '提取到 ${words.length} 个候选词（已去停用词/已收录词，自动查释义）',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  TextButton(
                    onPressed: _toggleAll,
                    child: Text(_allSelected ? '取消全选' : '全选'),
                  ),
                  FilledButton(
                    onPressed: _saving || _selected.isEmpty ? null : _add,
                    child: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text('添加(${_selected.length})'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: words.isEmpty
                  ? const Center(child: Text('未提取到新单词'))
                  : ListView.builder(
                      itemCount: words.length,
                      itemBuilder: (_, i) {
                        final c = words[i];
                        return CheckboxListTile(
                          value: _selected.contains(c.word),
                          onChanged: (_) => _toggle(c.word),
                          title: Text(c.word),
                          subtitle: Text(c.trans ?? (c.phonetic ?? '')),
                          secondary: Text(
                            '×${c.count}',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}