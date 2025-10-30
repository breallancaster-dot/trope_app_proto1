// lib/data/book.dart
import 'dart:convert';

class Book {
  final String id;            // stable key: isbn13 if present, else title|author (lowercase)
  final String title;
  final String author;
  final String? isbn13;
  final String? blurb;        // store blurb; expose it via a `description` getter for compatibility
  final int? pageCount;
  final String? publishedDate;
  final List<String> tropes;
  final List<String> subgenres;
  final String? coverUrl;     // asset path ("assets/..."), file path, or http(s) URL

  Book({
    required this.id,
    required this.title,
    required this.author,
    this.isbn13,
    this.blurb,
    this.pageCount,
    this.publishedDate,
    required this.tropes,
    required this.subgenres,
    this.coverUrl,
  });

  /// Back-compat for code that expects a `description` field.
  String? get description => blurb;

  // --- helpers ---------------------------------------------------------------

  static String _s(dynamic v) => v == null ? '' : v.toString();

  static int? _i(dynamic v) {
    final s = _s(v).trim();
    return s.isEmpty ? null : int.tryParse(s);
    }

  static List<String> _csv(dynamic v) {
    final s = _s(v).trim();
    if (s.isEmpty || s.toLowerCase() == 'none') return const [];
    return s
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  factory Book.fromMap(Map<String, dynamic> m) {
    // Title: prefer 'title', fallback to 'original_title'
    final titleRaw = _s(m['title']).trim();
    final title = titleRaw.isNotEmpty ? titleRaw : _s(m['original_title']).trim();

    final author = _s(m['author']).trim();

    // ID: prefer isbn13, else title|author
    final isbn = _s(m['isbn13']).trim();
    final id = isbn.isNotEmpty ? isbn : '${title.toLowerCase()}|${author.toLowerCase()}';

    // Blurb: accept either 'blurb' or 'description'
    final blurbRaw = _s(m['blurb']).trim().isNotEmpty
        ? _s(m['blurb']).trim()
        : _s(m['description']).trim();
    final blurb = blurbRaw.isEmpty ? null : blurbRaw;

    // Cover: accept either 'cover_url' or 'cover'
    final coverUrlField = _s(m['cover_url']).trim();
    final coverField = _s(m['cover']).trim();
    final coverUrl = coverUrlField.isNotEmpty
        ? coverUrlField
        : (coverField.isNotEmpty ? coverField : null);

    return Book(
      id: id,
      title: title,
      author: author,
      isbn13: isbn.isEmpty ? null : isbn,
      blurb: blurb,
      pageCount: _i(m['pagecount']),
      publishedDate: _s(m['publisheddate']).trim().isEmpty
          ? null
          : _s(m['publisheddate']).trim(),
      tropes: _csv(m['tropes']),
      subgenres: _csv(m['subgenres']),
      coverUrl: coverUrl,
    );
  }

  static List<Book> listFromJsonString(String jsonStr) {
    final data = json.decode(jsonStr);
    if (data is List) {
      return data.map((e) => Book.fromMap(e as Map<String, dynamic>)).toList();
    }
    return const [];
  }
}
