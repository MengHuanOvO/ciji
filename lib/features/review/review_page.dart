import 'package:flutter/material.dart';

import '../../core/models/study_state.dart';
import '../../core/models/word.dart';
import '../../core/srs/ebbinghaus_scheduler.dart';
import '../../data/repositories/review_repository.dart';

/// 闪卡复习页：认识 / 模糊 / 忘记，按艾宾浩斯调度下次复习。
class ReviewPage extends StatefulWidget {
  final List<StudyState> queue;
  const ReviewPage({super.key, required this.queue});

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  int _index = 0;
  bool _revealed = false;
  bool _loading = true;
  int _good = 0, _hard = 0, _forgot = 0;
  Map<int, Word> _words = {};

  StudyState get _current => widget.queue[_index];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final ids = widget.queue.map((s) => s.wordId).toList();
    final words = await ReviewRepository.instance.wordsOf(ids);
    if (mounted) {
      setState(() {
        _words = words;
        _loading = false;
      });
    }
  }

  Future<void> _grade(ReviewGrade grade) async {
    await ReviewRepository.instance.applyReview(_current.wordId, grade);
    setState(() {
      if (grade == ReviewGrade.good) _good++;
      if (grade == ReviewGrade.hard) _hard++;
      if (grade == ReviewGrade.forgot) _forgot++;
      _index++;
      _revealed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_index >= widget.queue.length) return _buildSummary();

    final word = _words[_current.wordId];
    if (word == null) {
      return const Scaffold(body: Center(child: Text('单词数据缺失')));
    }

    return Scaffold(
      appBar: AppBar(title: Text('复习 ${_index + 1}/${widget.queue.length}')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            LinearProgressIndicator(value: _index / widget.queue.length),
            const SizedBox(height: 20),
            Expanded(
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => setState(() => _revealed = true),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            word.text,
                            style: Theme.of(context)
                                .textTheme
                                .displaySmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          if (_revealed) ...[
                            if (word.phonetic != null)
                              Text(
                                word.phonetic!,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(color: Colors.grey),
                              ),
                            const SizedBox(height: 16),
                            Text(
                              word.trans ?? '（暂无释义，可到单词本补充）',
                              style: Theme.of(context).textTheme.titleMedium,
                              textAlign: TextAlign.center,
                            ),
                          ] else
                            const Text('点击卡片查看释义', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _gradeButton('忘记', Icons.refresh, Colors.red.shade400, ReviewGrade.forgot),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _gradeButton('模糊', Icons.help_outline, Colors.orange.shade400, ReviewGrade.hard),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _gradeButton('认识', Icons.check, Colors.green.shade400, ReviewGrade.good),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _gradeButton(String label, IconData icon, Color color, ReviewGrade grade) {
    return FilledButton(
      onPressed: () => _grade(grade),
      style: FilledButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon),
          const SizedBox(height: 4),
          Text(label),
        ],
      ),
    );
  }

  Widget _buildSummary() {
    return Scaffold(
      appBar: AppBar(title: const Text('复习完成'), automaticallyImplyLeading: false),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events, size: 72, color: Colors.amber),
            const SizedBox(height: 16),
            Text('今日复习完成！', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text('认识 $_good · 模糊 $_hard · 忘记 $_forgot'),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('返回首页'),
            ),
          ],
        ),
      ),
    );
  }
}