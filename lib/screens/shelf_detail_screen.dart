// lib/screens/shelf_detail_screen.dart
import 'dart:math';
import 'package:flutter/material.dart';

import '../data/book.dart';
import '../data/book_repository.dart';
import '../data/user_lists.dart';
import '../widgets/book_cover.dart';
import 'book_detail_screen.dart';

enum ShelfSort { title, author }
enum ViewPerRow { v3, v5, v10 }

class ShelfDetailScreen extends StatefulWidget {
  static const route = '/shelf-detail';
  final Shelf shelf;

  const ShelfDetailScreen({super.key, required this.shelf});

  /// Strongly-typed route helper
  static Route<Object?> materialRoute({required Shelf shelf}) {
    return MaterialPageRoute(
      builder: (_) => ShelfDetailScreen(shelf: shelf),
      settings: const RouteSettings(name: route),
    );
  }

  @override
  State<ShelfDetailScreen> createState() => _ShelfDetailScreenState();
}

class _ShelfDetailScreenState extends State<ShelfDetailScreen> {
  bool _loading = true;
  List<Book> _books = const [];

  ShelfSort _sort = ShelfSort.title;
  ViewPerRow _view = ViewPerRow.v3; // 3 per row by default

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final repo = BookRepository.instance;
    await repo.load();

    final ids = await UserLists.all(widget.shelf);
    final books = repo.booksByIds(ids.toSet());

    _applySort(books);

    if (!mounted) return;
    setState(() {
      _books = books;
      _loading = false;
    });
  }

  void _applySort(List<Book> list) {
    switch (_sort) {
      case ShelfSort.title:
        list.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
      case ShelfSort.author:
        list.sort((a, b) => a.author.toLowerCase().compareTo(b.author.toLowerCase()));
        break;
    }
  }

  int get _cols {
    switch (_view) {
      case ViewPerRow.v3:
        return 3;
      case ViewPerRow.v5:
        return 5;
      case ViewPerRow.v10:
        return 10;
    }
  }

  String get _title {
    switch (widget.shelf) {
      case Shelf.tbr:
        return 'To Be Read';
      case Shelf.read:
        return 'Read';
      case Shelf.dnf:
        return 'Did Not Finish';
    }
  }

  Future<void> _confirmRemove(Book b) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove from shelf?'),
        content: Text('Remove “${b.title}” from $_title?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Remove')),
        ],
      ),
    );
    if (ok == true) {
      await UserLists.removeEverywhere(b.id);
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Removed from shelf')),
      );
    }
  }

  Widget _plank(BuildContext context) {
    // A pink-ish plank matching the app vibe
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: 12,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Color.alphaBlend(scheme.primary.withOpacity(0.18), scheme.surface),
        borderRadius: const BorderRadius.all(Radius.circular(8)),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withOpacity(0.12),
            blurRadius: 3,
            offset: const Offset(0, 1),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: theme.colorScheme.primary),
        ),
      );
    }

    // Chunk books into rows
    final cols = _cols;
    final rows = <List<Book>>[];
    for (int i = 0; i < _books.length; i += cols) {
      rows.add(_books.sublist(i, min(i + cols, _books.length)));
    }
    // Ensure at least a few empty rows so planks are visible even on empty shelf
    while (rows.length < 3) {
      rows.add(const []);
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Top spacing & title
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 48, 16, 8),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: theme.colorScheme.primary.withOpacity(0.18)),
                  ),
                  child: Text(
                    _title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Controls (no ticks, just selected highlight)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // Sort
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Sort:', style: theme.textTheme.bodyMedium),
                      const SizedBox(width: 8),
                      SegmentedButton<ShelfSort>(
                        segments: const [
                          ButtonSegment(value: ShelfSort.title, label: Text('Title')),
                          ButtonSegment(value: ShelfSort.author, label: Text('Author')),
                        ],
                        selected: {_sort},
                        showSelectedIcon: false, // no checkmark
                        onSelectionChanged: (s) {
                          setState(() {
                            _sort = s.first;
                            _applySort(_books);
                          });
                        },
                      ),
                    ],
                  ),
                  // View per row
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('View:', style: theme.textTheme.bodyMedium),
                      const SizedBox(width: 8),
                      SegmentedButton<ViewPerRow>(
                        segments: const [
                          ButtonSegment(value: ViewPerRow.v3, label: Text('3')),
                          ButtonSegment(value: ViewPerRow.v5, label: Text('5')),
                          ButtonSegment(value: ViewPerRow.v10, label: Text('10')),
                        ],
                        selected: {_view},
                        showSelectedIcon: false, // no checkmark
                        onSelectionChanged: (s) => setState(() => _view = s.first),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Rows with planks
          SliverToBoxAdapter(child: SizedBox(height: 6)),
          SliverList.separated(
            itemCount: rows.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (ctx, rowIndex) {
              final rowBooks = rows[rowIndex];

              return LayoutBuilder(
                builder: (ctx, constraints) {
                  final totalW = constraints.maxWidth;
                  final spacing = 12.0;
                  final totalGutters = spacing * (cols - 1);
                  final itemW = (totalW - totalGutters - 32 /* left+right pad below */) / cols;
                  final itemH = itemW * 1.5;

                  return Column(
                    children: [
                      // top plank above the row
                      _plank(ctx),
                      const SizedBox(height: 12),

                      // covers row
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(cols, (i) {
                            final b = (i < rowBooks.length) ? rowBooks[i] : null;
                            if (b == null) {
                              return SizedBox(width: itemW, height: itemH);
                            }
                            return GestureDetector(
                              onTap: () {
                                Navigator.of(context).push(
                                  BookDetailScreen.materialRoute(bookId: b.id),
                                );
                              },
                              onLongPress: () => _confirmRemove(b),
                              child: bookCoverWidget(
                                b.coverUrl,
                                w: itemW,
                                h: itemH,
                                borderRadius: const BorderRadius.all(Radius.circular(8)),
                              ),
                            );
                          }),
                        ),
                      ),

                      // generous spacing so covers don't collide with the next plank
                      const SizedBox(height: 16),
                    ],
                  );
                },
              );
            },
          ),

          // bottom single plank
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 4),
                _plank(context),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
