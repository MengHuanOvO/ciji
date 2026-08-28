import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

class WordEntry {
  final String word;
  final String? phonetic;
  final String? trans;
  const WordEntry({required this.word, this.phonetic, this.trans});
}

/// 内置词书内存索引：单词 -> 音标/释义（启动时加载一次，供导入与显示使用）。
class WordLookup {
  static const List<String> _assetKeys = [
    'assets/wordbooks/GaoKao_3500.json',
    'assets/wordbooks/CET4_T.json',
    'assets/wordbooks/CET6_T.json',
    'assets/wordbooks/IELTS_3_T.json',
  ];

  static final Map<String, WordEntry> _index = {};
  static bool _loaded = false;

  static Future<void> ensureLoaded() async {
    if (_loaded) return;
    for (final key in _assetKeys) {
      final raw = await rootBundle.loadString(key);
      final list = jsonDecode(raw) as List<dynamic>;
      for (final item in list) {
        final map = item as Map<String, dynamic>;
        final name = (map['name'] as String).toLowerCase();
        final transList = map['trans'] as List<dynamic>?;
        _index[name] = WordEntry(
          word: name,
          phonetic: map['usphone'] as String?,
          trans: transList?.join('；'),
        );
      }
    }
    _loaded = true;
  }

  static WordEntry? lookup(String word) => _index[word.toLowerCase()];
}