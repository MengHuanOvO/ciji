import '../../data/repositories/word_repository.dart';
import '../dictionary/word_lookup.dart';
import 'difficulty_analyzer.dart';
import 'text_tokenizer.dart';

class CandidateWord {
  final String word;
  final int count;
  final String? phonetic;
  final String? trans;
  const CandidateWord({
    required this.word,
    required this.count,
    this.phonetic,
    this.trans,
  });
}

class ImportCandidates {
  final List<CandidateWord> words; // 按词频降序
  final List<CandidateWord> difficultWords; // 按难度降序（文章难词模式）
  const ImportCandidates({required this.words, required this.difficultWords});
}

/// 导入服务：把任意文本转成候选单词（去停用词、去已知词、自动查释义）。
class ImportService {
  final WordRepository words;
  const ImportService(this.words);

  Future<ImportCandidates> extractCandidates(String text) async {
    final tokenizer = TextTokenizer();
    final freq = tokenizer.frequency(text);
    final known = await words.knownTexts();

    final candidates = <CandidateWord>[];
    freq.forEach((w, c) {
      if (known.contains(w)) return;
      final entry = WordLookup.lookup(w);
      candidates.add(CandidateWord(
        word: w,
        count: c,
        phonetic: entry?.phonetic,
        trans: entry?.trans,
      ));
    });
    candidates.sort((a, b) => b.count.compareTo(a.count));

    final analyzer = DifficultyAnalyzer(knownWords: known);
    final difficult = analyzer
        .rank(freq.keys.toList(), topN: 60)
        .where((d) => !known.contains(d.word))
        .map((d) => candidates.firstWhere((c) => c.word == d.word))
        .toList();

    return ImportCandidates(words: candidates, difficultWords: difficult);
  }
}