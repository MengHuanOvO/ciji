/// 单词学习状态（艾宾浩斯调度核心数据）。
/// stage: 0=新词未学，1..n=已复习次数（对应间隔阶段）。
class StudyState {
  final int wordId;
  int stage;
  DateTime? lastReviewAt;
  DateTime? nextReviewAt;
  int reviewCount;
  int correctCount;
  int wrongCount;
  int lapses;
  bool isMastered;

  StudyState({
    required this.wordId,
    this.stage = 0,
    this.lastReviewAt,
    this.nextReviewAt,
    this.reviewCount = 0,
    this.correctCount = 0,
    this.wrongCount = 0,
    this.lapses = 0,
    this.isMastered = false,
  });

  factory StudyState.fromMap(Map<String, Object?> map) => StudyState(
        wordId: map['word_id'] as int,
        stage: map['stage'] as int? ?? 0,
        lastReviewAt: map['last_review_at'] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(map['last_review_at'] as int),
        nextReviewAt: map['next_review_at'] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(map['next_review_at'] as int),
        reviewCount: map['review_count'] as int? ?? 0,
        correctCount: map['correct_count'] as int? ?? 0,
        wrongCount: map['wrong_count'] as int? ?? 0,
        lapses: map['lapses'] as int? ?? 0,
        isMastered: (map['is_mastered'] as int? ?? 0) == 1,
      );

  Map<String, Object?> toMap() => {
        'word_id': wordId,
        'stage': stage,
        'last_review_at': lastReviewAt?.millisecondsSinceEpoch,
        'next_review_at': nextReviewAt?.millisecondsSinceEpoch,
        'review_count': reviewCount,
        'correct_count': correctCount,
        'wrong_count': wrongCount,
        'lapses': lapses,
        'is_mastered': isMastered ? 1 : 0,
      };
}