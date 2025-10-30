// lib/widgets/illustrated_shelves.dart
import 'dart:math';
import 'package:flutter/material.dart';

/// Cute illustrated shelf with SHARED rails:
/// - Exactly 3 covers per row
/// - One rail at the very top, one between rows, one at the bottom
/// - No double lines between rows
class IllustratedShelfGrid extends StatelessWidget {
  const IllustratedShelfGrid({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.aspectRatio = 2 / 3,   // cover width : height
    this.horizontalGap = 14,    // gap between covers in a row
    this.rowGap = 0,            // extra space after each rail (usually 0–8)
    this.railHeight = 20,
    this.railGapToCovers = 8,   // gap from a rail to covers
    this.colorFace = const Color(0xFFFFE5ED),
    this.colorEdge = const Color(0xFFF5C8D4),
    this.shadowColor = const Color(0x22000000),
  });

  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;

  final double aspectRatio;
  final double horizontalGap;
  final double rowGap;
  final double railHeight;
  final double railGapToCovers;

  final Color colorFace;
  final Color colorEdge;
  final Color shadowColor;

  @override
  Widget build(BuildContext context) {
    const cols = 3; // fixed 3 across for the “books between rails” look

    return LayoutBuilder(
      builder: (ctx, constraints) {
        final w = constraints.maxWidth;

        // Tile sizing
        final totalGutters = horizontalGap * (cols - 1);
        final tileW = (w - totalGutters) / cols;
        final tileH = tileW / aspectRatio;

        final rows = max(1, (itemCount / cols).ceil());

        // Build children as:
        // [TopRail] -> (Gap -> RowCovers -> Gap -> Rail [+rowGap]) x rows
        final children = <Widget>[];

        // Top rail (only once)
        children.add(SizedBox(
          height: railHeight,
          width: double.infinity,
          child: _rail(colorFace, colorEdge, shadowColor),
        ));

        int index = 0;
        for (var r = 0; r < rows; r++) {
          // Space from rail to covers
          children.add(SizedBox(height: railGapToCovers));

          // Covers row (up to 3)
          final thisRowCount = min(cols, itemCount - index);
          final rowChildren = <Widget>[];
          for (var i = 0; i < thisRowCount; i++) {
            rowChildren.add(SizedBox(
              width: tileW,
              height: tileH,
              child: itemBuilder(ctx, index++),
            ));
            if (i != thisRowCount - 1) {
              rowChildren.add(SizedBox(width: horizontalGap));
            }
          }
          children.add(Row(children: rowChildren));

          // Space from covers down to rail
          children.add(SizedBox(height: railGapToCovers));

          // Shared rail below this row
          children.add(SizedBox(
            height: railHeight,
            width: double.infinity,
            child: _rail(colorFace, colorEdge, shadowColor),
          ));

          // Optional breathing room after the rail (not between two rails)
          if (r != rows - 1 && rowGap > 0) {
            children.add(SizedBox(height: rowGap));
          }
        }

        return Column(children: children);
      },
    );
  }

  Widget _rail(Color face, Color edge, Color shadow) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: face,
        borderRadius: const BorderRadius.all(Radius.circular(14)),
        boxShadow: [
          BoxShadow(
            color: shadow,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border(bottom: BorderSide(color: edge, width: 2)),
      ),
    );
  }
}
