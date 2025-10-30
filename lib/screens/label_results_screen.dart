// lib/screens/label_results_screen.dart
import 'dart:math';
import 'package:flutter/material.dart';

import '../data/book.dart';
import '../data/book_repository.dart';
import '../widgets/book_cover.dart';
import 'book_detail_screen.dart';

enum LabelKind { trope, subgenre }

class LabelResultsScreen extends StatefulWidget {
  static const route = '/label-results';

  static LabelResultsScreen fromRouteArgs(BuildContext ctx) {
    final args = ModalRoute.of(ctx)?.settings.arguments;
    final label = (args is Map && args['label'] is String) ? (args['label'] as String) : '';
    final kindStr = (args is Map && args['kind'] is String) ? (args['kind'] as String) : 'trope';
    final kind = kindStr.toLowerCase() == 'subgenre' ? LabelKind.subgenre : LabelKind.trope;
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

class _LabelResultsScreenState extends State<LabelResultsScreen> {
  bool _loading = true;
  List<Book> _books = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = BookRepository.instance;
    await repo.load();

    final labelLc = widget.label.trim().toLowerCase();
    final all = repo.allBooks();

    List<Book> filtered;
    if (widget.kind == LabelKind.trope) {
      filtered = all.where((b) => b.tropes.any((t) => t.toLowerCase() == labelLc)).toList();
    } else {
      filtered = all.where((b) => b.subgenres.any((s) => s.toLowerCase() == labelLc)).toList();
    }

    // Deduplicate + sort
    final seen = <String>{};
    filtered.removeWhere((b) => !seen.add(b.id));
    filtered.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));

    if (!mounted) return;
    setState(() {
      _books = filtered;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final heading = '${widget.kind == LabelKind.trope ? 'Trope' : 'Subgenre'} • ${widget.label}';

    if (_loading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator(color: theme.colorScheme.primary)),
      );
    }

    return Scaffold(
      body: _books.isEmpty
          ? Padding(
              padding: const EdgeInsets.fromLTRB(16, 64, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(heading, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text('No books found.', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline)),
                ],
              ),
            )
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 48, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(heading, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 6),
                        Text(
                          '${_books.length} book${_books.length == 1 ? '' : 's'}',
                          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline),
                        ),
                        const SizedBox(height: 12),
                        const Divider(height: 1),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                  sliver: SliverLayoutBuilder(
                    builder: (ctx, constraints) {
                      final w = constraints.crossAxisExtent;
                      final targetCols = max(3, (w / 140).floor());
                      final spacing = 12.0;
                      final colCount = targetCols;
                      final totalGutters = spacing * (colCount - 1);
                      final itemW = (w - totalGutters) / colCount;
                      final itemH = itemW * 1.5;

                      // Covers only -> exact aspect, no bottom overflow
                      return SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: colCount,
                          crossAxisSpacing: spacing,
                          mainAxisSpacing: spacing,
                          childAspectRatio: itemW / itemH,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (ctx, i) {
                            final b = _books[i];
                            return InkWell(
                              onTap: () => Navigator.of(context).push(
                                BookDetailScreen.materialRoute(bookId: b.id),
                              ),
                              child: bookCoverWidget(
                                b.coverUrl,
                                w: itemW,
                                h: itemH,
                                borderRadius: const BorderRadius.all(Radius.circular(8)),
                              ),
                            );
                          },
                          childCount: _books.length,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
