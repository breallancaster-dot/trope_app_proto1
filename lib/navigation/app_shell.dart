// lib/navigation/app_shell.dart
import 'package:flutter/material.dart';

import '../screens/home_screen.dart';
import '../screens/library_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/book_detail_screen.dart';
import '../screens/label_results_screen.dart';

import '../features/search/trope_picker_screen.dart';
import '../features/search/trope_results_screen.dart';

/// Root shell with bottom nav + a nested Navigator per tab.
///
/// Tabs:
/// 0 = Home
/// 1 = Tropes
/// 2 = Library
/// 3 = Profile
class AppShell extends StatefulWidget {
  static const route = '/home';

  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();

  static void setTab(int i) {
    // Hook this up later if you want to programmatically switch tabs.
  }
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  /// One navigator per tab so each has its own stack.
  final List<GlobalKey<NavigatorState>> _navKeys = <GlobalKey<NavigatorState>>[
    GlobalKey<NavigatorState>(), // Home
    GlobalKey<NavigatorState>(), // Tropes
    GlobalKey<NavigatorState>(), // Library
    GlobalKey<NavigatorState>(), // Profile
  ];

  void _setIndex(int i) {
    // Re-tap on the *same* tab.
    if (_index == i) {
      // Special behaviour for Tropes: always reset to a blank picker.
      if (i == 1) {
        final nav = _navKeys[1].currentState;
        if (nav != null) {
          nav.pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) => const TropePickerScreen(prefill: []),
            ),
            (route) => false,
          );
        }
        return;
      }

      // Other tabs: just pop to root of that tab.
      final nav = _navKeys[i].currentState;
      nav?.popUntil((route) => route.isFirst);
      return;
    }

    // Switching between different tabs.
    setState(() {
      _index = i;
    });
  }

  Route<dynamic> _onGenerateRoute(
    RouteSettings settings,
    WidgetBuilder rootBuilder,
  ) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(
          builder: rootBuilder,
          settings: settings,
        );

      // Book detail: accept either 'bookId' or legacy 'id'.
      case BookDetailScreen.route: {
        final args = settings.arguments;
        String? id;
        if (args is Map) {
          if (args['bookId'] is String) {
            id = args['bookId'] as String;
          } else if (args['id'] is String) {
            id = args['id'] as String;
          }
        }
        return MaterialPageRoute(
          builder: (_) => BookDetailScreen(bookId: id ?? ''),
          settings: settings,
        );
      }

      // Trope results: expects { 'selected': List<String> }.
      case TropeResultsScreen.route: {
        final args = settings.arguments;
        final selected = (args is Map && args['selected'] is List)
            ? (args['selected'] as List).map((e) => e.toString()).toList()
            : const <String>[];
        return MaterialPageRoute(
          builder: (_) => TropeResultsScreen(selected: selected),
          settings: settings,
        );
      }

      // Label results: { 'label': String, 'kind': 'trope' | 'subgenre' }.
      case LabelResultsScreen.route: {
        final args = settings.arguments;
        final label = (args is Map && args['label'] is String)
            ? args['label'] as String
            : '';
        final kindStr = (args is Map && args['kind'] is String)
            ? args['kind'] as String
            : 'trope';
        final kind = kindStr.toLowerCase() == 'subgenre'
            ? LabelKind.subgenre
            : LabelKind.trope;
        return MaterialPageRoute(
          builder: (_) => LabelResultsScreen(label: label, kind: kind),
          settings: settings,
        );
      }

      default:
        return MaterialPageRoute(
          builder: rootBuilder,
          settings: settings,
        );
    }
  }

  Widget _buildTabStack(int i, WidgetBuilder rootBuilder) {
    return Navigator(
      key: _navKeys[i],
      onGenerateRoute: (settings) => _onGenerateRoute(settings, rootBuilder),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: null,
      body: IndexedStack(
        index: _index,
        children: [
          _buildTabStack(0, (_) => const HomeScreen()),
          _buildTabStack(1, (_) => const TropePickerScreen(prefill: [])),
          _buildTabStack(2, (_) => const LibraryScreen()),
          _buildTabStack(3, (_) => const ProfileScreen()),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _setIndex,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_outline),
            label: 'Tropes',
          ),
          NavigationDestination(
            icon: Icon(Icons.library_books_outlined),
            label: 'Library',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
