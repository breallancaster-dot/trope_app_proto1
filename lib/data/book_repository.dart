// lib/data/book_repository.dart
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

import 'book.dart';

class BookRepository {
  BookRepository._();
  static final BookRepository instance = BookRepository._();

  bool _loaded = false;

  // Master list
  final List<Book> _books = <Book>[];

  // Lookups
  final Map<String, Book> _byId = <String, Book>{};                 // id -> Book
  final Map<String, Set<String>> _tropeToBookIds = <String, Set<String>>{};
  final Set<String> _allTropeSet = <String>{};                       // cleaned-lc set

  // Additional lookups for forgiving resolution
  final Map<String, String> _isbnToId = <String, String>{};          // isbn13 -> id
  final Map<String, String> _titleAuthorToId = <String, String>{};   // "title|author"(lc) -> id

  bool get isLoaded => _loaded;

  /// Load once from assets/data/final_books.json.
  Future<void> load() async {
    if (_loaded) return;

    final raw = await rootBundle.loadString('assets/data/final_books.json');
    final List<dynamic> data = json.decode(raw) as List<dynamic>;

    for (final row in data) {
      final m = row as Map<String, dynamic>;
      final b = Book.fromMap(m);

      // Clean labels for indexing/display stability
      final cleanedTropes =
          b.tropes.map(_cleanLabel).where((t) => t.isNotEmpty).toList();
      final cleanedSubgenres =
          b.subgenres.map(_cleanLabel).where((s) => s.isNotEmpty).toList();

      // Shallow copy with cleaned lists
      final book = Book(
        id: b.id,
        title: b.title,
        author: b.author,
        isbn13: b.isbn13,
        blurb: b.blurb,
        pageCount: b.pageCount,
        publishedDate: b.publishedDate,
        tropes: cleanedTropes,
        subgenres: cleanedSubgenres,
        coverUrl: b.coverUrl,
      );

      _books.add(book);
      _byId[book.id] = book;

      // Secondary lookups
      if ((book.isbn13 ?? '').trim().isNotEmpty) {
        _isbnToId[book.isbn13!.trim()] = book.id;
      }
      _titleAuthorToId[_titleAuthorKey(book.title, book.author)] = book.id;

      // Index by trope (lowercased, cleaned)
      for (final t in book.tropes) {
        final key = t.toLowerCase();
        _allTropeSet.add(key);
        (_tropeToBookIds[key] ??= <String>{}).add(book.id);
      }
    }

    _loaded = true;
  }

  // ---------- Public API ----------

  List<Book> allBooks() => List.unmodifiable(_books);

  List<Book> booksByIds(Set<String> ids) {
    final out = <Book>[];
    for (final id in ids) {
      final b = _byId[id];
      if (b != null) out.add(b);
    }
    return out;
  }

  Book? bookById(String id) => _byId[id];

  /// Resolve a possibly “fuzzy” id into our canonical id.
  /// Accepts: exact id, ISBN-13, or "title|author" (any case/spacing).
  String? resolveId(String raw) {
    if (raw.trim().isEmpty) return null;

    // 1) Exact match
    if (_byId.containsKey(raw)) return raw;

    // 2) ISBN-13 match
    final isbn = raw.trim();
    final byIsbn = _isbnToId[isbn];
    if (byIsbn != null) return byIsbn;

    // 3) Title|Author (case/spacing insensitive)
    final key = _titleAuthorKeyFromRaw(raw);
    final byTitleAuthor = _titleAuthorToId[key];
    if (byTitleAuthor != null) return byTitleAuthor;

    // 4) Last-ditch: try to find by title+author substring-ish
    final lowered = raw.toLowerCase();
    for (final b in _books) {
      final probe = '${b.title.toLowerCase()}|${b.author.toLowerCase()}';
      if (probe == lowered) return b.id;
    }

    return null;
  }

  /// Distinct tropes in Title Case for UI.
  List<String> allTropes() {
    final out = _allTropeSet.map(_titleCase).toList();
    out.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return out;
  }

  /// Books that match *all* selected tropes (AND).
  Set<String> bookIdsForSelectedTropes(List<String> selected) {
    if (selected.isEmpty) {
      return _byId.keys.toSet();
    }
    Set<String>? running;
    for (final t in selected) {
      final key = _cleanLabel(t).toLowerCase();
      final ids = _tropeToBookIds[key] ?? const <String>{};
      running = running == null ? ids.toSet() : running.intersection(ids);
      if (running.isEmpty) break;
    }
    return running ?? <String>{};
  }

  /// Given current selection, which additional tropes still yield results?
  Set<String> viableNextTropes(List<String> selected) {
    final selectedLc = selected.map((e) => _cleanLabel(e).toLowerCase()).toSet();
    final currentIds = bookIdsForSelectedTropes(selected);
    if (currentIds.isEmpty) return <String>{};

    final viable = <String>{};
    for (final trope in _allTropeSet) {
      if (selectedLc.contains(trope)) continue;
      final idsForTrope = _tropeToBookIds[trope] ?? const <String>{};
      if (currentIds.intersection(idsForTrope).isNotEmpty) {
        viable.add(trope);
      }
    }
    return viable;
  }

  /// Simple title/author search (case-insensitive).
  List<Book> searchByText(String query, {Set<String>? withinIds}) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      return withinIds == null ? allBooks() : booksByIds(withinIds);
    }

    final src = withinIds == null ? _books : booksByIds(withinIds);
    return src
        .where((b) =>
            b.title.toLowerCase().contains(q) ||
            b.author.toLowerCase().contains(q))
        .toList();
  }

  /// Counts per (lowercased/cleaned) trope — supports "Popular" sorting.
  Map<String, int> tropeCounts() {
    return _tropeToBookIds.map((k, v) => MapEntry(k, v.length));
  }

  // ---------- Helpers ----------

  String _cleanLabel(String s) {
    var out = s.trim();

    // Raw triple-quoted strings to avoid escaping quotes
    final leading = RegExp(r'''^[\]\[\)\(\}\{"'•.,;:\-–—\s]+''');
    final trailing = RegExp(r'''[\]\[\)\(\}\{"'•.,;:\-–—\s]+$''');

    out = out.replaceFirst(leading, '');
    out = out.replaceFirst(trailing, '');
    out = out.replaceAll(RegExp(r'\s+'), ' ');
    return out;
  }

  String _titleCase(String s) {
    if (s.isEmpty) return s;
    return s
        .split(' ')
        .map((w) =>
            w.isEmpty ? w : w[0].toUpperCase() + (w.length > 1 ? w.substring(1) : ''))
        .join(' ');
  }

  String _titleAuthorKey(String title, String author) {
    String norm(String x) => x.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    return '${norm(title)}|${norm(author)}';
  }

  String _titleAuthorKeyFromRaw(String raw) {
    // Accept already "title|author" or do our best with a single string
    final parts = raw.split('|');
    if (parts.length == 2) {
      return _titleAuthorKey(parts[0], parts[1]);
    }
    // If not pipe-separated, try to split on last " - " or similar (best-effort).
    // But generally, callers should pass the right id or "title|author".
    return raw.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  // Kept for compatibility if something calls it.
  Future<void> ensureLoaded() async {}
}
