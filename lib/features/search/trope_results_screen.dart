// lib/features/search/trope_results_screen.dart
import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';

import '../../data/book.dart';
import '../../data/book_repository.dart';
import '../../data/user_lists.dart';
import '../../widgets/book_results_list.dart';
import '../../navigation/nav.dart';
import 'trope_picker_screen.dart';

class TropeResultsScreen extends StatefulWidget {
  static const route = '/trope-results';

  final List<String> selected;

  const TropeResultsScreen({
    super.key,
    required this.selected,
  });

  @override
  State<TropeResultsScreen> createState() => _TropeResultsScreenState();
}

class _TropeResultsScreenState extends State<TropeResultsScreen> {
  bool _loading = true;
  List<String> _selected = const [];
  List<Book> _books = const [];

  @override
  void initState() {
    super.initState();
    _selected = List<String>.from(widget.selected);
    _load();
  }

  @override
  void didUpdateWidget(covariant TropeResultsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.selected, widget.selected)) {
      _selected = List<String>.from(widget.selected);
      _load();
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    final repo = BookRepository.instance;
    await repo.load();

    final ids = repo.bookIdsForSelectedTropes(_selected);
    var books = repo.booksByIds(ids);
    books.sort(
      (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
    );

    setState(() {
      _books = books;
      _loading = false;
    });
  }

  Future<void> _openAddTropes() async {
    await Navigator.of(context).pushNamed(
      TropePickerScreen.route,
      arguments: {'prefill': List<String>.from(_selected)},
    );
    await _load();
  }

  Future<void> _clearSelection() async {
    await Navigator.of(context).pushNamed(
      TropePickerScreen.route,
      arguments: {'prefill': const <String>[]},
    );
    await _load();
  }

  Future<void> _handleLongPress(BuildContext context, Book book) async {
    final current = await UserLists.shelfFor(book.id);
    final chosen = await showModalBottomSheet<_QA>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => _QuickAddSheet(current: current),
    );
    if (chosen == null) return;

    switch (chosen) {
      case _QA.toTbr:
        await UserLists.addTo(Shelf.tbr, book.id);
        break;
      case _QA.toRead:
        await UserLists.addTo(Shelf.read, book.id);
        break;
      case _QA.toDnf:
        await UserLists.addTo(Shelf.dnf, book.id);
        break;
      case _QA.remove:
        await UserLists.removeEverywhere(book.id);
        break;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Updated shelf')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final heading =
        _selected.isEmpty ? 'Results' : _selected.join(' • ');

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(heading)),
        body: Center(
          child: CircularProgressIndicator(
            color: theme.colorScheme.primary,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(heading),
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
          : BookResultsList(
              books: _books,
              onTap: (ctx, book) => Nav.toBook(ctx, book.id),
              onLongPress: _handleLongPress,
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
    Widget tile(IconData icon, String label, _QA action,
        {bool selected = false}) {
      return ListTile(
        leading: Icon(icon),
        title: Text(label),
        trailing: selected
            ? const Icon(Icons.check, color: Colors.green)
            : null,
        onTap: () => Navigator.of(context).pop<_QA>(action),
      );
    }

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          tile(Icons.bookmark_add_outlined, 'Add to TBR', _QA.toTbr,
              selected: current == Shelf.tbr),
          tile(Icons.check_circle_outline, 'Mark as Read', _QA.toRead,
              selected: current == Shelf.read),
          tile(Icons.not_interested_outlined, 'Mark as DNF', _QA.toDnf,
              selected: current == Shelf.dnf),
          const Divider(height: 0),
          tile(Icons.remove_circle_outline, 'Remove from shelves',
              _QA.remove,
              selected: current == null),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
