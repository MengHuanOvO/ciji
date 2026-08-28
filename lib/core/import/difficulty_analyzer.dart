class WordDifficulty {
  final String word;
  final double score;
  final int length;
  final bool isKnown;
  const WordDifficulty({
    required this.word,
    required this.score,
    required this.length,
    required this.isKnown,
  });
}

/// 文章难词提取的启发式评分：
///  - 词越长越难；
///  - 已知（已收录/已掌握）词减分；
///  - 常见短词减分。
class DifficultyAnalyzer {
  final Set<String> knownWords;
  const DifficultyAnalyzer({this.knownWords = const {}});

  double scoreFor(String word) {
    final lower = word.toLowerCase();
    var score = 0.0;
    score += word.length.clamp(3, 14) * 0.6;
    if (word.length <= 4) score -= 1.5;
    if (knownWords.contains(lower)) score -= 3.0;
    return score;
  }

  /// 按难度从高到低排序，返回前 topN 个。
  List<WordDifficulty> rank(List<String> words, {int topN = 50}) {
    final seen = <String>{};
    final list = <WordDifficulty>[];
    for (final w in words) {
      final lower = w.toLowerCase();
      if (seen.contains(lower)) continue;
      seen.add(lower);
      list.add(WordDifficulty(
        word: lower,
        score: scoreFor(lower),
        length: lower.length,
        isKnown: knownWords.contains(lower),
      ));
    }
    list.sort((a, b) => b.score.compareTo(a.score));
    return list.take(topN).toList();
  }
}