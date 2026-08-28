import 'package:flutter/material.dart';

import '../../core/models/word.dart';
import '../../core/models/word_book.dart';
import '../../data/repositories/word_repository.dart';

/// 单词本：按词书浏览 + 搜索。
class WordListPage extends StatefulWidget {
  final int? initialBookId;
  const WordListPage({super.key, this.initialBookId});

  @override
  State<WordListPage> createState() => _WordListPageState();
}

class _WordListPageState extends State<WordListPage> {
  List<WordBook> _books = [];
  List<Word> _words = [];
  int? _bookId;
  String _query = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final books = await WordRepository.instance.getBooks();
    final bookId = widget.initialBookId ?? (books.isEmpty ? null : books.first.id);
    if (!mounted) return;
    setState(() {
      _books = books;
      _bookId = bookId;
    });
    await _loadWords();
  }

  Future<void> _loadWords() async {
    final bookId = _bookId;
    if (bookId == null) {
      if (mounted) setState(() { _words = []; _loading = false; });
      return;
    }
    final words = await WordRepository.instance.getWordsByBook(bookId, query: _query);
    if (mounted) setState(() { _words = words; _loading = false; });
  }

  void _onBookChanged(int? id) {
    setState(() { _bookId = id; _loading = true; });
    _loadWords();
  }

  void _onSearch(String q) {
    setState(() { _query = q; _loading = true; });
    _loadWords();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('单词本')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: '词书',
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _bookId,
                  isExpanded: true,
                  hint: const Text('选择词书'),
                  items: [
                    for (final b in _books)
                      DropdownMenuItem(value: b.id, child: Text('${b.name}（${b.totalWords}）')),
                  ],
                  onChanged: _onBookChanged,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              onChanged: _onSearch,
              decoration: const InputDecoration(
                hintText: '搜索单词…',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _words.isEmpty
                    ? const Center(child: Text('暂无单词'))
                    : ListView.separated(
                        itemCount: _words.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (_, i) {
                          final w = _words[i];
                          return ListTile(
                            title: Text(w.text),
                            subtitle: Text(w.trans ?? ''),
                            trailing: w.phonetic == null
                                ? null
                                : Text(w.phonetic!,
                                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}