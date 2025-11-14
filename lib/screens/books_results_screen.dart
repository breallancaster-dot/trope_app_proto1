// lib/screens/books_results_screen.dart
import 'package:flutter/material.dart';

import '../data/book.dart';
import '../data/book_repository.dart';
import '../widgets/book_results_list.dart';

/// Pass arguments like:
///
/// Navigator.pushNamed(
///   context,
///   BooksResultsScreen.route,
///   arguments: {'ids': <Set<String>> OR List<String>, 'title': 'Your Title'},
/// );
///
/// OR:
///
/// Navigator.pushNamed(
///   context,
///   BooksResultsScreen.route,
///   arguments: {'query': 'search text'},
/// );
class BooksResultsScreen extends StatefulWidget {
  static const route = '/books-results';

  const BooksResultsScreen({super.key});

  @override
  State<BooksResultsScreen> createState() => _BooksResultsScreenState();
}

class _BooksResultsScreenState extends State<BooksResultsScreen> {
  bool _loading = true;
  String _title = 'Results';
  List<Book> _items = const [];

  @override
  void initState() {
    super.initState();
    // wait for context / arguments
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final repo = BookRepository.instance;
    await repo.load();

    final args = ModalRoute.of(context)?.settings.arguments;
    Set<String> ids = <String>{};
    String query = '';
    String? title;

    if (args is Map) {
      if (args['ids'] is Set<String>) {
        ids = args['ids'] as Set<String>;
      } else if (args['ids'] is List) {
        ids = (args['ids'] as List).map((e) => e.toString()).toSet();
      }
      if (args['query'] is String) {
        query = args['query'] as String;
      }
      if (args['title'] is String) {
        title = args['title'] as String;
      }
    }

    _title = title ??
        (ids.isNotEmpty
            ? 'Results'
            : (query.trim().isNotEmpty ? 'Search Results' : 'Results'));

    if (ids.isNotEmpty) {
      _items = repo.booksByIds(ids);
    } else if (query.trim().isNotEmpty) {
      final q = query.trim().toLowerCase();
      final all = repo.allBooks();
      _items = all
          .where((b) =>
              b.title.toLowerCase().contains(q) ||
              b.author.toLowerCase().contains(q) ||
              b.tropes.any((t) => t.toLowerCase().contains(q)))
          .toList();
    } else {
      _items = const <Book>[];
    }

    setState(() {
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      final theme = Theme.of(context);
      return Scaffold(
        appBar: AppBar(title: Text(_title)),
        body: Center(
          child: CircularProgressIndicator(
            color: theme.colorScheme.primary,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(_title)),
      body: BookResultsList(books: _items),
    );
  }
}
