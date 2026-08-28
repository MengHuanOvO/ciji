import 'database/app_database.dart';
import 'srs/ebbinghaus_scheduler.dart';

/// 应用设置（存 SQLite settings 表）。
class AppSettings {
  AppSettings._();
  static final AppSettings instance = AppSettings._();

  Database get _db => AppDatabase.instance.db;

  int _dailyNewWords = 20;
  List<int> _intervals = const [1, 2, 4, 7, 15, 30];

  int get dailyNewWords => _dailyNewWords;
  List<int> get intervals => _intervals;

  EbbinghausScheduler get scheduler => EbbinghausScheduler(intervalsDays: _intervals);

  Future<void> load() async {
    final rows = await _db.query('settings');
    for (final r in rows) {
      final k = r['key'] as String;
      final v = r['value'] as String;
      if (k == 'daily_new_words') {
        _dailyNewWords = int.tryParse(v) ?? 20;
      } else if (k == 'intervals') {
        final parsed = v
            .split(',')
            .map((s) => int.tryParse(s.trim()))
            .whereType<int>()
            .where((x) => x > 0)
            .toList();
        if (parsed.length >= 2) _intervals = parsed;
      }
    }
  }

  Future<void> setDailyNewWords(int n) async {
    _dailyNewWords = n;
    await _db.insert('settings', {'key': 'daily_new_words', 'value': '$n'},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> setIntervals(List<int> list) async {
    _intervals = list;
    await _db.insert('settings', {'key': 'intervals', 'value': list.join(',')},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }
}