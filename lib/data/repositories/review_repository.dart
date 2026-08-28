import 'package:sqflite/sqflite.dart';

import '../../core/database/app_database.dart';
import '../../core/models/study_state.dart';
import '../../core/models/word.dart';
import '../../core/settings.dart';
import '../../core/srs/ebbinghaus_scheduler.dart';

class DailyStats {
  final int dueCount;
  final int newCount;
  final int doneToday;
  final int masteredCount;
  const DailyStats({
    required this.dueCount,
    required this.newCount,
    required this.doneToday,
    required this.masteredCount,
  });
}

/// 复习仓库：到期队列、新学队列、评价落地。
class ReviewRepository {
  ReviewRepository._();
  static final ReviewRepository instance = ReviewRepository._();

  Database get _db => AppDatabase.instance.db;
  EbbinghausScheduler get _scheduler => AppSettings.instance.scheduler;

  /// 今日到期（next_review_at <= 今日零点）。
  Future<List<StudyState>> getDue({DateTime? now}) async {
    final n = now ?? DateTime.now();
    final today = DateTime(n.year, n.month, n.day).millisecondsSinceEpoch;
    final rows = await _db.query('study_state',
        where: 'next_review_at IS NOT NULL AND next_review_at <= ?',
        whereArgs: [today]);
    return rows.map(StudyState.fromMap).toList();
  }

  /// 新学队列：来自启用词书或用户导入、从未复习的词。
  Future<List<StudyState>> getFresh({int limit = 50}) async {
    final rows = await _db.rawQuery('''
      SELECT s.* FROM study_state s
      WHERE s.review_count = 0 AND s.next_review_at IS NULL
        AND (
          NOT EXISTS (SELECT 1 FROM book_words bw WHERE bw.word_id = s.word_id)
          OR EXISTS (
            SELECT 1 FROM book_words bw JOIN word_books b ON b.id = bw.book_id
            WHERE bw.word_id = s.word_id AND b.enabled = 1
          )
        )
      ORDER BY s.word_id LIMIT ?
    ''', [limit]);
    return rows.map(StudyState.fromMap).toList();
  }

  /// 批量取单词。
  Future<Map<int, Word>> wordsOf(List<int> ids) async {
    if (ids.isEmpty) return {};
    final placeholders = List.filled(ids.length, '?').join(',');
    final rows = await _db.rawQuery(
        'SELECT * FROM words WHERE id IN ($placeholders)', ids);
    return {for (final r in rows) r['id'] as int: Word.fromMap(r)};
  }

  Future<Word?> wordOf(int id) async {
    final rows = await _db.query('words',
        where: 'id = ?', whereArgs: [id], limit: 1);
    return rows.isEmpty ? null : Word.fromMap(rows.first);
  }

  /// 应用一次评价：更新学习状态 + 写复习日志。
  Future<void> applyReview(int wordId, ReviewGrade grade, {DateTime? now}) async {
    final n = now ?? DateTime.now();
    final rows = await _db.query('study_state',
        where: 'word_id = ?', whereArgs: [wordId], limit: 1);
    final state = rows.isEmpty
        ? StudyState(wordId: wordId)
        : StudyState.fromMap(rows.first);
    final stageBefore = state.stage;
    final outcome = _scheduler.schedule(stage: stageBefore, grade: grade, now: n);

    state
      ..stage = outcome.stage
      ..lastReviewAt = n
      ..nextReviewAt = outcome.nextReviewAt
      ..reviewCount += 1;
    if (grade == ReviewGrade.good) {
      state.correctCount += 1;
    } else {
      state.wrongCount += 1;
      if (grade == ReviewGrade.forgot) state.lapses += 1;
    }
    state.isMastered = state.stage >= _scheduler.maxStage;

    await _db.insert('study_state', state.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
    await _db.insert('review_logs', {
      'word_id': wordId,
      'reviewed_at': n.millisecondsSinceEpoch,
      'grade': grade.index,
      'stage_before': stageBefore,
      'stage_after': outcome.stage,
      'interval_days': outcome.intervalDays,
    });
  }

  /// 今日统计。
  Future<DailyStats> getTodayStats({DateTime? now}) async {
    final n = now ?? DateTime.now();
    final todayStart = DateTime(n.year, n.month, n.day).millisecondsSinceEpoch;
    final todayEnd = todayStart + const Duration(days: 1).inMilliseconds;

    final due = await _db.rawQuery(
        'SELECT COUNT(*) AS c FROM study_state WHERE next_review_at IS NOT NULL AND next_review_at <= ?',
        [todayStart]);
    final fresh = await _db.rawQuery(
        'SELECT COUNT(*) AS c FROM study_state WHERE review_count = 0 AND next_review_at IS NULL');
    final done = await _db.rawQuery(
        'SELECT COUNT(*) AS c FROM review_logs WHERE reviewed_at >= ? AND reviewed_at < ?',
        [todayStart, todayEnd]);
    final mastered = await _db.rawQuery(
        'SELECT COUNT(*) AS c FROM study_state WHERE is_mastered = 1');

    return DailyStats(
      dueCount: Sqflite.firstIntValue(due) ?? 0,
      newCount: Sqflite.firstIntValue(fresh) ?? 0,
      doneToday: Sqflite.firstIntValue(done) ?? 0,
      masteredCount: Sqflite.firstIntValue(mastered) ?? 0,
    );
  }
}