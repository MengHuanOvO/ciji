import 'package:ciji/core/import/difficulty_analyzer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('长词（生僻）优先', () {
    const a = DifficultyAnalyzer();
    final ranked = a.rank(['cat', 'photosynthesis', 'apple', 'dog']);
    expect(ranked.first.word, 'photosynthesis');
  });

  test('已知词减分', () {
    const a = DifficultyAnalyzer(knownWords: {'apple'});
    final ranked = a.rank(['apple', 'photosynthesis']);
    expect(ranked.first.word, 'photosynthesis');
  });

  test('去重', () {
    const a = DifficultyAnalyzer();
    expect(a.rank(['book', 'book', 'book']).length, 1);
  });

  test('topN 限制', () {
    const a = DifficultyAnalyzer();
    final ranked = a.rank(List.generate(30, (i) => 'word$i'), topN: 10);
    expect(ranked.length, 10);
  });
}