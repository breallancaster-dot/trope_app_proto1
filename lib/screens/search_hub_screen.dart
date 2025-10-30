// lib/screens/search_hub_screen.dart
import 'package:flutter/material.dart';
import '../features/search/trope_search_screen.dart';

class SearchHubScreen extends StatelessWidget {
  const SearchHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctl = TextEditingController();
    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: ctl,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search by title or author',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (q) {
                // TODO: regular search results screen
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Search "$q" (coming soon)')),
                );
              },
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).pushNamed(TropeSearchScreen.route),
              icon: const Icon(Icons.favorite),
              label: const Text('Search by Tropes'),
            ),
          ],
        ),
      ),
    );
  }
}
