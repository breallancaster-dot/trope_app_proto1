// lib/screens/books_list_screen.dart
import 'package:flutter/material.dart';

import '../data/book.dart';
import '../data/book_repository.dart';
import '../widgets/book_cover.dart';
import 'book_detail_screen.dart';

class BooksListScreen extends StatefulWidget {
  static const route = '/books-list';
  const BooksListScreen({super.key});

  @override
  State<BooksListScreen> createState() => _BooksListScreenState();
}

class _BooksListScreenState extends State<BooksListScreen> {
  bool _loading = true;
  String _query = '';
  List<Book> _books = [];
  List<Book> _filtered = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = BookRepository.instance;
    await repo.load();
    _books = repo.allBooks();
    _applyFilter();
    setState(() => _loading = false);
  }

  void _applyFilter() {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) {
      _filtered = [..._books]..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    } else {
      _filtered = _books.where((b) {
        return b.title.toLowerCase().contains(q) ||
               b.author.toLowerCase().contains(q) ||
               b.tropes.any((t) => t.toLowerCase().contains(q));
      }).toList()
        ..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('All Books')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('All Books')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search title, author, or trope…',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() {
                _query = v;
                _applyFilter();
              }),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${_filtered.length} result${_filtered.length == 1 ? '' : 's'}',
                style: theme.textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const Divider(height: 8),
          Expanded(
            child: _filtered.isEmpty
                ? const Center(child: Text('No books match your search.'))
                : ListView.separated(
                    itemCount: _filtered.length,
                    separatorBuilder: (_, __) => Divider(height: 1, color: theme.dividerColor),
                    itemBuilder: (context, i) {
                      final b = _filtered[i];
                      return ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: bookCoverWidget(b.coverUrl, w: 48, h: 72),
                        ),
                        title: Text(b.title),
                        subtitle: Text(
                          '${b.author}${b.tropes.isNotEmpty ? ' • ${b.tropes.join(', ')}' : ''}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () {
                          Navigator.of(context).pushNamed(
                            BookDetailScreen.route,
                            arguments: {'id': b.id},
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
