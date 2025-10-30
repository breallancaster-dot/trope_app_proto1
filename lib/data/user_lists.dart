// lib/data/user_lists.dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum Shelf { read, tbr, dnf }

class UserLists {
  // Legacy keys (were used as unordered sets)
  static const _kRead = 'shelf_read';
  static const _kTbr  = 'shelf_tbr';
  static const _kDnf  = 'shelf_dnf';

  // New ordered list keys (front = most recently added)
  static const _kReadList = 'shelf_read_list';
  static const _kTbrList  = 'shelf_tbr_list';
  static const _kDnfList  = 'shelf_dnf_list';

  /// Emits a tick every time shelves change (UI can listen/reload).
  static final ValueNotifier<int> changes = ValueNotifier<int>(0);

  static String _legacyKey(Shelf s) => switch (s) {
        Shelf.read => _kRead,
        Shelf.tbr  => _kTbr,
        Shelf.dnf  => _kDnf,
      };

  static String _listKey(Shelf s) => switch (s) {
        Shelf.read => _kReadList,
        Shelf.tbr  => _kTbrList,
        Shelf.dnf  => _kDnfList,
      };

  // ---- Internal helpers -----------------------------------------------------

  static Future<List<String>> _getList(Shelf s) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_listKey(s));
    if (list != null) return List<String>.from(list);

    // Migrate from legacy set (if present)
    final legacy = prefs.getStringList(_legacyKey(s)) ?? const <String>[];
    // Keep current order as-is (it was arbitrary before). Save under list key.
    await prefs.setStringList(_listKey(s), legacy);
    return List<String>.from(legacy);
  }

  static Future<void> _putList(Shelf s, List<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_listKey(s), ids);

    // Maintain legacy Set mirror for any old code still calling `all()`
    await prefs.setStringList(_legacyKey(s), ids.toSet().toList());
  }

  static Future<void> _removeFromAllLists(String bookId) async {
    for (final s in Shelf.values) {
      final list = await _getList(s);
      list.removeWhere((e) => e == bookId);
      await _putList(s, list);
    }
  }

  // ---- Public API (ordered list first, set for compatibility) ---------------

  /// Add a book to a shelf (and remove from the others).
  /// Inserts at the *front* of the ordered list (Recently Added).
  static Future<void> addTo(Shelf s, String bookId) async {
    // Remove everywhere first
    await _removeFromAllLists(bookId);

    // Insert at front of target shelf
    final target = await _getList(s);
    target.removeWhere((e) => e == bookId);
    target.insert(0, bookId);
    await _putList(s, target);

    changes.value++; // notify
  }

  /// Remove a book id from all shelves
  static Future<void> removeEverywhere(String bookId) async {
    await _removeFromAllLists(bookId);
    changes.value++; // notify
  }

  /// Ordered list for a shelf (front = most recent).
  static Future<List<String>> allOrdered(Shelf s) => _getList(s);

  /// Back-compat: the old API returned an unordered Set<String>.
  static Future<Set<String>> all(Shelf s) async {
    final list = await _getList(s);
    return list.toSet();
  }

  /// Which shelf (if any) a book is currently in
  static Future<Shelf?> shelfFor(String bookId) async {
    for (final s in Shelf.values) {
      final list = await _getList(s);
      if (list.contains(bookId)) return s;
    }
    return null;
  }
}
