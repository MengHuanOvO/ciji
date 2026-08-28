import 'package:flutter/material.dart';

import '../../core/database/app_database.dart';
import '../../core/settings.dart';
import '../../data/repositories/word_repository.dart';

/// 设置页：每日新学数量 / 艾宾浩斯间隔 / 数据重置。
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  double _daily = 20;
  late final TextEditingController _intervalController;

  @override
  void initState() {
    super.initState();
    final s = AppSettings.instance;
    _daily = s.dailyNewWords.toDouble();
    _intervalController = TextEditingController(text: s.intervals.join(', '));
  }

  @override
  void dispose() {
    _intervalController.dispose();
    super.dispose();
  }

  Future<void> _saveDaily(double v) async {
    setState(() => _daily = v);
    await AppSettings.instance.setDailyNewWords(v.round());
  }

  Future<void> _saveIntervals() async {
    final parsed = _intervalController.text
        .split(',')
        .map((s) => int.tryParse(s.trim()))
        .whereType<int>()
        .where((x) => x > 0)
        .toList();
    if (parsed.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请至少输入 2 个正整数间隔，用逗号分隔')),
      );
      return;
    }
    await AppSettings.instance.setIntervals(parsed);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已保存间隔：${parsed.join(', ')} 天')),
    );
  }

  Future<void> _reset() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('重置全部数据？'),
        content: const Text('将清空学习进度、生词与词书，且不可恢复。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('重置')),
        ],
      ),
    );
    if (ok != true) return;
    await AppDatabase.instance.reset();
    await AppSettings.instance.load();
    await WordRepository.instance.seedBuiltInBooks();
    if (!mounted) return;
    setState(() {
      _daily = AppSettings.instance.dailyNewWords.toDouble();
      _intervalController.text = AppSettings.instance.intervals.join(', ');
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已重置，词书已重新加载')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('复习设置', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: const Text('每日新学数量'),
                  subtitle: Text('每天进入队列的新词：${_daily.round()} 个'),
                  trailing: SizedBox(
                    width: 180,
                    child: Slider(
                      value: _daily,
                      min: 5,
                      max: 100,
                      divisions: 19,
                      label: '${_daily.round()}',
                      onChanged: _saveDaily,
                    ),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  title: const Text('艾宾浩斯复习间隔（天）'),
                  subtitle: const Text('认识后按 1,2,4,7,15,30… 递进复习'),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: TextField(
                    controller: _intervalController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: '1, 2, 4, 7, 15, 30',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: TextButton(onPressed: _saveIntervals, child: const Text('保存间隔')),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text('数据管理', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: const Text('重置全部数据'),
              onTap: _reset,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '词迹 Ciji v0.1.0\n内置词书：高中 3500 / 大学英语四级 / 六级 / 雅思核心\n数据来源：开源项目 qwerty-learner（MIT）',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}