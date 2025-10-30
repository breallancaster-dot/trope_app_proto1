// lib/navigation/app_shell.dart
import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../features/search/trope_search_screen.dart';
import '../screens/library_screen.dart';
import '../screens/profile_screen.dart';

class AppShell extends StatefulWidget {
  static const route = '/home';

  const AppShell({super.key});

  // allow other screens to switch tabs
  static void setTab(int index) => _AppShellState._setTabExternally(index);

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  static _AppShellState? _instance;
  int _index = 0;

  _AppShellState() {
    _instance = this;
  }

  static void _setTabExternally(int i) {
    _instance?._setTab(i);
  }

  void _setTab(int i) {
    if (!mounted) return;
    setState(() => _index = i);
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const HomeScreen(),
      const TropeSearchScreen(),
      const LibraryScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Trope App')),
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
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
