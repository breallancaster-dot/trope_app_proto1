// lib/features/search/trope_search_screen.dart
import 'package:flutter/material.dart';

import '../../data/book.dart';
import '../../data/book_repository.dart';
import '../../widgets/book_cover.dart';
import '../../screens/book_detail_screen.dart';

class TropeSearchScreen extends StatefulWidget {
  static const route = '/trope-search';
  const TropeSearchScreen({super.key});

  @override
  State<TropeSearchScreen> createState() => _TropeSearchScreenState();
}
  String _tropeFilter = '';
  enum _Sort { az, popular }
  _Sort _sort = _Sort.az;

  // cached for Popular sort
  late Map<String, int> _tropeCountLc; // lc-key -> count

class _TropeSearchScreenState extends State<TropeSearchScreen> {
  bool _loading = true;
  List<String> _allTropes = [];
  final List<String> _selected = [];
  Set<String> _viableNext = {};
  Set<String> _matchingBookIds = {};
  List<Book> _matchingBooks = [];
  String _query = "";

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final repo = BookRepository.instance;
    await repo.load();
    _allTropes = repo.allTropes();
    _recompute();
    setState(() => _loading = false);
  }

  void _recompute() {
    final repo = BookRepository.instance;

    _matchingBookIds = repo.bookIdsForSelectedTropes(_selected);
    _viableNext = repo.viableNextTropes(_selected);

    var books = repo.booksByIds(_matchingBookIds);
    if (_query.trim().isNotEmpty) {
      final q = _query.trim().toLowerCase();
      books = books.where((b) {
        return b.title.toLowerCase().contains(q) ||
            b.author.toLowerCase().contains(q);
      }).toList();
    }
    books.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    _matchingBooks = books;
  }

  void _toggleTrope(String trope) {
    setState(() {
      if (_selected.contains(trope)) {
        _selected.remove(trope);
      } else {
        if (_selected.length >= 5) return; // max 5 selected
        _selected.add(trope);
      }
      _recompute();
    });
  }

  void _clearAll() {
    setState(() {
      _selected.clear();
      _query = "";
      _recompute();
    });
  }

  bool _isDisabledChip(String trope) {
    if (_selected.contains(trope)) return false;
    if (_selected.length >= 5) return true;
    return !_viableNext.contains(trope.toLowerCase());
  }

  Widget _buildChip(String trope) {
    final selected = _selected.contains(trope);
    final disabled = _isDisabledChip(trope);

    return FilterChip(
      label: Text(
        trope,
        style: TextStyle(
          color: disabled
              ? Colors.grey.shade500
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text("Search by Tropes")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final resultCount = _matchingBooks.length;
    final maxReached = _selected.length >= 5;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Search by Tropes"),
        actions: [
          if (_selected.isNotEmpty || _query.isNotEmpty)
            TextButton.icon(
              onPressed: _clearAll,
              icon: const Icon(Icons.clear_all),
              label: const Text("Clear"),
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.onPrimary,
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // inline query for title/author narrowing
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: "Filter by title or author (optional)",
                border: OutlineInputBorder(),
              ),
              onChanged: (v) {
                setState(() {
                  _query = v;
                  _recompute();
                });
              },
            ),
          ),

          // selection status / helper
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Text(
                  _selected.isEmpty
                      ? "Select up to 5 tropes"
                      : "Selected (${_selected.length}/5)",
                  style: theme.textTheme.bodyMedium!
                      .copyWith(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                if (maxReached)
                  Text(
                    "Max selected",
                    style: theme.textTheme.bodySmall!
                        .copyWith(color: theme.colorScheme.secondary),
                  ),
              ],
            ),
          ),

          // chips row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _allTropes.map(_buildChip).toList(),
              ),
            ),
          ),

          const Divider(height: 16),

          // results header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                Text(
                  "$resultCount result${resultCount == 1 ? '' : 's'}",
                  style: theme.textTheme.titleMedium,
                ),
                const Spacer(),
                if (_selected.isNotEmpty)
                  Expanded(
                    child: Text(
                      _selected.join(" • "),
                      style: theme.textTheme.bodySmall!
                          .copyWith(color: theme.colorScheme.outline),
                      textAlign: TextAlign.end,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
              ],
            ),
          ),

          // results list
          Expanded(
            child: resultCount == 0
                ? const Center(
                    child: Text("No books match the current selection."),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.only(bottom: 16),
                    itemCount: _matchingBooks.length,
                    separatorBuilder: (_, __) =>
                        Divider(height: 1, color: theme.dividerColor),
                    itemBuilder: (context, index) {
                      final b = _matchingBooks[index];
                      return ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: bookCoverWidget(b.coverUrl, w: 48, h: 72),
                        ),
                        title: Text(b.title),
                        subtitle: Text(
                          "${b.author}${b.tropes.isNotEmpty ? " • ${b.tropes.join(', ')}" : ""}",
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
