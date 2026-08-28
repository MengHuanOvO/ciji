import '../models/study_state.dart';

/// 复习评价等级。
enum ReviewGrade { forgot, hard, good }

/// 一次调度结果。
class ReviewOutcome {
  final int stage;
  final DateTime nextReviewAt;
  final int intervalDays;
  const ReviewOutcome({
    required this.stage,
    required this.nextReviewAt,
    required this.intervalDays,
  });
}

/// 艾宾浩斯遗忘曲线调度器（纯 Dart，可单测）。
///
/// 经典间隔：1、2、4、7、15、30 天。
/// 分级逻辑：
///  - forgot(忘记)：回到第 0 阶段，按 1 天重学；
///  - hard(模糊)：阶段保持不变，按当前间隔复习；
///  - good(认识)：阶段 +1，按新间隔复习（到顶后维持）。
class EbbinghausScheduler {
  final List<int> intervalsDays;
  const EbbinghausScheduler({this.intervalsDays = const [1, 2, 4, 7, 15, 30]});

  int get maxStage => intervalsDays.length;

  /// 是否已到期（以“日”为单位比较）。
  bool isDue(StudyState s, DateTime now) {
    final next = s.nextReviewAt;
    if (next == null) return true;
    final today = DateTime(now.year, now.month, now.day);
    return !next.isAfter(today);
  }

  /// 根据当前阶段与评价，计算新阶段与下次复习时间。
  ReviewOutcome schedule({
    required int stage,
    required ReviewGrade grade,
    required DateTime now,
  }) {
    final int newStage;
    final int intervalIndex;
    switch (grade) {
      case ReviewGrade.forgot:
        newStage = 0;
        intervalIndex = 0;
        break;
      case ReviewGrade.hard:
        newStage = stage <= 0 ? 0 : stage;
        intervalIndex = (newStage - 1).clamp(0, intervalsDays.length - 1);
        break;
      case ReviewGrade.good:
        newStage = stage + 1 > maxStage ? maxStage : stage + 1;
        intervalIndex = newStage - 1;
        break;
    }
    final base = DateTime(now.year, now.month, now.day);
    final next = base.add(Duration(days: intervalsDays[intervalIndex]));
    return ReviewOutcome(
      stage: newStage,
      nextReviewAt: next,
      intervalDays: intervalsDays[intervalIndex],
    );
  }

  /// 构建每日队列：先到期复习（越早到期越靠前），再补足新词配额。
  List<StudyState> buildDailyQueue({
    required List<StudyState> due,
    required List<StudyState> fresh,
    required int newWordsPerDay,
  }) {
    final sortedDue = [...due]..sort((a, b) {
        final da = a.nextReviewAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final db = b.nextReviewAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return da.compareTo(db);
      });
    final quota = newWordsPerDay < 0 ? fresh.length : newWordsPerDay;
    return [...sortedDue, ...fresh.take(quota)];
  }
}