// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import '../navigation/app_shell.dart';

class HomeScreen extends StatelessWidget {
  static const route = '/home';
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Welcome back 👋', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const Icon(Icons.favorite),
            title: const Text('Jump into trope search'),
            subtitle: const Text('Find books by your favorite tropes'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => AppShell.setTab(1), // ← switch to Tropes tab
          ),
        ),
        const SizedBox(height: 12),
        const Card(
          child: ListTile(
            leading: Icon(Icons.local_fire_department_outlined),
            title: Text('Trending this week'),
            subtitle: Text('Coming soon'),
          ),
        ),
      ],
    );
  }
}
