/// 词书（内置：高中 3500 / 四级 / 六级 / 雅思）。
class WordBook {
  final int? id;
  final String key;
  final String name;
  final String? description;
  final bool builtIn;
  final bool enabled;
  final int totalWords;
  final int learnedWords;

  const WordBook({
    this.id,
    required this.key,
    required this.name,
    this.description,
    this.builtIn = true,
    this.enabled = true,
    this.totalWords = 0,
    this.learnedWords = 0,
  });

  factory WordBook.fromMap(Map<String, Object?> map) => WordBook(
        id: map['id'] as int?,
        key: map['key'] as String,
        name: map['name'] as String,
        description: map['description'] as String?,
        builtIn: (map['built_in'] as int? ?? 1) == 1,
        enabled: (map['enabled'] as int? ?? 1) == 1,
        totalWords: map['total_words'] as int? ?? 0,
        learnedWords: map['learned_words'] as int? ?? 0,
      );
}