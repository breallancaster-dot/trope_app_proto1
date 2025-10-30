// lib/widgets/bookshelf.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../data/book.dart';
import 'book_cover.dart';

/// A responsive, 3-column bookshelf with wooden planks.
/// - Covers are fixed-size 2:3, equal spacing, consistent side padding.
/// - Always shows at least 3 shelves (rows) even if there are fewer books.
class BookShelfGrid extends StatelessWidget {
  final List<Book> books;
  final EdgeInsetsGeometry padding;
  final double sidePadding;        // left/right screen padding
  final double hGap;               // horizontal gap between covers
  final double vGap;               // vertical gap between cover rows
  final void Function(Book)? onTap;

  const BookShelfGrid({
    super.key,
    required this.books,
    this.padding = const EdgeInsets.symmetric(vertical: 12),
    this.sidePadding = 16,
    this.hGap = 16,
    this.vGap = 22,
    this.onTap, required int columns, required int coverWidth, required int coverHeight,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        // Exactly 3 columns, equal spacing, fixed side padding.
        const columns = 3;
        final totalWidth = constraints.maxWidth;
        final usable = totalWidth - sidePadding * 2 - hGap * (columns - 1);
        final coverWidth = usable / columns;
        final coverHeight = coverWidth * 1.5; // 2:3 aspect ratio

        // rows needed for books
        final computedRows =
            books.isEmpty ? 0 : (books.length / columns).ceil();
        // always show at least 3 shelves
        final rows = math.max(3, computedRows);

        // distance between shelf planks (slightly below each row of covers)
        final shelfPitch = coverHeight + vGap + 16; // plank every row

        return CustomPaint(
          painter: _WoodShelvesPainter(
            rowCount: rows,
            shelfPitch: shelfPitch,
            leftInset: sidePadding,
            rightInset: sidePadding,
          ),
          child: Padding(
            padding: padding.add(EdgeInsets.symmetric(horizontal: sidePadding)),
            child: Wrap(
              spacing: hGap,
              runSpacing: vGap,
              children: List.generate(rows * columns, (i) {
                // Fixed-size slot so items never jump around.
                if (i >= books.length) {
                  return SizedBox(
                    width: coverWidth,
                    height: coverHeight,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  );
                }
                final b = books[i];
                // tiny stagger for playfulness (doesn't affect size)
                final dy = (i % columns).isOdd ? -3.0 : 0.0;
                return Transform.translate(
                  offset: Offset(0, dy),
                  child: GestureDetector(
                    onTap: onTap == null ? null : () => onTap!(b),
                    child: SizedBox(
                      width: coverWidth,
                      height: coverHeight,
                      child: bookCoverWidget(
                        b.coverUrl,
                        w: coverWidth,
                        h: coverHeight,
                        borderRadius:
                            const BorderRadius.all(Radius.circular(10)),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        );
      },
    );
  }
}

/// Painter that draws warm wooden planks under each row.
/// No external images needed; uses gradients + subtle grain lines.
class _WoodShelvesPainter extends CustomPainter {
  final int rowCount;
  final double shelfPitch;
  final double leftInset;
  final double rightInset;

  _WoodShelvesPainter({
    required this.rowCount,
    required this.shelfPitch,
    required this.leftInset,
    required this.rightInset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (rowCount <= 0) return;

    // Colors tuned for a soft wood look
    final baseTop = const Color(0xFFB07A4A);   // lighter
    final baseBot = const Color(0xFF8A5A33);   // darker
    final edge = const Color(0x66000000);      // soft edge shadow
    final highlight = const Color(0x33FFFFFF); // subtle highlight

    final plankHeight = 14.0;
    final radius = 10.0;

    for (int r = 0; r < rowCount; r++) {
      // Plank just *below* where the row of covers sits
      final y = (r + 1) * shelfPitch - 8;
      if (y > size.height) break;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          leftInset,
          y.clamp(0, size.height - plankHeight),
          size.width - leftInset - rightInset,
          plankHeight,
        ),
        Radius.circular(radius),
      );

      // Wood gradient
      final gradient = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [baseTop, baseBot],
      );
      final paint = Paint()
        ..shader = gradient.createShader(rect.outerRect);

      // Draw plank
      canvas.drawRRect(rect, paint);

      // Edge stroke/shadow
      final edgePaint = Paint()
        ..color = edge
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;
      canvas.drawRRect(rect, edgePaint);

      // Soft highlight near top edge
      final hiRect = Rect.fromLTWH(
        rect.left + 6,
        rect.top + 2,
        rect.width - 12,
        2.0,
      );
      final hiPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [highlight, Colors.transparent, highlight],
        ).createShader(hiRect);
      canvas.drawRect(hiRect, hiPaint);

      // Subtle grain lines across plank
      final grain = Paint()
        ..color = const Color(0x22000000)
        ..strokeWidth = 0.8;
      final grooves = 6;
      for (int i = 0; i < grooves; i++) {
        final gx = rect.left + 10 + (i * (rect.width - 20) / (grooves - 1));
        final gy1 = rect.top + 3;
        final gy2 = rect.bottom - 3;
        // small sinusoidal wiggle for organic feel
        final wiggle = math.sin((i + r) * 1.2) * 0.8;
        canvas.drawLine(Offset(gx, gy1 + wiggle), Offset(gx, gy2 - wiggle), grain);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _WoodShelvesPainter old) {
    return rowCount != old.rowCount ||
        shelfPitch != old.shelfPitch ||
        leftInset != old.leftInset ||
        rightInset != old.rightInset;
  }
}
