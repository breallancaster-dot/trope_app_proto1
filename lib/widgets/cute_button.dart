// lib/widgets/cute_button.dart
import 'package:flutter/material.dart';
import '../data/user_lists.dart';

class CuteButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool filled;

  const CuteButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.filled = true,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = filled ? scheme.primary : scheme.primaryContainer;
    final fg = filled ? scheme.onPrimary : scheme.onPrimaryContainer;

    final child = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18),
          const SizedBox(width: 8),
        ],
        Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
      ],
    );

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: fg,
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        elevation: 0,
      ),
      onPressed: onPressed,
      child: child,
    );
  }
}

/// Goodreads-style split button:
/// - Big pill says “Want to Read” / “In TBR” / “Read” / “DNF”
/// - Tiny chevron opens menu to switch shelves.
class SplitWantButton extends StatefulWidget {
  final String bookId;
  final ValueChanged<Shelf?>? onShelfChanged;

  const SplitWantButton({
    super.key,
    required this.bookId,
    this.onShelfChanged,
  });

  @override
  State<SplitWantButton> createState() => _SplitWantButtonState();
}

class _SplitWantButtonState extends State<SplitWantButton> {
  Shelf? _shelf;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _shelf = await UserLists.shelfFor(widget.bookId);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _setShelf(Shelf? s) async {
    if (s == null) {
      await UserLists.removeEverywhere(widget.bookId);
    } else {
      await UserLists.addTo(s, widget.bookId);
    }
    _shelf = await UserLists.shelfFor(widget.bookId);
    if (mounted) setState(() {});
    widget.onShelfChanged?.call(_shelf);
  }

  String _label() => switch (_shelf) {
        Shelf.tbr  => 'In TBR',
        Shelf.read => 'Read',
        Shelf.dnf  => 'DNF',
        null       => 'Want to Read',
      };

  Color _bg(BuildContext ctx) {
    final c = Theme.of(ctx).colorScheme;
    return switch (_shelf) {
      Shelf.tbr  => c.primary,
      Shelf.read => Colors.green,
      Shelf.dnf  => Colors.redAccent,
      null       => c.primaryContainer,
    };
  }

  Color _fg(BuildContext ctx) {
    final c = Theme.of(ctx).colorScheme;
    return switch (_shelf) {
      Shelf.tbr  => c.onPrimary,
      Shelf.read => Colors.white,
      Shelf.dnf  => Colors.white,
      null       => c.onPrimaryContainer,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        height: 44,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    final bg = _bg(context);
    final fg = _fg(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // main pill
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: bg,
            foregroundColor: fg,
            shape: const StadiumBorder(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            elevation: 0,
          ),
          onPressed: () async {
            // primary action = add to TBR if none; otherwise cycle Read -> TBR
            if (_shelf == null) {
              await _setShelf(Shelf.tbr);
            } else if (_shelf == Shelf.tbr) {
              await _setShelf(Shelf.read);
            } else {
              await _setShelf(Shelf.tbr);
            }
          },
          child: Text(_label()),
        ),
        const SizedBox(width: 8),
        // small chevron menu
        Material(
          color: bg,
          shape: const StadiumBorder(),
          child: PopupMenuButton<_MenuChoice>(
            tooltip: 'Change shelf',
            icon: Icon(Icons.arrow_drop_down, color: fg),
            color: Theme.of(context).colorScheme.surface,
            onSelected: (choice) async {
              switch (choice) {
                case _MenuChoice.toTbr:   await _setShelf(Shelf.tbr);  break;
                case _MenuChoice.toRead:  await _setShelf(Shelf.read); break;
                case _MenuChoice.toDnf:   await _setShelf(Shelf.dnf);  break;
                case _MenuChoice.remove:  await _setShelf(null);       break;
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: _MenuChoice.toTbr,  child: ListTile(leading: Icon(Icons.bookmark_add_outlined), title: Text('Add to TBR'))),
              const PopupMenuItem(value: _MenuChoice.toRead, child: ListTile(leading: Icon(Icons.check_circle_outline),  title: Text('Mark as Read'))),
              const PopupMenuItem(value: _MenuChoice.toDnf,  child: ListTile(leading: Icon(Icons.not_interested_outlined),title: Text('Mark as DNF'))),
              const PopupMenuDivider(),
              const PopupMenuItem(value: _MenuChoice.remove, child: ListTile(leading: Icon(Icons.remove_circle_outline),  title: Text('Remove from shelves'))),
            ],
          ),
        ),
      ],
    );
  }
}

enum _MenuChoice { toTbr, toRead, toDnf, remove }
