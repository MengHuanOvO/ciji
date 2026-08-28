import 'package:ciji/core/import/text_tokenizer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final t = TextTokenizer();

  test('分词：小写化、去标点', () {
    expect(t.tokenize('Hello, World!'), ['hello', 'world']);
  });

  test('去停用词', () {
    expect(t.tokenize('The cat and the dog'), ['cat', 'dog']);
  });

  test('忽略单字母', () {
    expect(t.tokenize('I a b c ok'), ['ok']);
  });

  test('词频统计', () {
    expect(t.frequency('apple apple banana'), {'apple': 2, 'banana': 1});
  });
}