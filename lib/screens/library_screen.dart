// lib/screens/library_screen.dart
import 'package:flutter/material.dart';
import '../data/book.dart';
import '../data/book_repository.dart';
import '../data/user_lists.dart';
import '../widgets/shelf_card.dart';

class LibraryScreen extends StatefulWidget {
  static const route = '/library';
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen>
    with AutomaticKeepAliveClientMixin {
  bool _loading = true;

  final Map<Shelf, List<Book>> _sections = <Shelf, List<Book>>{
    Shelf.tbr: <Book>[],
    Shelf.read: <Book>[],
    Shelf.dnf: <Book>[],
  };

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
    UserLists.changes.addListener(_load);
  }

  @override
  void dispose() {
    UserLists.changes.removeListener(_load);
    super.dispose();
  }

  Set<String> _normalizeIds(Iterable<dynamic> raw, BookRepository repo) {
    final out = <String>{};
    for (final id in raw) {
      final s = id.toString();
      final resolved = repo.resolveId(s) ?? s;
      out.add(resolved);
    }
    return out;
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    final repo = BookRepository.instance;
    await repo.load();

    final readRaw = await UserLists.all(Shelf.read);
    final tbrRaw = await UserLists.all(Shelf.tbr);
    final dnfRaw = await UserLists.all(Shelf.dnf);

    final readIds = _normalizeIds(readRaw, repo);
    final tbrIds = _normalizeIds(tbrRaw, repo);
    final dnfIds = _normalizeIds(dnfRaw, repo);

    _sections[Shelf.read] = repo.booksByIds(readIds);
    _sections[Shelf.tbr] = repo.booksByIds(tbrIds);
    _sections[Shelf.dnf] = repo.booksByIds(dnfIds);

    for (final s in Shelf.values) {
      _sections[s]!.sort(
        (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
      );
    }

    if (!mounted) return;
    setState(() => _loading = false);
  }

  Widget _header(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        children: [
          // Pretty centered "Library" bar
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                'Library',
                style: theme.textTheme.headlineSmall!
                    .copyWith(fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Quick counts
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chip(theme, 'Read: ${_sections[Shelf.read]!.length}'),
              _chip(theme, 'TBR: ${_sections[Shelf.tbr]!.length}'),
              _chip(theme, 'DNF: ${_sections[Shelf.dnf]!.length}'),
            ],
          ),
        ],
      ),
    );
  }

  Chip _chip(ThemeData theme, String label) => Chip(
        label: Text(label),
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        labelStyle: TextStyle(
          color: theme.colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      );

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        children: [
          _header(context),

          // Three shelves preview (tap a card to open ShelfDetailScreen)
          ShelfCard(
            shelf: Shelf.tbr,
            books: _sections[Shelf.tbr] ?? const [],
            thumbCount: 3,
          ),
          ShelfCard(
            shelf: Shelf.read,
            books: _sections[Shelf.read] ?? const [],
            thumbCount: 3,
          ),
          ShelfCard(
            shelf: Shelf.dnf,
            books: _sections[Shelf.dnf] ?? const [],
            thumbCount: 3,
          ),

          const SizedBox(height: 24),
          Center(
            child: Text(
              'Tip: long-press a cover within a shelf to remove it.',
              style: TextStyle(color: theme.colorScheme.outline),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
