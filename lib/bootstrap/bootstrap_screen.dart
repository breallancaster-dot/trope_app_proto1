// lib/bootstrap/bootstrap_screen.dart
import 'package:flutter/material.dart';
import '../navigation/app_shell.dart';
import '../data/book_repository.dart';

class BootstrapScreen extends StatefulWidget {
  const BootstrapScreen({super.key});

  @override
  State<BootstrapScreen> createState() => _BootstrapScreenState();
}

class _BootstrapScreenState extends State<BootstrapScreen> {
  String _status = 'Preparing…';

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    try {
      setState(() => _status = 'Loading library…');
      // Non-blocking preload; BookRepository.ensureLoaded() should parse JSON using compute()
      await BookRepository.instance.ensureLoaded();

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AppShell()),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _status = 'Failed to load data. Pull to retry.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async => _start(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.3),
            const Center(child: CircularProgressIndicator()),
            const SizedBox(height: 16),
            Center(child: Text(_status, style: theme.textTheme.bodyMedium)),
          ],
        ),
      ),
    );
  }
}
