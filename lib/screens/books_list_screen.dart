// lib/screens/books_list_screen.dart
import 'package:flutter/material.dart';

import '../data/book.dart';
import '../data/book_repository.dart';
import '../widgets/book_results_list.dart';

class BooksListScreen extends StatefulWidget {
  static const route = '/books-list';

  const BooksListScreen({super.key});

  @override
  State<BooksListScreen> createState() => _BooksListScreenState();
}

class _BooksListScreenState extends State<BooksListScreen> {
  bool _loading = true;
  List<Book> _all = const [];
  List<Book> _filtered = const [];
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = BookRepository.instance;
    await repo.load();
    final all = repo.allBooks();
    setState(() {
      _all = all;
      _filtered = all;
      _loading = false;
    });
  }

  void _applyFilter() {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) {
      _filtered = _all;
    } else {
      _filtered = _all
          .where((b) =>
              b.title.toLowerCase().contains(q) ||
              b.author.toLowerCase().contains(q) ||
              b.tropes.any((t) => t.toLowerCase().contains(q)))
          .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('All Books')),
        body: Center(
          child: CircularProgressIndicator(
            color: theme.colorScheme.primary,
          ),
        ),
      );
    }

    _applyFilter();

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
              }),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${_filtered.length} result${_filtered.length == 1 ? '' : 's'}',
                style: theme.textTheme.bodyMedium!
                    .copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          const Divider(height: 8),
          Expanded(
            child: BookResultsList(books: _filtered),
          ),
        ],
      ),
    );
  }
}
