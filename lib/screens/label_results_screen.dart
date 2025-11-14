// lib/screens/label_results_screen.dart
import 'dart:math';

import 'package:flutter/material.dart';

import '../data/book.dart';
import '../data/book_repository.dart';
import '../widgets/book_cover.dart';
import '../widgets/book_results_list.dart';
import 'book_detail_screen.dart';

enum LabelKind { trope, subgenre }

class LabelResultsScreen extends StatefulWidget {
  static const route = '/label-results';

  /// Kept for compatibility if anything still uses it.
  static LabelResultsScreen fromRouteArgs(BuildContext ctx) {
    final args = ModalRoute.of(ctx)?.settings.arguments;
    String label = '';
    LabelKind kind = LabelKind.trope;

    if (args is Map) {
      if (args['label'] is String) {
        label = args['label'] as String;
      }
      if (args['kind'] is String) {
        final k = (args['kind'] as String).toLowerCase();
        if (k == 'subgenre') {
          kind = LabelKind.subgenre;
        } else {
          kind = LabelKind.trope;
        }
      }
    }

    return LabelResultsScreen(label: label, kind: kind);
  }

  final String label;
  final LabelKind kind;

  const LabelResultsScreen({
    super.key,
    required this.label,
    required this.kind,
  });

  @override
  State<LabelResultsScreen> createState() => _LabelResultsScreenState();
}

enum _ViewMode { grid, list }

class _LabelResultsScreenState extends State<LabelResultsScreen> {
  bool _loading = true;
  List<Book> _books = const [];
  _ViewMode _viewMode = _ViewMode.grid;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant LabelResultsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.label != widget.label || oldWidget.kind != widget.kind) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
    });

    final repo = BookRepository.instance;
    await repo.load();
    final all = repo.allBooks();

    // Filter, then force uniqueness by book.id in case upstream data is messy.
    final Map<String, Book> byId = <String, Book>{};

    for (final b in all) {
      final matches = widget.kind == LabelKind.trope
          ? b.tropes.contains(widget.label)
          : b.subgenres.contains(widget.label);
      if (matches) {
        byId[b.id] = b; // last one wins, but id ensures no duplicates
      }
    }

    final matches = byId.values.toList(growable: false);
    matches.sort(
      (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
    );

    setState(() {
      _books = matches;
      _loading = false;
    });
  }

  void _openBook(BuildContext context, Book book) {
    Navigator.of(context).pushNamed(
      BookDetailScreen.route,
      arguments: {'bookId': book.id},
    );
  }

  String get _heading {
    if (widget.label.isEmpty) return 'Results';
    return widget.label;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(_heading),
        ),
        body: Center(
          child: CircularProgressIndicator(
            color: theme.colorScheme.primary,
          ),
        ),
      );
    }

    final countText =
        '${_books.length} book${_books.length == 1 ? '' : 's'}';

    return Scaffold(
      appBar: AppBar(
        title: Text(_heading),
        actions: [
          IconButton(
            tooltip:
                _viewMode == _ViewMode.grid ? 'Show list' : 'Show grid',
            onPressed: () {
              setState(() {
                _viewMode = _viewMode == _ViewMode.grid
                    ? _ViewMode.list
                    : _ViewMode.grid;
              });
            },
            icon: Icon(
              _viewMode == _ViewMode.grid
                  ? Icons.view_list_outlined
                  : Icons.grid_view_outlined,
            ),
          ),
        ],
      ),
      body: _books.isEmpty
          ? Center(
              child: Text(
                'No books found for this ${widget.kind == LabelKind.trope ? 'trope' : 'subgenre'}.',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: summary row
                Padding(
                  padding:
                      const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _heading,
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        countText,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: _viewMode == _ViewMode.grid
                      ? _buildGrid(context)
                      : BookResultsList(books: _books),
                ),
              ],
            ),
    );
  }

  Widget _buildGrid(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        // Aim for ~120px wide covers; clamp for sanity.
        const idealItemWidth = 120.0;
        const minCols = 2;
        const maxCols = 4;
        final cols = max(
          minCols,
          min(maxCols, (width / idealItemWidth).floor()),
        );
        const spacing = 12.0;
        final itemWidth =
            (width - spacing * (cols - 1)) / cols;
        final itemHeight = itemWidth * 1.5;

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
          itemCount: _books.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
            childAspectRatio: itemWidth / itemHeight,
          ),
          itemBuilder: (context, index) {
            final book = _books[index];
            return InkWell(
              onTap: () => _openBook(context, book),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: bookCoverWidget(
                        book.coverUrl,
                        w: itemWidth,
                        h: itemHeight,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    book.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  if (book.author.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      book.author,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}
