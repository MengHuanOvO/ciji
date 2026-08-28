import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// SQLite 数据库单例（iOS/Android 原生 sqflite；Windows/Linux 用 ffi）。
class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  static const _dbName = 'ciji.db';
  static const _dbVersion = 1;
  Database? _db;

  Database get db {
    final d = _db;
    if (d == null) throw StateError('AppDatabase 尚未初始化，请先调用 open()');
    return d;
  }

  Future<void> open() async {
    if (_db != null) return;
    final dir = await getDatabasesPath();
    _db = await openDatabase(p.join(dir, _dbName), version: _dbVersion, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE word_books(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        key TEXT UNIQUE NOT NULL,
        name TEXT NOT NULL,
        description TEXT,
        built_in INTEGER NOT NULL DEFAULT 1,
        enabled INTEGER NOT NULL DEFAULT 1,
        total_words INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE words(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        text TEXT NOT NULL UNIQUE COLLATE NOCASE,
        phonetic TEXT,
        trans TEXT,
        source TEXT,
        freq_rank INTEGER,
        created_at INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE book_words(
        book_id INTEGER NOT NULL,
        word_id INTEGER NOT NULL,
        PRIMARY KEY (book_id, word_id)
      )
    ''');
    await db.execute('''
      CREATE TABLE study_state(
        word_id INTEGER PRIMARY KEY,
        stage INTEGER NOT NULL DEFAULT 0,
        last_review_at INTEGER,
        next_review_at INTEGER,
        review_count INTEGER NOT NULL DEFAULT 0,
        correct_count INTEGER NOT NULL DEFAULT 0,
        wrong_count INTEGER NOT NULL DEFAULT 0,
        lapses INTEGER NOT NULL DEFAULT 0,
        is_mastered INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE review_logs(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        word_id INTEGER NOT NULL,
        reviewed_at INTEGER NOT NULL,
        grade INTEGER NOT NULL,
        stage_before INTEGER NOT NULL,
        stage_after INTEGER NOT NULL,
        interval_days INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE import_batches(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        source_text TEXT,
        created_at INTEGER NOT NULL,
        words_added INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE settings(
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX idx_words_text ON words(text)');
    await db.execute('CREATE INDEX idx_study_next ON study_state(next_review_at)');
  }

  /// 重置全部数据（设置页使用）。
  Future<void> reset() async {
    final dir = await getDatabasesPath();
    final path = p.join(dir, _dbName);
    await db.close();
    _db = null;
    await deleteDatabase(path);
    await open();
  }
}