// lib/features/search/trope_search_screen.dart
import 'package:flutter/material.dart';

import '../../data/book.dart';
import '../../data/book_repository.dart';
import '../../widgets/book_results_list.dart';

/// Free-text search across the library.
///
/// Matches:
/// - title
/// - author
/// - tropes
/// - subgenres
class TropeSearchScreen extends StatefulWidget {
  static const route = '/trope-search';

  const TropeSearchScreen({super.key});

  @override
  State<TropeSearchScreen> createState() => _TropeSearchScreenState();
}

class _TropeSearchScreenState extends State<TropeSearchScreen> {
  bool _loading = true;
  String _query = '';
  List<Book> _all = const [];
  List<Book> _filtered = const [];

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
      return;
    }

    _filtered = _all.where((b) {
      final t = b.title.toLowerCase();
      final a = b.author.toLowerCase();
      final tropes = b.tropes.map((e) => e.toLowerCase());
      final subs = b.subgenres.map((e) => e.toLowerCase());
      return t.contains(q) ||
          a.contains(q) ||
          tropes.any((t) => t.contains(q)) ||
          subs.any((s) => s.contains(q));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Search')),
        body: Center(
          child: CircularProgressIndicator(
            color: theme.colorScheme.primary,
          ),
        ),
      );
    }

    _applyFilter();

    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search title, author, trope, or subgenre…',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) {
                setState(() {
                  _query = v;
                });
              },
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
