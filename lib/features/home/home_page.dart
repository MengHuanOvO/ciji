import 'package:flutter/material.dart';

import '../../core/settings.dart';
import '../../data/repositories/review_repository.dart';
import '../import/import_page.dart';
import '../review/review_page.dart';

/// 今日任务首页。
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  DailyStats? _stats;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final stats = await ReviewRepository.instance.getTodayStats();
    if (mounted) setState(() => _stats = stats);
  }

  Future<void> _startReview() async {
    final settings = AppSettings.instance;
    final due = await ReviewRepository.instance.getDue();
    final fresh = await ReviewRepository.instance.getFresh(limit: settings.dailyNewWords);
    final queue = settings.scheduler.buildDailyQueue(
      due: due,
      fresh: fresh,
      newWordsPerDay: settings.dailyNewWords,
    );
    if (!mounted) return;
    if (queue.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('今天没有需要复习的单词，去「导入」或「词书」添加吧')),
      );
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ReviewPage(queue: queue)),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final stats = _stats;
    return Scaffold(
      appBar: AppBar(title: const Text('词迹 Ciji'), centerTitle: true),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (stats == null)
              const Padding(
                padding: EdgeInsets.all(48),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              _StatCard(
                label: '今日待复习',
                value: '${stats.dueCount}',
                icon: Icons.autorenew,
                color: Colors.teal,
              ),
              _StatCard(
                label: '新词待学习',
                value: '${stats.newCount}',
                icon: Icons.fiber_new,
                color: Colors.indigo,
              ),
              _StatCard(
                label: '今日已完成',
                value: '${stats.doneToday}',
                icon: Icons.check_circle_outline,
                color: Colors.green,
              ),
              _StatCard(
                label: '已掌握',
                value: '${stats.masteredCount}',
                icon: Icons.emoji_events_outlined,
                color: Colors.amber.shade800,
              ),
            ],
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _startReview,
              icon: const Icon(Icons.play_arrow),
              label: const Text('开始今日复习'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ImportPage()),
              ),
              icon: const Icon(Icons.add),
              label: const Text('导入新单词'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: .15),
          child: Icon(icon, color: color),
        ),
        title: Text(label),
        trailing: Text(
          value,
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(color: color, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}