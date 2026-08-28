import 'package:ciji/core/models/study_state.dart';
import 'package:ciji/core/srs/ebbinghaus_scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final scheduler = const EbbinghausScheduler();
  final now = DateTime(2026, 8, 28, 10, 0);

  group('EbbinghausScheduler', () {
    test('默认间隔为 1,2,4,7,15,30 天', () {
      expect(scheduler.intervalsDays, [1, 2, 4, 7, 15, 30]);
    });

    test('新词认识 -> 阶段1，1天后复习', () {
      final o = scheduler.schedule(stage: 0, grade: ReviewGrade.good, now: now);
      expect(o.stage, 1);
      expect(o.nextReviewAt, DateTime(2026, 8, 29));
    });

    test('阶段1认识 -> 阶段2，2天后复习', () {
      final o = scheduler.schedule(stage: 1, grade: ReviewGrade.good, now: now);
      expect(o.stage, 2);
      expect(o.nextReviewAt, DateTime(2026, 8, 30));
    });

    test('忘记 -> 回到阶段0，1天后重学', () {
      final o = scheduler.schedule(stage: 3, grade: ReviewGrade.forgot, now: now);
      expect(o.stage, 0);
      expect(o.nextReviewAt, DateTime(2026, 8, 29));
    });

    test('模糊 -> 阶段不变，按当前间隔复习', () {
      final o = scheduler.schedule(stage: 2, grade: ReviewGrade.hard, now: now);
      expect(o.stage, 2);
      expect(o.nextReviewAt, DateTime(2026, 8, 30));
    });

    test('到顶后认识保持 maxStage，间隔封顶', () {
      final o = scheduler.schedule(stage: 6, grade: ReviewGrade.good, now: now);
      expect(o.stage, 6);
      expect(o.nextReviewAt, DateTime(2026, 9, 27));
    });

    test('isDue: 未设置下次复习时间视为到期', () {
      final s = StudyState(wordId: 1, stage: 0, nextReviewAt: null);
      expect(scheduler.isDue(s, now), isTrue);
    });

    test('isDue: 未来时间未到期，当日到期', () {
      final future = StudyState(wordId: 1, stage: 1, nextReviewAt: DateTime(2026, 8, 29));
      expect(scheduler.isDue(future, now), isFalse);
      final today = StudyState(wordId: 2, stage: 1, nextReviewAt: DateTime(2026, 8, 28, 0, 0));
      expect(scheduler.isDue(today, now), isTrue);
    });

    test('buildDailyQueue: 到期在前（越早越靠前），新词按配额补充', () {
      final due = [
        StudyState(wordId: 1, stage: 1, nextReviewAt: DateTime(2026, 8, 28)),
        StudyState(wordId: 2, stage: 2, nextReviewAt: DateTime(2026, 8, 27)),
      ];
      final fresh = [
        StudyState(wordId: 3),
        StudyState(wordId: 4),
        StudyState(wordId: 5),
      ];
      final queue = scheduler.buildDailyQueue(due: due, fresh: fresh, newWordsPerDay: 2);
      expect(queue.map((s) => s.wordId).toList(), [2, 1, 3, 4]);
    });
  });
}