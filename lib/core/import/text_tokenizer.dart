/// 英文文本分词器：小写化、去标点、去停用词。
class TextTokenizer {
  static final RegExp _wordPattern = RegExp(r"[A-Za-z][A-Za-z'’\-]*[A-Za-z]|[A-Za-z]");

  static const Set<String> stopwords = {
    'a', 'an', 'the', 'and', 'or', 'but', 'if', 'then', 'else', 'when',
    'while', 'so', 'for', 'to', 'of', 'in', 'on', 'at', 'by', 'with',
    'from', 'up', 'down', 'out', 'off', 'over', 'under', 'again',
    'further', 'once', 'here', 'there', 'all', 'any', 'both', 'each',
    'few', 'more', 'most', 'other', 'some', 'such', 'no', 'nor', 'not',
    'only', 'own', 'same', 'than', 'too', 'very', 'can', 'will', 'just',
    'don', 'should', 'now', 'is', 'are', 'was', 'were', 'be', 'been',
    'being', 'have', 'has', 'had', 'do', 'does', 'did', 'am', 'as', 'it',
    'its', 'this', 'that', 'these', 'those', 'i', 'you', 'he', 'she',
    'we', 'they', 'me', 'him', 'her', 'us', 'them', 'my', 'your', 'his',
    'their', 'our', 'what', 'which', 'who', 'whom', 'whose', 'how', 'why',
    'where', 'about', 'into', 'through', 'during', 'before', 'after',
    'above', 'below', 'between', 'among', 'because', 'since', 'until',
    'per', 'via', 'against', 'toward', 'upon', 'also', 'may', 'might',
    'must', 'shall', 'could', 'would', 'yes',
  };

  /// 分词并过滤：长度>=2、非停用词。
  List<String> tokenize(String text) {
    final words = <String>[];
    for (final m in _wordPattern.allMatches(text.toLowerCase())) {
      final w = m.group(0)!;
      if (w.length < 2) continue;
      if (stopwords.contains(w)) continue;
      words.add(w);
    }
    return words;
  }

  /// 词频统计。
  Map<String, int> frequency(String text) {
    final freq = <String, int>{};
    for (final w in tokenize(text)) {
      freq[w] = (freq[w] ?? 0) + 1;
    }
    return freq;
  }
}