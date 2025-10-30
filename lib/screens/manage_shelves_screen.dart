// lib/screens/manage_shelves_screen.dart
import 'package:flutter/material.dart';
import '../data/user_lists.dart';
import '../settings/user_settings.dart';

class ManageShelvesScreen extends StatefulWidget {
  static const route = '/manage-shelves';
  const ManageShelvesScreen({super.key});

  @override
  State<ManageShelvesScreen> createState() => _ManageShelvesScreenState();
}

class _ManageShelvesScreenState extends State<ManageShelvesScreen> {
  final us = UserSettings.instance;

  late List<Shelf> _order;
  late Map<Shelf, TextEditingController> _controllers;
  String _wood = '';
  double _scale = 1.0;
  int _cols = 3;

  @override
  void initState() {
    super.initState();
    () async {
      await us.load();
      setState(() {
        _order = List<Shelf>.from(us.order);
        _controllers = {
          for (final s in Shelf.values)
            s: TextEditingController(text: us.titles[s]),
        };
        _wood = us.woodAsset;
        _scale = us.coverScale;
        _cols = us.gridColsPhone;
      });
    }();
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  String _label(Shelf s) => us.titles[s] ?? s.name.toUpperCase();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Manage shelves')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Text('Names', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          ...Shelf.values.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextField(
                  controller: _controllers[s],
                  decoration: InputDecoration(
                    labelText: '${_label(s)} name',
                    prefixIcon: Icon(s == Shelf.tbr
                        ? Icons.bookmark_added_outlined
                        : s == Shelf.read
                            ? Icons.check_circle_outline
                            : Icons.not_interested_outlined),
                  ),
                  onChanged: (v) => us.setTitle(s, v),
                ),
              )),

          const SizedBox(height: 12),
          Text('Order', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          ReorderableListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (newIndex > oldIndex) newIndex -= 1;
                final item = _order.removeAt(oldIndex);
                _order.insert(newIndex, item);
              });
              us.setOrder(_order);
            },
            children: [
              for (final s in _order)
                ListTile(
                  key: ValueKey(s),
                  leading: const Icon(Icons.drag_handle),
                  title: Text(_label(s)),
                  trailing: Icon(
                    s == Shelf.tbr
                        ? Icons.bookmark_added_outlined
                        : s == Shelf.read
                            ? Icons.check_circle_outline
                            : Icons.not_interested_outlined,
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),
          Text('Shelf appearance', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),

          // Wood picker (simple radio for now)
          Text('Wood background', style: theme.textTheme.labelLarge),
          const SizedBox(height: 6),
          _WoodChoice(
            value: _wood,
            onChanged: (v) {
              setState(() => _wood = v);
              us.setWoodAsset(v);
            },
          ),

          const SizedBox(height: 12),
          Text('Cover size', style: theme.textTheme.labelLarge),
          Slider(
            min: 0.8,
            max: 1.3,
            divisions: 10,
            label: _scale.toStringAsFixed(2),
            value: _scale,
            onChanged: (v) => setState(() => _scale = v),
            onChangeEnd: (v) => us.setCoverScale(v),
          ),

          const SizedBox(height: 12),
          Text('Grid columns (phones)', style: theme.textTheme.labelLarge),
          Row(
            children: [
              Expanded(
                child: Slider(
                  min: 3,
                  max: 6,
                  divisions: 3,
                  label: '$_cols',
                  value: _cols.toDouble(),
                  onChanged: (v) => setState(() => _cols = v.round()),
                  onChangeEnd: (v) => us.setGridColsPhone(v.round()),
                ),
              ),
              SizedBox(
                width: 44,
                child: Center(child: Text('$_cols')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WoodChoice extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  const _WoodChoice({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    // three demo options (you can add more later)
    const options = <(String label, String asset)>[
      ('Oak (light)', 'assets/wood/brown-oak-wood-textured-design-background.jpg'),
      ('Pale Maple',  'assets/wood/pale_maple.jpg'),
      ('Walnut',      'assets/wood/walnut_dark.jpg'),
    ];

    return Column(
      children: options.map((opt) {
        final (label, asset) = opt;
        return RadioListTile<String>(
          value: asset,
          groupValue: value,
          onChanged: (v) => onChanged(v!),
          title: Text(label),
          subtitle: Text(asset, style: const TextStyle(fontSize: 12)),
        );
      }).toList(),
    );
  }
}
