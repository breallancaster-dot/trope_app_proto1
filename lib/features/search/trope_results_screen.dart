// lib/features/search/trope_results_screen.dart
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../../data/book.dart';
import '../../data/book_repository.dart';
import '../../data/user_lists.dart';
import '../../screens/book_detail_screen.dart';
import 'trope_picker_screen.dart';

class TropeResultsScreen extends StatefulWidget {
  static const route = '/trope-results';

  /// Optional helper if you prefer builder refs in Navigator stacks
  static TropeResultsScreen fromRouteArgs(BuildContext _) =>
      const TropeResultsScreen(selected: [],);

  const TropeResultsScreen({super.key, required List<String> selected});

  @override
  State<TropeResultsScreen> createState() => _TropeResultsScreenState();
}

class _TropeResultsScreenState extends State<TropeResultsScreen> {
  bool _loading = true;
  List<String> _selected = const [];
  List<Book> _books = const [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    final list = (args is Map && args['selected'] is List)
        ? (args['selected'] as List).map((e) => e.toString()).toList()
        : <String>[];
    if (list.toString() != _selected.toString()) {
      _selected = list;
      _load();
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    final repo = BookRepository.instance;
    await repo.load();

    final ids = repo.bookIdsForSelectedTropes(_selected);
    var books = repo.booksByIds(ids);
    books.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));

    setState(() {
      _books = books;
      _loading = false;
    });
  }

  Future<void> _openAddTropes() async {
    // Go to picker with current selection highlighted.
    await Navigator.of(context).pushNamed(
      TropePickerScreen.route,
      arguments: {'prefill': List<String>.from(_selected)},
    );
    await _load();
  }

  Future<void> _clearSelection() async {
    // Go to a BLANK picker state.
    await Navigator.of(context).pushNamed(
      TropePickerScreen.route,
      arguments: {'prefill': const <String>[]},
    );
    // If user returns here via back, just reload (shelves may have changed).
    await _load();
  }

  Widget _coverThumb(Book b) {
    final String url = (b.coverUrl ?? '').trim();
    const w = 48.0, h = 72.0;

    Widget fallback() => const SizedBox(
          width: w,
          height: h,
          child: DecoratedBox(
            decoration: BoxDecoration(color: Colors.black12),
            child: Icon(Icons.menu_book, color: Colors.black38, size: 20),
          ),
        );

    if (url.isEmpty) return fallback();

    if (url.startsWith('assets/')) {
      return Image.asset(url, width: w, height: h, fit: BoxFit.cover, errorBuilder: (_, __, ___) => fallback());
    }
    if (url.startsWith('http')) {
      return Image.network(url, width: w, height: h, fit: BoxFit.cover, errorBuilder: (_, __, ___) => fallback());
    }
    if (kIsWeb) return fallback();
    try {
      return Image.file(File(url), width: w, height: h, fit: BoxFit.cover, errorBuilder: (_, __, ___) => fallback());
    } catch (_) {
      return fallback();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selected.isEmpty ? 'Results' : _selected.join(' • '),
        ),
        actions: [
          if (_selected.isNotEmpty)
            TextButton.icon(
              onPressed: _clearSelection,
              icon: const Icon(Icons.clear_all),
              label: const Text('Clear'),
            ),
          IconButton(
            tooltip: 'Add tropes',
            onPressed: _openAddTropes,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: _books.isEmpty
          ? const Center(child: Text('No matching books.'))
          : ListView.separated(
              padding: const EdgeInsets.only(bottom: 16),
              itemCount: _books.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: theme.dividerColor),
              itemBuilder: (context, i) {
                final b = _books[i];
                return ListTile(
                  onTap: () {
                    Navigator.of(context).pushNamed(
                      BookDetailScreen.route,
                      arguments: {'bookId': b.id},
                    );
                  },
                  onLongPress: () async {
                    final s = await UserLists.shelfFor(b.id);
                    final chosen = await showModalBottomSheet<_QA>(
                      context: context,
                      showDragHandle: true,
                      builder: (ctx) => _QuickAddSheet(current: s),
                    );
                    if (chosen == null) return;
                    switch (chosen) {
                      case _QA.toTbr:  await UserLists.addTo(Shelf.tbr, b.id); break;
                      case _QA.toRead: await UserLists.addTo(Shelf.read, b.id); break;
                      case _QA.toDnf:  await UserLists.addTo(Shelf.dnf, b.id); break;
                      case _QA.remove: await UserLists.removeEverywhere(b.id); break;
                    }
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Updated shelf')),
                      );
                    }
                  },
                  leading: ClipRRect(borderRadius: BorderRadius.circular(6), child: _coverThumb(b)),
                  title: Text(b.title),
                  subtitle: Text(
                    '${b.author}${b.tropes.isNotEmpty ? ' • ${b.tropes.join(', ')}' : ''}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.chevron_right),
                );
              },
            ),
    );
  }
}

enum _QA { toTbr, toRead, toDnf, remove }

class _QuickAddSheet extends StatelessWidget {
  final Shelf? current;
  const _QuickAddSheet({required this.current});

  @override
  Widget build(BuildContext context) {
    Widget tile(IconData icon, String label, _QA action, {bool selected = false}) {
      return ListTile(
        leading: Icon(icon, color: selected ? Theme.of(context).colorScheme.primary : null),
        title: Row(children: [
          Text(label),
          if (selected) ...[const SizedBox(width: 8), const Icon(Icons.check_circle, size: 18)],
        ]),
        onTap: () => Navigator.pop(context, action),
      );
    }

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          tile(Icons.bookmark_add_outlined, 'Add to TBR', _QA.toTbr, selected: current == Shelf.tbr),
          tile(Icons.check_circle_outline, 'Mark as Read', _QA.toRead, selected: current == Shelf.read),
          tile(Icons.not_interested_outlined, 'Mark as DNF', _QA.toDnf, selected: current == Shelf.dnf),
          const Divider(height: 0),
          tile(Icons.remove_circle_outline, 'Remove from shelves', _QA.remove, selected: current == null),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
