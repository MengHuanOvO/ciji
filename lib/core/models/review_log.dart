/// 复习记录（用于统计与复盘）。
class ReviewLog {
  final int? id;
  final int wordId;
  final DateTime reviewedAt;
  final int grade; // 0=忘记 1=模糊 2=认识
  final int stageBefore;
  final int stageAfter;
  final int intervalDays;

  const ReviewLog({
    this.id,
    required this.wordId,
    required this.reviewedAt,
    required this.grade,
    required this.stageBefore,
    required this.stageAfter,
    required this.intervalDays,
  });

  factory ReviewLog.fromMap(Map<String, Object?> map) => ReviewLog(
        id: map['id'] as int?,
        wordId: map['word_id'] as int,
        reviewedAt: DateTime.fromMillisecondsSinceEpoch(map['reviewed_at'] as int),
        grade: map['grade'] as int,
        stageBefore: map['stage_before'] as int,
        stageAfter: map['stage_after'] as int,
        intervalDays: map['interval_days'] as int,
      );
}