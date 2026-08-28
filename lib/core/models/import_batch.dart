/// 一次导入记录（拍照 / 相册 / 粘贴 / 文章难词）。
class ImportBatch {
  final int? id;
  final String type;
  final String? sourceText;
  final DateTime createdAt;
  final int wordsAdded;

  const ImportBatch({
    this.id,
    required this.type,
    this.sourceText,
    required this.createdAt,
    required this.wordsAdded,
  });

  factory ImportBatch.fromMap(Map<String, Object?> map) => ImportBatch(
        id: map['id'] as int?,
        type: map['type'] as String,
        sourceText: map['source_text'] as String?,
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
        wordsAdded: map['words_added'] as int? ?? 0,
      );
}