// lib/screens/book_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/book.dart';
import '../data/book_repository.dart';
import '../data/user_lists.dart';
import '../widgets/book_cover.dart';
import 'label_results_screen.dart';

class BookDetailScreen extends StatefulWidget {
  static const route = '/book-detail';

  /// Convenience to push this page using a strongly typed route.
  static Route<Object?> materialRoute({required String bookId}) {
    return MaterialPageRoute(
      settings: const RouteSettings(name: route),
      builder: (_) => BookDetailScreen(bookId: bookId),
    );
  }

  final String bookId;
  const BookDetailScreen({super.key, required this.bookId});

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();

  static fromRouteArgs(BuildContext ctx) {}
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  bool _loading = true;
  Book? _book;
  Shelf? _currentShelf;

  int _starRating = 0;  // 0..5
  int _spiceRating = 0; // 0..3

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final repo = BookRepository.instance;
    await repo.load();

    final b = repo.bookById(widget.bookId);
    final shelf = await UserLists.shelfFor(widget.bookId);

    if (b != null) {
      final prefs = await SharedPreferences.getInstance();
      _starRating = prefs.getInt(_starsKey(b.id)) ?? 0;
      _spiceRating = prefs.getInt(_spiceKey(b.id)) ?? 0;
    }

    if (!mounted) return;
    setState(() {
      _book = b;
      _currentShelf = shelf;
      _loading = false;
    });
  }

  String _starsKey(String id) => 'rating_stars_$id';
  String _spiceKey(String id) => 'rating_spice_$id';

  Future<void> _saveRatings() async {
    final b = _book; if (b == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_starsKey(b.id), _starRating);
    await prefs.setInt(_spiceKey(b.id), _spiceRating);
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _setShelf(Shelf s) async {
    final b = _book; if (b == null) return;
    await UserLists.addTo(s, b.id);
    _currentShelf = await UserLists.shelfFor(b.id);
    if (mounted) setState(() {});
    switch (s) {
      case Shelf.tbr:  _toast('Added to TBR'); break;
      case Shelf.read: _toast('Marked as Read'); break;
      case Shelf.dnf:  _toast('Marked as DNF'); break;
    }
  }

  Future<void> _removeShelves() async {
    final b = _book; if (b == null) return;
    await UserLists.removeEverywhere(b.id);
    _currentShelf = null;
    if (mounted) setState(() {});
    _toast('Removed from all shelves');
  }

  (String label, Color bg) _statusVisual(ThemeData theme) {
    return switch (_currentShelf) {
      Shelf.tbr  => ('In TBR', theme.colorScheme.primary),
      Shelf.read => ('Read', Colors.green.shade700),
      Shelf.dnf  => ('DNF', Colors.red.shade700),
      _          => ('Want to Read', theme.colorScheme.primary),
    };
  }

  Future<void> _openShelfMenu(ThemeData theme) async {
    final selected = await showMenu<_MenuAction>(
      context: context,
      position: const RelativeRect.fromLTRB(24, 110, 24, 0),
      items: [
        PopupMenuItem(
          value: _MenuAction.toTbr,
          child: Row(
            children: [
              Icon(Icons.bookmark_add_outlined,
                  color: _currentShelf == Shelf.tbr ? theme.colorScheme.primary : null),
              const SizedBox(width: 12),
              const Text('Add to TBR'),
              if (_currentShelf == Shelf.tbr) ...[
                const SizedBox(width: 8),
                const Icon(Icons.check, size: 18),
              ],
            ],
          ),
        ),
        PopupMenuItem(
          value: _MenuAction.toRead,
          child: Row(
            children: [
              Icon(Icons.check_circle_outline,
                  color: _currentShelf == Shelf.read ? theme.colorScheme.primary : null),
              const SizedBox(width: 12),
              const Text('Mark as Read'),
              if (_currentShelf == Shelf.read) ...[
                const SizedBox(width: 8),
                const Icon(Icons.check, size: 18),
              ],
            ],
          ),
        ),
        PopupMenuItem(
          value: _MenuAction.toDnf,
          child: Row(
            children: [
              Icon(Icons.not_interested_outlined,
                  color: _currentShelf == Shelf.dnf ? theme.colorScheme.primary : null),
              const SizedBox(width: 12),
              const Text('Mark as DNF'),
              if (_currentShelf == Shelf.dnf) ...[
                const SizedBox(width: 8),
                const Icon(Icons.check, size: 18),
              ],
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: _MenuAction.removeAll,
          child: Row(
            children: [
              Icon(Icons.remove_circle_outline),
              SizedBox(width: 12),
              Text('Remove from shelves'),
            ],
          ),
        ),
      ],
    );

    switch (selected) {
      case _MenuAction.toTbr: await _setShelf(Shelf.tbr); break;
      case _MenuAction.toRead: await _setShelf(Shelf.read); break;
      case _MenuAction.toDnf: await _setShelf(Shelf.dnf); break;
      case _MenuAction.removeAll: await _removeShelves(); break;
      case null: break;
    }
  }

  Widget _statusButton(ThemeData theme) {
    final (label, bg) = _statusVisual(theme);
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: bg,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onPressed: () async {
              if (_currentShelf == null) {
                await _setShelf(Shelf.tbr);
              } else {
                await _openShelfMenu(theme);
              }
            },
            icon: const Icon(Icons.bookmark),
            label: Text(label),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 44,
          height: 44,
          child: OutlinedButton(
            onPressed: () => _openShelfMenu(theme),
            child: const Icon(Icons.arrow_drop_down),
          ),
        ),
      ],
    );
  }

  Widget _starRow() {
    return Row(
      children: List.generate(5, (i) {
        final idx = i + 1;
        final on = _starRating >= idx;
        return IconButton(
          visualDensity: VisualDensity.compact,
          icon: Icon(on ? Icons.star : Icons.star_border),
          color: on ? Colors.amber : null,
          onPressed: () { setState(() => _starRating = idx); _saveRatings(); },
        );
      }),
    );
  }

  Widget _spiceRow() {
    return Row(
      children: List.generate(3, (i) {
        final idx = i + 1;
        final on = _spiceRating >= idx;
        return IconButton(
          visualDensity: VisualDensity.compact,
          icon: Icon(on ? Icons.local_fire_department : Icons.local_fire_department_outlined),
          color: on ? Colors.redAccent : null,
          onPressed: () { setState(() => _spiceRating = idx); _saveRatings(); },
        );
      }),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black87),
                children: [
                  TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chipsLight(
    String title,
    List<String> items,
    Color bg,
    Color fg, {
    required LabelKind kind,
  }) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items.map((t) {
            return ActionChip(
              label: Text(t),
              backgroundColor: bg.withOpacity(0.5),
              labelStyle: TextStyle(color: fg),
              onPressed: () {
                Navigator.of(context).pushNamed(
                  LabelResultsScreen.route,
                  arguments: {'label': t, 'kind': kind.name},
                );
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_book == null) {
      return const Scaffold(body: Center(child: Text('Book not found')));
    }
    final b = _book!;

    return Scaffold(
      // No AppBar – we’re using full-bleed pink background in the app
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 48, 16, 24),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              bookCoverWidget(b.coverUrl, w: 120, h: 180),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(b.title, style: theme.textTheme.titleLarge, maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(b.author, style: theme.textTheme.titleMedium!.copyWith(color: theme.colorScheme.primary), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 12),
                    _infoRow(Icons.numbers, 'ISBN-13', b.isbn13 ?? ''),
                    _infoRow(Icons.menu_book_outlined, 'Pages', b.pageCount?.toString() ?? ''),
                    _infoRow(Icons.event, 'Published', b.publishedDate ?? ''),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _statusButton(theme),

          const SizedBox(height: 16),
          const Divider(),

          Text('Your Rating', style: theme.textTheme.titleMedium),
          _starRow(),
          const SizedBox(height: 8),
          Text('Spice Level', style: theme.textTheme.titleMedium),
          _spiceRow(),

          const SizedBox(height: 16),
          const Divider(),

          if ((b.blurb ?? '').trim().isNotEmpty) ...[
            Text('Blurb', style: theme.textTheme.titleMedium),
            const SizedBox(height: 6),
            _ExpandableText(b.blurb!.trim(), trimLines: 6),
            const SizedBox(height: 16),
          ],

          // Tappable chips -> LabelResultsScreen
          _chipsLight(
            'Tropes',
            b.tropes,
            theme.colorScheme.secondaryContainer,
            theme.colorScheme.onSecondaryContainer,
            kind: LabelKind.trope,
          ),
          const SizedBox(height: 12),
          _chipsLight(
            'Subgenres',
            b.subgenres,
            theme.colorScheme.tertiaryContainer,
            theme.colorScheme.onTertiaryContainer,
            kind: LabelKind.subgenre,
          ),
        ],
      ),
    );
  }
}

enum _MenuAction { toTbr, toRead, toDnf, removeAll }

class _ExpandableText extends StatefulWidget {
  final String text;
  final int trimLines;
  const _ExpandableText(this.text, {this.trimLines = 5});

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
          overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
          textAlign: TextAlign.start,
        ),
        const SizedBox(height: 4),
        TextButton(
          onPressed: () => setState(() => _expanded = !_expanded),
          child: Text(_expanded ? 'Show less' : 'Read more', style: TextStyle(color: theme.colorScheme.primary)),
        ),
      ],
    );
  }
}
