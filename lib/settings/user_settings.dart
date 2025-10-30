// lib/settings/user_settings.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/user_lists.dart'; // for Shelf enum

/// Centralized, simple settings model + notifier.
class UserSettings {
  UserSettings._();
  static final UserSettings instance = UserSettings._();

  // --- Keys
  static const _kTitles = 'prefs_shelf_titles';        // json: {tbr:"", read:"", dnf:""}
  static const _kOrder  = 'prefs_shelf_order';         // json: ["tbr","read","dnf"]
  static const _kWood   = 'prefs_wood_asset';          // string asset path
  static const _kScale  = 'prefs_cover_scale';         // double (0.8 .. 1.3)
  static const _kCols   = 'prefs_grid_cols_phone';     // int (min 3, max 6)

  /// Emits when any setting changes so interested screens can refresh.
  final ValueNotifier<int> changes = ValueNotifier<int>(0);

  // --- Defaults
  final Map<Shelf, String> _defaultTitles = const {
    Shelf.tbr:  'To Be Read',
    Shelf.read: 'Read',
    Shelf.dnf:  'Did Not Finish',
  };

  final List<Shelf> _defaultOrder = const [Shelf.tbr, Shelf.read, Shelf.dnf];

  final String _defaultWood =
      'assets/covers/../wood/brown-oak-wood-textured-design-background.jpg'; // safe path

  final double _defaultScale = 1.0; // 64x96 * scale in overview & shelf pages
  final int _defaultColsPhone = 3;

  // --- Live values (in-memory cache)
  Map<Shelf, String> titles = {};
  List<Shelf> order = [];
  String woodAsset = '';
  double coverScale = 1.0;
  int gridColsPhone = 3;

  bool _loaded = false;
  bool get isLoaded => _loaded;

  Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();

    // titles
    final titlesJson = prefs.getString(_kTitles);
    if (titlesJson != null) {
      final m = jsonDecode(titlesJson) as Map<String, dynamic>;
      titles = {
        Shelf.tbr:  (m['tbr']  as String?) ?? _defaultTitles[Shelf.tbr]!,
        Shelf.read: (m['read'] as String?) ?? _defaultTitles[Shelf.read]!,
        Shelf.dnf:  (m['dnf']  as String?) ?? _defaultTitles[Shelf.dnf]!,
      };
    } else {
      titles = Map<Shelf, String>.from(_defaultTitles);
    }

    // order
    final orderJson = prefs.getString(_kOrder);
    if (orderJson != null) {
      final list = (jsonDecode(orderJson) as List).map((e) => e.toString()).toList();
      order = _fromKeys(list);
    } else {
      order = List<Shelf>.from(_defaultOrder);
    }

    woodAsset = prefs.getString(_kWood) ?? _defaultWood;
    coverScale = prefs.getDouble(_kScale) ?? _defaultScale;
    gridColsPhone = prefs.getInt(_kCols) ?? _defaultColsPhone;

    _loaded = true;
  }

  Future<void> _saveTitles() async {
    final prefs = await SharedPreferences.getInstance();
    final m = {
      'tbr':  titles[Shelf.tbr],
      'read': titles[Shelf.read],
      'dnf':  titles[Shelf.dnf],
    };
    await prefs.setString(_kTitles, jsonEncode(m));
    changes.value++;
  }

  Future<void> _saveOrder() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kOrder, jsonEncode(order.map(_key).toList()));
    changes.value++;
  }

  Future<void> setWoodAsset(String asset) async {
    final prefs = await SharedPreferences.getInstance();
    woodAsset = asset;
    await prefs.setString(_kWood, asset);
    changes.value++;
  }

  Future<void> setCoverScale(double v) async {
    final prefs = await SharedPreferences.getInstance();
    coverScale = v.clamp(0.8, 1.3);
    await prefs.setDouble(_kScale, coverScale);
    changes.value++;
  }

  Future<void> setGridColsPhone(int v) async {
    final prefs = await SharedPreferences.getInstance();
    gridColsPhone = v.clamp(3, 6);
    await prefs.setInt(_kCols, gridColsPhone);
    changes.value++;
  }

  Future<void> setTitle(Shelf shelf, String title) async {
    titles[shelf] = title.trim().isEmpty ? _defaultTitles[shelf]! : title.trim();
    await _saveTitles();
  }

  Future<void> setOrder(List<Shelf> newOrder) async {
    order = List<Shelf>.from(newOrder);
    await _saveOrder();
  }

  // helpers
  String _key(Shelf s) => switch (s) { Shelf.tbr => 'tbr', Shelf.read => 'read', Shelf.dnf => 'dnf' };
  List<Shelf> _fromKeys(List<String> keys) {
    Shelf? parse(String k) => switch (k) {
      'tbr' => Shelf.tbr, 'read' => Shelf.read, 'dnf' => Shelf.dnf, _ => null
    };
    final out = <Shelf>[];
    for (final k in keys) {
      final s = parse(k);
      if (s != null && !out.contains(s)) out.add(s);
    }
    // ensure all present
    for (final s in _defaultOrder) {
      if (!out.contains(s)) out.add(s);
    }
    return out;
  }
}
