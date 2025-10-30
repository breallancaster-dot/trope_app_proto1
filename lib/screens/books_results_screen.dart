// lib/screens/books_results_screen.dart
import 'package:flutter/material.dart';

import '../data/book.dart';
import '../data/book_repository.dart';
import '../widgets/book_cover.dart';
import 'book_detail_screen.dart';

/// Pass arguments like:
///   Navigator.pushNamed(
///     context,
///     BooksResultsScreen.route,
///     arguments: {'ids': <Set<String>> OR List<String>, 'title': 'Your Title'},
///   );
/// OR
///   Navigator.pushNamed(
///     context,
///     BooksResultsScreen.route,
///     arguments: {'query': 'search text', 'title': 'Search Results'},
///   );
class BooksResultsScreen extends StatefulWidget {
  static const route = '/books-results';
  const BooksResultsScreen({super.key});

  @override
  State<BooksResultsScreen> createState() => _BooksResultsScreenState();
}

class _BooksResultsScreenState extends State<BooksResultsScreen> {
  bool _loading = true;
  String _title = 'Results';
  List<Book> _items = [];

  @override
  void initState() {
    super.initState();
    // wait for context to be ready
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final repo = BookRepository.instance;
    await repo.load();

    final args = ModalRoute.of(context)?.settings.arguments;
    Set<String> ids = {};
    String query = '';
    String? title;

    if (args is Map) {
      if (args['ids'] is Set<String>) ids = args['ids'] as Set<String>;
      if (args['ids'] is List) ids = (args['ids'] as List).map((e) => e.toString()).toSet();
      if (args['query'] is String) query = args['query'] as String;
      if (args['title'] is String) title = args['title'] as String;
    }

    _title = title ?? (ids.isNotEmpty ? 'Results' : (query.isNotEmpty ? 'Search Results' : 'Results'));

    if (ids.isNotEmpty) {
      _items = repo.booksByIds(ids);
    } else if (query.trim().isNotEmpty) {
      final q = query.trim().toLowerCase();
      final all = repo.allBooks();
      _items = all.where((b) =>
        b.title.toLowerCase().contains(q) ||
        b.author.toLowerCase().contains(q) ||
        b.tropes.any((t) => t.toLowerCase().contains(q)),
      ).toList();
    } else {
      _items = [];
    }

    _items.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(_title)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(_title)),
      body: _items.isEmpty
          ? const Center(child: Text('No results'))
          : ListView.separated(
              itemCount: _items.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: theme.dividerColor),
              itemBuilder: (context, i) {
                final b = _items[i];
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
    );
  }
}
