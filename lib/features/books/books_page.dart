import 'package:flutter/material.dart';

import '../../core/models/word_book.dart';
import '../../data/repositories/word_repository.dart';
import '../wordlist/wordlist_page.dart';

/// 词书页：内置词书进度 + 启用开关 + 查看单词。
class BooksPage extends StatefulWidget {
  const BooksPage({super.key});

  @override
  State<BooksPage> createState() => _BooksPageState();
}

class _BooksPageState extends State<BooksPage> {
  List<WordBook>? _books;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final books = await WordRepository.instance.getBooks();
    if (mounted) setState(() => _books = books);
  }

  Future<void> _toggle(WordBook book) async {
    if (book.id == null) return;
    await WordRepository.instance.setBookEnabled(book.id!, !book.enabled);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final books = _books;
    return Scaffold(
      appBar: AppBar(title: const Text('词书')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: books == null
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  for (final b in books)
                    Card(
                      child: Column(
                        children: [
                          ListTile(
                            title: Text(b.name),
                            subtitle: Text(
                              '${b.description ?? ''}\n已学 ${b.learnedWords} / ${b.totalWords}',
                            ),
                            trailing: Switch(
                              value: b.enabled,
                              onChanged: (_) => _toggle(b),
                            ),
                          ),
                          LinearProgressIndicator(
                            value: b.totalWords == 0
                                ? 0
                                : b.learnedWords / b.totalWords,
                            minHeight: 4,
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => WordListPage(initialBookId: b.id),
                                ),
                              ),
                              icon: const Icon(Icons.list, size: 18),
                              label: const Text('查看单词'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 8),
                  const Text(
                    '开关=是否进入每日新学队列；点「查看单词」浏览该词书全部单词。',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
      ),
    );
  }
}