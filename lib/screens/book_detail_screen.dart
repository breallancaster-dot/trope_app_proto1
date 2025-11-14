// lib/screens/book_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/book.dart';
import '../data/book_repository.dart';
import '../data/user_lists.dart';
import '../widgets/book_cover.dart';
import '../widgets/rating_row.dart';
import 'label_results_screen.dart';

class BookDetailScreen extends StatefulWidget {
  static const route = '/book-detail';

  /// Convenience to push this page using a strongly typed route.
  static Route<Object?> materialRoute({required String bookId}) {
    return MaterialPageRoute(
      builder: (_) => BookDetailScreen(bookId: bookId),
      settings: const RouteSettings(name: route),
    );
  }

  final String bookId;

  const BookDetailScreen({
    super.key,
    required this.bookId,
  });

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  bool _loading = true;
  Book? _book;
  Shelf? _currentShelf;
  int _rating = 0; // 0..5
  int _spice = 0; // 0..3
  String _notes = '';
  bool _savingNotes = false;
  List<Book> _related = const [];

  static const _kRatingPrefix = 'book_rating_';
  static const _kSpicePrefix = 'book_spice_';
  static const _kNotesPrefix = 'book_notes_';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = BookRepository.instance;
    await repo.load();
    final book = repo.bookById(widget.bookId);

    if (book == null) {
      setState(() {
        _book = null;
        _loading = false;
      });
      return;
    }

    final shelf = await UserLists.shelfFor(book.id);
    final prefs = await SharedPreferences.getInstance();

    final rating = prefs.getInt('$_kRatingPrefix${book.id}') ?? 0;
    final spice = prefs.getInt('$_kSpicePrefix${book.id}') ?? 0;
    final notes = prefs.getString('$_kNotesPrefix${book.id}') ?? '';

    final related = _computeRelated(repo, book);

    setState(() {
      _book = book;
      _currentShelf = shelf;
      _rating = rating;
      _spice = spice;
      _notes = notes;
      _related = related;
      _loading = false;
    });
  }

  List<Book> _computeRelated(BookRepository repo, Book book) {
    // Dedupe upstream books by id first, in case the data source has duplicates.
    final Map<String, Book> byId = <String, Book>{};
    for (final b in repo.allBooks()) {
      byId[b.id] = b;
    }
    final all = byId.values.toList();
    if (all.isEmpty) return const [];

    final thisTropeSet = book.tropes.toSet();
    final thisSubSet = book.subgenres.toSet();

    final scored = <Book, int>{};

    for (final other in all) {
      if (other.id == book.id) continue;

      final tropesOverlap =
          thisTropeSet.intersection(other.tropes.toSet()).length;
      final subsOverlap =
          thisSubSet.intersection(other.subgenres.toSet()).length;

      final score = tropesOverlap * 2 + subsOverlap;
      if (score > 0) {
        scored[other] = score;
      }
    }

    final list = scored.entries.toList()
      ..sort((a, b) {
        final diff = b.value.compareTo(a.value);
        if (diff != 0) return diff;
        return a.key.title.toLowerCase().compareTo(b.key.title.toLowerCase());
      });

    // Don’t need a wall of recs; top 12 is fine.
    return list.map((e) => e.key).take(12).toList();
  }

  String? _formatDate(String? raw) {
    if (raw == null) return null;
    final v = raw.trim();
    if (v.isEmpty) return null;

    // Expecting YYYY-MM-DD → dd/MM/yyyy; fall back to original string.
    final fullDate = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    if (fullDate.hasMatch(v)) {
      final dt = DateTime.tryParse(v);
      if (dt != null) {
        final d = dt.day.toString().padLeft(2, '0');
        final m = dt.month.toString().padLeft(2, '0');
        final y = dt.year.toString();
        return '$d/$m/$y';
      }
    }
    return v;
  }

  Future<void> _setShelf(Shelf? shelf) async {
    final b = _book;
    if (b == null) return;

    if (shelf == null) {
      await UserLists.removeEverywhere(b.id);
    } else {
      await UserLists.addTo(shelf, b.id);
    }

    setState(() => _currentShelf = shelf);

    final msg = shelf == null
        ? 'Removed from shelves'
        : 'Moved to ${_shelfLabel(shelf)}';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  String _shelfLabel(Shelf s) {
    switch (s) {
      case Shelf.tbr:
        return 'TBR';
      case Shelf.read:
        return 'Read';
      case Shelf.dnf:
        return 'DNF';
    }
  }

  Future<void> _openShelfPicker() async {
    final theme = Theme.of(context);

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        Widget tile(String label, IconData icon, Shelf shelf) {
          final selected = _currentShelf == shelf;
          return ListTile(
            leading: Icon(
              icon,
              color: selected ? theme.colorScheme.primary : null,
            ),
            title: Text(label),
            trailing:
                selected ? const Icon(Icons.check, color: Colors.green) : null,
            onTap: () {
              Navigator.of(ctx).pop();
              _setShelf(shelf);
            },
          );
        }

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              tile('TBR', Icons.bookmark_add_outlined, Shelf.tbr),
              tile('Read', Icons.check_circle_outline, Shelf.read),
              tile('DNF', Icons.not_interested_outlined, Shelf.dnf),
              const Divider(height: 0),
              ListTile(
                leading: const Icon(Icons.remove_circle_outline),
                title: const Text('Remove from shelves'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _setShelf(null);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _updateRating(int stars) async {
    final b = _book;
    if (b == null) return;
    setState(() => _rating = stars);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('$_kRatingPrefix${b.id}', stars);
  }

  Future<void> _updateSpice(int spice) async {
    final b = _book;
    if (b == null) return;
    setState(() => _spice = spice);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('$_kSpicePrefix${b.id}', spice);
  }

  Future<void> _saveNotes(String text) async {
    final b = _book;
    if (b == null) return;
    setState(() {
      _notes = text;
      _savingNotes = true;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_kNotesPrefix${b.id}', text);
    setState(() {
      _savingNotes = false;
    });
  }

  void _openLabelResults(String label, LabelKind kind) {
    Navigator.of(context).pushNamed(
      LabelResultsScreen.route,
      arguments: {
        'label': label,
        'kind': kind == LabelKind.trope ? 'trope' : 'subgenre',
      },
    );
  }

  void _openRelated(Book book) {
    Navigator.of(context).pushNamed(
      BookDetailScreen.route,
      arguments: {'bookId': book.id},
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Book')),
        body: Center(
          child: CircularProgressIndicator(
            color: theme.colorScheme.primary,
          ),
        ),
      );
    }

    if (_book == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Book not found')),
        body: const Center(
          child: Text('This book could not be found.'),
        ),
      );
    }

    final book = _book!;

    return Scaffold(
      appBar: AppBar(
        title: Text(book.title),
      ),
      body: _buildBody(context, book),
    );
  }

  Widget _buildBody(BuildContext context, Book book) {
    final theme = Theme.of(context);

    final metaParts = <String>[];
    if (book.pageCount != null) {
      metaParts.add('${book.pageCount} pages');
    }
    final formattedDate = _formatDate(book.publishedDate);
    if (formattedDate != null) {
      metaParts.add(formattedDate);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: cover + title/author/meta + shelf button
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              bookCoverWidget(
                book.coverUrl,
                w: 110,
                h: 165,
                borderRadius: const BorderRadius.all(Radius.circular(12)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      book.author,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(color: theme.textTheme.bodySmall?.color),
                    ),
                    const SizedBox(height: 8),
                    if (metaParts.isNotEmpty)
                      Text(
                        metaParts.join(' • '),
                        style: theme.textTheme.bodySmall,
                      ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _openShelfPicker,
                      icon: const Icon(Icons.bookmarks_outlined),
                      label: Text(
                        _currentShelf == null
                            ? 'Add to shelf'
                            : 'Shelf: ${_shelfLabel(_currentShelf!)}',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Rating row gets full width, separate from header.
          RatingRow(
            stars: _rating,
            spice: _spice,
            onStars: _updateRating,
            onSpice: _updateSpice,
          ),

          const SizedBox(height: 16),

          // Blurb first
          if ((book.blurb ?? '').trim().isNotEmpty) ...[
            Text(
              'Blurb',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            _ExpandableText(
              text: book.blurb!.trim(),
              trimLines: 6,
            ),
            const SizedBox(height: 16),
          ],

          // Tropes and subgenres
          if (book.tropes.isNotEmpty) ...[
            Text(
              'Tropes',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: book.tropes.map((t) {
                return ActionChip(
                  label: Text(t),
                  onPressed: () => _openLabelResults(t, LabelKind.trope),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
          if (book.subgenres.isNotEmpty) ...[
            Text(
              'Subgenres',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: book.subgenres.map((s) {
                return ActionChip(
                  label: Text(s),
                  onPressed: () =>
                      _openLabelResults(s, LabelKind.subgenre),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],

          // More like this (recs)
          if (_related.isNotEmpty) ...[
            Text(
              'More like this',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _related.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final b = _related[index];
                  return SizedBox(
                    width: 110,
                    child: InkWell(
                      onTap: () => _openRelated(b),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: bookCoverWidget(
                                b.coverUrl,
                                w: 110,
                                h: 165,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            b.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          if (b.author.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              b.author,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Notes at the bottom
          Text(
            'Your notes',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          _NotesField(
            initialText: _notes,
            onChanged: _saveNotes,
            saving: _savingNotes,
          ),
        ],
      ),
    );
  }
}

class _NotesField extends StatefulWidget {
  final String initialText;
  final Future<void> Function(String text) onChanged;
  final bool saving;

  const _NotesField({
    required this.initialText,
    required this.onChanged,
    required this.saving,
  });

  @override
  State<_NotesField> createState() => _NotesFieldState();
}

class _NotesFieldState extends State<_NotesField> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialText);
  }

  @override
  void didUpdateWidget(covariant _NotesField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialText != widget.initialText &&
        widget.initialText != _ctrl.text) {
      _ctrl.text = widget.initialText;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _ctrl,
          minLines: 3,
          maxLines: 5,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'What did you think? Favourite moments, warnings, etc…',
          ),
          onChanged: (value) {
            widget.onChanged(value);
          },
        ),
        const SizedBox(height: 4),
        if (widget.saving)
          Text(
            'Saving…',
            style: theme.textTheme.bodySmall,
          ),
      ],
    );
  }
}

class _ExpandableText extends StatefulWidget {
  final String text;
  final int trimLines;

  const _ExpandableText({
    required this.text,
    this.trimLines = 4,
  });

  @override
  State<_ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<_ExpandableText> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.text,
          maxLines: _expanded ? null : widget.trimLines,
          overflow:
              _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
          textAlign: TextAlign.start,
        ),
        const SizedBox(height: 4),
        TextButton(
          onPressed: () => setState(() => _expanded = !_expanded),
          child: Text(
            _expanded ? 'Show less' : 'Read more',
            style: TextStyle(color: theme.colorScheme.primary),
          ),
        ),
      ],
    );
  }
}
