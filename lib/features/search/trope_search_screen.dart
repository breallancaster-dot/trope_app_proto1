// lib/features/search/trope_search_screen.dart
import 'package:flutter/material.dart';

import '../../data/book.dart';
import '../../data/book_repository.dart';
import '../../data/user_lists.dart';
import '../../widgets/book_cover.dart';
import '../../screens/book_detail_screen.dart';

enum _Sort { az, popular }
enum _QuickAction { toTbr, toRead, toDnf, remove }

class TropeSearchScreen extends StatefulWidget {
  static const route = '/trope-search';
  const TropeSearchScreen({super.key});

  @override
  State<TropeSearchScreen> createState() => _TropeSearchScreenState();
}

class _TropeSearchScreenState extends State<TropeSearchScreen> {
  bool _loading = true;

  // source
  List<String> _allTropes = <String>[];

  // selection + computed state
  final List<String> _selected = <String>[];
  Set<String> _viableNext = <String>{};
  List<Book> _matchingBooks = <Book>[];

  // per-row shelf cache (for badges)
  final Map<String, Shelf?> _shelfCache = <String, Shelf?>{};

  // filters
  String _tropeFilter = '';   // MAIN: filters trope chips
  String _bookQuery = '';     // optional: filters matched books by title/author

  // sort
  late Map<String, int> _tropeCountLc; // lc-key -> count
  _Sort _sort = _Sort.az;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final repo = BookRepository.instance;
    await repo.load();

    _tropeCountLc = repo.tropeCounts();
    _allTropes = repo.allTropes(); // Title Case for display

    // prefill from navigation (e.g. coming from book detail chip)
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map && args['prefill'] is List) {
      final List pre = args['prefill'] as List;
      for (final raw in pre) {
        final t = raw.toString();
        if (!_selected.contains(t)) _selected.add(t);
      }
    }

    _recompute();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _refreshShelvesFor(Iterable<Book> books) async {
    for (final b in books) {
      _shelfCache[b.id] = await UserLists.shelfFor(b.id);
    }
    if (mounted) setState(() {});
  }

  void _recompute() {
    final repo = BookRepository.instance;

    final ids = repo.bookIdsForSelectedTropes(_selected);
    var books = repo.booksByIds(ids);

    if (_bookQuery.trim().isNotEmpty) {
      final q = _bookQuery.toLowerCase().trim();
      books = books
          .where((b) =>
              b.title.toLowerCase().contains(q) ||
              b.author.toLowerCase().contains(q))
          .toList();
    }

    books.sort(
      (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
    );
    _viableNext = repo.viableNextTropes(_selected);
    _matchingBooks = books;

    _refreshShelvesFor(_matchingBooks);
  }

  void _toggleTrope(String trope) {
    setState(() {
      if (_selected.contains(trope)) {
        _selected.remove(trope);
      } else {
        if (_selected.length >= 5) return; // cap
        _selected.add(trope);
      }
      _recompute();
    });
  }

  void _clearAll() {
    setState(() {
      _selected.clear();
      _tropeFilter = "";
      _bookQuery = "";
      _recompute();
    });
  }

  bool _isDisabledChip(String trope) {
    if (_selected.contains(trope)) return false;
    if (_selected.length >= 5) return true;
    return !_viableNext.contains(trope.toLowerCase());
  }

  List<String> _visibleTropes() {
    // text filter for trope list
    final f = _tropeFilter.trim().toLowerCase();
    Iterable<String> src =
        _allTropes.where((t) => f.isEmpty || t.toLowerCase().contains(f));

    // sort
    if (_sort == _Sort.az) {
      final list = src.toList()
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      return list;
    } else {
      // Popular: by count desc, tie-break A–Z
      final list = src.toList()
        ..sort((a, b) {
          final ca = _tropeCountLc[a.toLowerCase()] ?? 0;
          final cb = _tropeCountLc[b.toLowerCase()] ?? 0;
          if (cb != ca) return cb.compareTo(ca);
          return a.toLowerCase().compareTo(b.toLowerCase());
        });
      return list;
    }
  }

  // ---------------- UI helpers ----------------

  Widget _buildChip(String trope) {
    final selected = _selected.contains(trope);
    final disabled = _isDisabledChip(trope);

    return FilterChip(
      label: Text(
        trope,
        style: TextStyle(
          color: disabled
              ? Colors.grey.shade600
              : (selected ? Colors.white : null),
        ),
      ),
      selected: selected,
      onSelected: disabled ? null : (_) => _toggleTrope(trope),
      backgroundColor: disabled ? Colors.grey.shade200 : null,
      selectedColor: Theme.of(context).colorScheme.primary,
      checkmarkColor: selected ? Colors.white : null,
      shape: StadiumBorder(
        side: BorderSide(
          color: disabled
              ? Colors.grey.shade300
              : Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
    );
  }

  Future<void> _quickAddSheet(Book b) async {
    final current = _shelfCache[b.id]; // may be null
    final chosen = await showModalBottomSheet<_QuickAction>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        Widget tile({
          required IconData icon,
          required String label,
          required _QuickAction action,
          bool selected = false,
        }) {
          return ListTile(
            leading: Icon(icon, color: selected ? Theme.of(ctx).colorScheme.primary : null),
            title: Row(
              children: [
                Text(label),
                if (selected) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.check_circle, size: 18),
                ]
              ],
            ),
            onTap: () => Navigator.pop(ctx, action),
          );
        }

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              tile(
                icon: Icons.bookmark_add_outlined,
                label: 'Add to TBR',
                action: _QuickAction.toTbr,
                selected: current == Shelf.tbr,
              ),
              tile(
                icon: Icons.check_circle_outline,
                label: 'Mark as Read',
                action: _QuickAction.toRead,
                selected: current == Shelf.read,
              ),
              tile(
                icon: Icons.not_interested_outlined,
                label: 'Mark as DNF',
                action: _QuickAction.toDnf,
                selected: current == Shelf.dnf,
              ),
              const Divider(height: 0),
              tile(
                icon: Icons.remove_circle_outline,
                label: 'Remove from shelves',
                action: _QuickAction.remove,
                selected: current == null,
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (chosen == null) return;

    switch (chosen) {
      case _QuickAction.toTbr:
        await UserLists.addTo(Shelf.tbr, b.id);
        break;
      case _QuickAction.toRead:
        await UserLists.addTo(Shelf.read, b.id);
        break;
      case _QuickAction.toDnf:
        await UserLists.addTo(Shelf.dnf, b.id);
        break;
      case _QuickAction.remove:
        await UserLists.removeEverywhere(b.id);
        break;
    }

    _shelfCache[b.id] = await UserLists.shelfFor(b.id);
    if (mounted) setState(() {});
  }

  Widget _coverThumb(Book b) {
    // Use shared helper so assets/network/file all work
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: bookCoverWidget(b.coverUrl, w: 48, h: 72),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return const Scaffold(
        body: SafeArea(child: Center(child: CircularProgressIndicator())),
      );
    }

    final resultCount = _matchingBooks.length;
    final maxReached = _selected.length >= 5;

    return Scaffold(
      // No AppBar: full pastel background
      body: SafeArea(
        child: Column(
          children: [
            // ******** MAIN TROPES SEARCH BAR (at top) ********
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Search tropes…',
                  border: OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.search,
                onChanged: (v) => setState(() => _tropeFilter = v),
              ),
            ),

            // Sort + Clear + Selected count
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  const Text('Sort:'),
                  const SizedBox(width: 8),
                  SegmentedButton<_Sort>(
                    segments: const [
                      ButtonSegment(value: _Sort.az, label: Text('A–Z')),
                      ButtonSegment(value: _Sort.popular, label: Text('Popular')),
                    ],
                    selected: {_sort},
                    onSelectionChanged: (s) => setState(() => _sort = s.first),
                  ),
                  const Spacer(),
                  if (_selected.isNotEmpty || _bookQuery.isNotEmpty || _tropeFilter.isNotEmpty)
                    TextButton.icon(
                      onPressed: _clearAll,
                      icon: const Icon(Icons.clear_all),
                      label: const Text('Clear'),
                    ),
                ],
              ),
            ),

            // Selection header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Text(
                    _selected.isEmpty
                        ? 'Select up to 5 tropes (tap again to deselect)'
                        : 'Selected (${_selected.length}/5)',
                    style: theme.textTheme.bodyMedium!
                        .copyWith(fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  if (maxReached)
                    Text(
                      'Max selected',
                      style: theme.textTheme.bodySmall!
                          .copyWith(color: theme.colorScheme.secondary),
                    ),
                ],
              ),
            ),

            // Trope chips (vertical scroll area)
            SizedBox(
              height: 150,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _visibleTropes().map(_buildChip).toList(),
                  ),
                ),
              ),
            ),

            const Divider(height: 16),

            // Optional book title/author filter (affects results list below)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.menu_book_outlined),
                  hintText: 'Filter results by title or author (optional)',
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => setState(() {
                  _bookQuery = v;
                  _recompute();
                }),
              ),
            ),

            // Results header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  Text(
                    '$resultCount result${resultCount == 1 ? '' : 's'}',
                    style: theme.textTheme.titleMedium,
                  ),
                  const Spacer(),
                  if (_selected.isNotEmpty)
                    Flexible(
                      child: Text(
                        _selected.join(' • '),
                        style: theme.textTheme.bodySmall!
                            .copyWith(color: theme.colorScheme.outline),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                ],
              ),
            ),

            // Results list
            Expanded(
              child: resultCount == 0
                  ? const Center(
                      child: Text('No books match the current selection.'),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.only(bottom: 16),
                      itemCount: _matchingBooks.length,
                      separatorBuilder: (_, __) =>
                          Divider(height: 1, color: theme.dividerColor),
                      itemBuilder: (context, i) {
                        final b = _matchingBooks[i];
                        final shelf = _shelfCache[b.id];

                        return ListTile(
                          onTap: () {
// AFTER
Navigator.of(context).push(
  MaterialPageRoute(builder: (_) => BookDetailScreen(bookId: b.id)),
);
                          },
                          onLongPress: () => _quickAddSheet(b),
                          leading: _coverThumb(b),
                          title: Text(b.title),
                          subtitle: Text(
                            '${b.author}${b.tropes.isNotEmpty ? ' • ${b.tropes.join(', ')}' : ''}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: shelf == null
                              ? IconButton(
                                  tooltip: 'Quick add',
                                  icon: const Icon(Icons.add_circle_outline),
                                  onPressed: () => _quickAddSheet(b),
                                )
                              : _shelfBadge(shelf),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _shelfBadge(Shelf? shelf) {
    if (shelf == null) return const SizedBox.shrink();
    final (label, color) = switch (shelf) {
      Shelf.read => ('READ', Colors.green),
      Shelf.tbr  => ('TBR', Colors.blue),
      Shelf.dnf  => ('DNF', Colors.red),
    };
    return Chip(
      label: Text(label),
      labelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      backgroundColor: color.withOpacity(0.85),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
    );
  }
}
