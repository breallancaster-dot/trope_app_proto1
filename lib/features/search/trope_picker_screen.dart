// lib/features/search/trope_picker_screen.dart
import 'package:flutter/material.dart';
import '../../data/book_repository.dart';
import 'trope_results_screen.dart';

class TropePickerScreen extends StatefulWidget {
  static const route = '/trope-picker';
  const TropePickerScreen({super.key, required List prefill});

  @override
  State<TropePickerScreen> createState() => _TropePickerScreenState();
}

class _TropePickerScreenState extends State<TropePickerScreen> {
  bool _loading = true;
  String? _fatalError;

  // All available tropes (Title Case for display)
  List<String> _allTropes = const [];

  // Current selection (Title Case)
  final List<String> _selected = <String>[];

  // Which tropes remain viable given current selection (lowercased keys)
  Set<String> _viableNext = <String>{};

  // Local search within the trope list
  String _filter = '';

  bool _didBootstrap = false;
  bool get _ready => !_loading && _fatalError == null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didBootstrap) return;
    _didBootstrap = true;
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      final repo = BookRepository.instance;
      await repo.load();

      // Base data
      final all = repo.allTropes();

      // Optional prefill from route args: {'prefill': <String>[]}
      final args = ModalRoute.of(context)?.settings.arguments;
      final prefill = (args is Map && args['prefill'] is List)
          ? (args['prefill'] as List).map((e) => e.toString()).toList()
          : <String>[];

      if (!mounted) return;
      setState(() {
        _allTropes = all;
        _selected
          ..clear()
          ..addAll(prefill.where((t) => all.contains(t)));
        _viableNext = repo.viableNextTropes(_selected);
        _loading = false;
        _fatalError = null;
      });
    } catch (e, st) {
      debugPrint('TropePicker bootstrap error: $e\n$st');
      if (!mounted) return;
      setState(() {
        _fatalError = 'Failed to load tropes.';
        _loading = false;
      });
    }
  }

  void _toggle(String trope) {
    if (!_ready) return;
    final repo = BookRepository.instance;
    setState(() {
      if (_selected.contains(trope)) {
        _selected.remove(trope);
      } else {
        if (_selected.length >= 5) return; // cap at 5
        _selected.add(trope);
      }
      _viableNext = repo.viableNextTropes(_selected);
    });
  }

  void _clearAll() {
    if (!_ready) return;
    setState(() {
      _selected.clear();
      _filter = '';
      _viableNext = BookRepository.instance.viableNextTropes(_selected);
    });
  }

  /// Only show chips that are either selected or viable given selection.
  /// Also apply the local search filter.
  List<String> _visibleTropes() {
    if (!_ready) return const <String>[];
    final f = _filter.trim().toLowerCase();
    if (_selected.isEmpty) {
      return _allTropes
          .where((t) => f.isEmpty || t.toLowerCase().contains(f))
          .toList();
    }
    return _allTropes.where((t) {
      final show =
          _selected.contains(t) || _viableNext.contains(t.toLowerCase());
      if (!show) return false;
      if (f.isEmpty) return true;
      return t.toLowerCase().contains(f);
    }).toList();
  }

  Widget _chip(String trope) {
    final selected = _selected.contains(trope);
    // Disabled means it’s neither selected nor viable (when there is a selection)
    final disabled = !selected &&
        _selected.isNotEmpty &&
        !_viableNext.contains(trope.toLowerCase());

    return FilterChip(
      label: Text(
        trope,
        style: TextStyle(
          color: disabled
              ? Colors.grey.shade600
              : (selected ? Colors.white : null),
        ),
      ),
      selected: selected,
      onSelected: disabled ? null : (_) => _toggle(trope),
      backgroundColor: disabled ? Colors.grey.shade200 : null,
      selectedColor: Theme.of(context).colorScheme.primary,
      checkmarkColor: selected ? Colors.white : null,
      shape: StadiumBorder(
        side: BorderSide(
          color: disabled
              ? Colors.grey.shade300
              : Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
    );
  }

  void _apply() {
    if (_selected.isEmpty) return;
    final picked = List<String>.from(_selected);
    Navigator.of(context).pushReplacementNamed(
      TropeResultsScreen.route,
      arguments: {'selected': picked},
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Loading
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Pick Tropes')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Soft error state (no red screen)
    if (_fatalError != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Pick Tropes')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 42),
              const SizedBox(height: 8),
              Text(_fatalError!, style: theme.textTheme.titleMedium),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  setState(() {
                    _loading = true;
                    _fatalError = null;
                  });
                  _bootstrap();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final visible = _visibleTropes();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick Tropes'),
        actions: [
          if (_selected.isNotEmpty || _filter.isNotEmpty)
            TextButton.icon(
              onPressed: _clearAll,
              icon: const Icon(Icons.clear_all),
              label: const Text('Clear'),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search field for tropes
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
              child: TextField(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Search tropes…',
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => setState(() => _filter = v),
              ),
            ),

            // Selected count/helper
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                _selected.isEmpty
                    ? 'Select up to 5 tropes'
                    : 'Selected (${_selected.length}/5)',
                style: theme.textTheme.bodyMedium!
                    .copyWith(fontWeight: FontWeight.w600),
              ),
            ),

            // Bubble grid
            Expanded(
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: visible.map(_chip).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: FilledButton.icon(
          onPressed: _selected.isEmpty ? null : _apply,
          icon: const Icon(Icons.check),
          label: const Text('Apply'),
        ),
      ),
    );
  }
}
