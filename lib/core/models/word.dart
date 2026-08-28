/// 单词实体（内置词书或用户导入的生词）。
class Word {
  final int? id;
  final String text;
  final String? phonetic;
  final String? trans;
  final String? source; // 词书 key 或 'user'
  final int? freqRank;
  final DateTime? createdAt;

  const Word({
    this.id,
    required this.text,
    this.phonetic,
    this.trans,
    this.source,
    this.freqRank,
    this.createdAt,
  });

  factory Word.fromMap(Map<String, Object?> map) => Word(
        id: map['id'] as int?,
        text: map['text'] as String,
        phonetic: map['phonetic'] as String?,
        trans: map['trans'] as String?,
        source: map['source'] as String?,
        freqRank: map['freq_rank'] as int?,
        createdAt: map['created_at'] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'text': text,
        'phonetic': phonetic,
        'trans': trans,
        'source': source,
        'freq_rank': freqRank,
        'created_at': createdAt?.millisecondsSinceEpoch,
      };
}