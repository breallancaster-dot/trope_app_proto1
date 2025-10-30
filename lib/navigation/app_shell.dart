// lib/navigation/app_shell.dart
import 'package:flutter/material.dart';

import '../screens/home_screen.dart';
import '../screens/library_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/book_detail_screen.dart';
import '../screens/label_results_screen.dart';

import '../features/search/trope_picker_screen.dart';
import '../features/search/trope_results_screen.dart';

// A single AppShell with a nested Navigator per tab so each tab keeps its own history.
class AppShell extends StatefulWidget {
  static const route = '/home';
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();

  static void setTab(int i) {}
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  // One navigator per tab
  final _navKeys = <GlobalKey<NavigatorState>>[
    GlobalKey<NavigatorState>(), // Home
    GlobalKey<NavigatorState>(), // Tropes
    GlobalKey<NavigatorState>(), // Library
    GlobalKey<NavigatorState>(), // Profile
  ];

  void _setIndex(int i) {
    if (_index == i) {
      // If the user re-taps an already-selected tab, pop that tab stack to root.
      _navKeys[i].currentState?.popUntil((r) => r.isFirst);
    }
    setState(() => _index = i);
  }

  // Common onGenerateRoute used by each tab's nested Navigator.
  Route<dynamic> _onGenerateRoute(RouteSettings settings, WidgetBuilder rootBuilder) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: rootBuilder, settings: settings);

      // Book detail requires a bookId argument.
      case BookDetailScreen.route: {
        final args = settings.arguments;
        final bookId = (args is Map && args['id'] is String) ? args['id'] as String : null;
        return MaterialPageRoute(
          builder: (_) => BookDetailScreen(bookId: bookId ?? ''),
          settings: settings,
        );
      }

      // Trope results takes a list of selected tropes.
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

      // Label results (from tapping a trope/subgenre chip on Book Detail)
      case LabelResultsScreen.route: {
        final args = settings.arguments;
        final label = (args is Map && args['label'] is String) ? args['label'] as String : '';
        final kindStr = (args is Map && args['kind'] is String) ? args['kind'] as String : 'trope';
        final kind = kindStr == 'subgenre' ? LabelKind.subgenre : LabelKind.trope;
        return MaterialPageRoute(
          builder: (_) => LabelResultsScreen(label: label, kind: kind),
          settings: settings,
        );
      }

      default:
        return MaterialPageRoute(builder: rootBuilder, settings: settings);
    }
  }

  // Build a tab stack with its own Navigator and routes.
  Widget _buildTabStack(int i, WidgetBuilder rootBuilder) {
    return Navigator(
      key: _navKeys[i],
      onGenerateRoute: (settings) => _onGenerateRoute(settings, rootBuilder),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // We’ve moved page titles into each screen; keep the app bar minimal or remove it entirely.
      appBar: null,
      body: IndexedStack(
        index: _index,
        children: [
          _buildTabStack(0, (_) => const HomeScreen()),
          _buildTabStack(1, (_) => const TropePickerScreen(prefill: [],)),
          _buildTabStack(2, (_) => const LibraryScreen()),
          _buildTabStack(3, (_) => const ProfileScreen()),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _setIndex,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.favorite_outline), label: 'Tropes'),
          NavigationDestination(icon: Icon(Icons.library_books_outlined), label: 'Library'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}
