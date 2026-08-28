import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:sqflite/sqflite.dart';

import '../../core/database/app_database.dart';
import '../../core/dictionary/word_lookup.dart';
import '../../core/models/word.dart';
import '../../core/models/word_book.dart';

/// 单词 / 词书仓库：内置词书种子化、导入、查询。
class WordRepository {
  WordRepository._();
  static final WordRepository instance = WordRepository._();

  static const List<(String, String, String, String)> _books = [
    ('gaokao3500', '高中 3500 词', '高考大纲核心词汇', 'assets/wordbooks/GaoKao_3500.json'),
    ('cet4', '大学英语四级', 'CET-4 核心词汇', 'assets/wordbooks/CET4_T.json'),
    ('cet6', '大学英语六级', 'CET-6 核心词汇', 'assets/wordbooks/CET6_T.json'),
    ('ielts', '雅思核心词汇', 'IELTS 高频词汇', 'assets/wordbooks/IELTS_3_T.json'),
  ];

  Database get _db => AppDatabase.instance.db;

  /// 首次启动时把内置词书写入数据库（幂等）。
  Future<void> seedBuiltInBooks() async {
    final count = Sqflite.firstIntValue(
          await _db.rawQuery('SELECT COUNT(*) AS c FROM word_books'),
        ) ??
        0;
    if (count > 0) return;

    await WordLookup.ensureLoaded();
    final now = DateTime.now().millisecondsSinceEpoch;

    await _db.transaction((txn) async {
      for (final (key, name, desc, asset) in _books) {
        final raw = await rootBundle.loadString(asset);
        final list = jsonDecode(raw) as List<dynamic>;
        final bookId = await txn.insert('word_books', {
          'key': key,
          'name': name,
          'description': desc,
          'built_in': 1,
          'enabled': 1,
          'total_words': list.length,
        });
        for (final item in list) {
          final map = item as Map<String, dynamic>;
          final text = (map['name'] as String).toLowerCase();
          final transList = map['trans'] as List<dynamic>?;
          await txn.insert('words', {
            'text': text,
            'phonetic': map['usphone'] as String?,
            'trans': transList?.join('；'),
            'source': key,
            'created_at': now,
          }, conflictAlgorithm: ConflictAlgorithm.ignore);
          final rows = await txn.query('words',
              columns: ['id'], where: 'text = ?', whereArgs: [text], limit: 1);
          if (rows.isNotEmpty) {
            final wordId = rows.first['id'] as int;
            await txn.insert('book_words', {'book_id': bookId, 'word_id': wordId},
                conflictAlgorithm: ConflictAlgorithm.ignore);
            // 预建学习状态（stage=0 新词），复习调度直接基于 study_state。
            await txn.insert('study_state', {'word_id': wordId},
                conflictAlgorithm: ConflictAlgorithm.ignore);
          }
        }
      }
    });
  }

  /// 词书列表（含已学进度）。
  Future<List<WordBook>> getBooks() async {
    final rows = await _db.rawQuery('''
      SELECT b.*,
        (SELECT COUNT(*) FROM study_state s
          JOIN book_words bw ON bw.word_id = s.word_id
          WHERE bw.book_id = b.id AND (s.review_count > 0 OR s.stage > 0)) AS learned_words
      FROM word_books b ORDER BY b.id
    ''');
    return rows.map(WordBook.fromMap).toList();
  }

  /// 已收录的所有单词文本（去重、小写）——导入时用来过滤已知词。
  Future<Set<String>> knownTexts() async {
    final rows = await _db.query('words', columns: ['text']);
    return rows.map((r) => (r['text'] as String).toLowerCase()).toSet();
  }

  /// 某词书下的单词（可搜索）。
  Future<List<Word>> getWordsByBook(int bookId, {String? query}) async {
    final hasQuery = query != null && query.trim().isNotEmpty;
    final sql = hasQuery
        ? '''
          SELECT w.* FROM words w JOIN book_words bw ON bw.word_id = w.id
          WHERE bw.book_id = ? AND w.text LIKE ? ORDER BY w.text LIMIT 1000
        '''
        : '''
          SELECT w.* FROM words w JOIN book_words bw ON bw.word_id = w.id
          WHERE bw.book_id = ? ORDER BY w.text LIMIT 1000
        ''';
    final rows = await _db.rawQuery(sql,
        hasQuery ? [bookId, '%${query!.trim().toLowerCase()}%'] : [bookId]);
    return rows.map(Word.fromMap).toList();
  }

  /// 全局搜索。
  Future<List<Word>> search(String query) async {
    final rows = await _db.rawQuery(
      'SELECT * FROM words WHERE text LIKE ? ORDER BY text LIMIT 200',
      ['%${query.trim().toLowerCase()}%'],
    );
    return rows.map(Word.fromMap).toList();
  }

  /// 从导入候选批量添加生词（自动去重、自动补释义），并记录导入批次。
  Future<List<Word>> addWordsFromImport(
    List<String> texts, {
    required String importType,
    String? sourceText,
  }) async {
    final now = DateTime.now();
    final added = <Word>[];
    await _db.transaction((txn) async {
      for (final raw in texts) {
        final text = raw.trim().toLowerCase();
        if (text.isEmpty) continue;
        final existing = await txn.query('words',
            columns: ['id'], where: 'text = ?', whereArgs: [text], limit: 1);
        if (existing.isNotEmpty) continue;
        final entry = WordLookup.lookup(text);
        final id = await txn.insert('words', {
          'text': text,
          'phonetic': entry?.phonetic,
          'trans': entry?.trans,
          'source': 'user',
          'created_at': now.millisecondsSinceEpoch,
        });
        await txn.insert('study_state', {'word_id': id},
            conflictAlgorithm: ConflictAlgorithm.ignore);
        added.add(Word(
          id: id,
          text: text,
          phonetic: entry?.phonetic,
          trans: entry?.trans,
          source: 'user',
          createdAt: now,
        ));
      }
      await txn.insert('import_batches', {
        'type': importType,
        'source_text': sourceText,
        'created_at': now.millisecondsSinceEpoch,
        'words_added': added.length,
      });
    });
    return added;
  }

  /// 启用 / 停用词书（停用后不再进入每日新学队列）。
  Future<void> setBookEnabled(int bookId, bool enabled) async {
    await _db.update('word_books', {'enabled': enabled ? 1 : 0},
        where: 'id = ?', whereArgs: [bookId]);
  }
}