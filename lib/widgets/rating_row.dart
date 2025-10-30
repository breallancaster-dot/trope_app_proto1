// lib/widgets/rating_row.dart
import 'package:flutter/material.dart';

class RatingRow extends StatelessWidget {
  final int stars;   // 0..5
  final int spice;   // 0..3
  final void Function(int newStars)? onStars;
  final void Function(int newSpice)? onSpice;

  const RatingRow({
    super.key,
    required this.stars,
    required this.spice,
    this.onStars,
    this.onSpice,
  });

  @override
  Widget build(BuildContext context) {
    Widget star(int i) => IconButton(
      visualDensity: VisualDensity.compact,
      iconSize: 20,
      padding: const EdgeInsets.all(2),
      onPressed: onStars == null ? null : () => onStars!(i),
      icon: Icon(
        i <= stars ? Icons.star_rounded : Icons.star_outline_rounded,
      ),
    );

    Widget flame(int i) => IconButton(
      visualDensity: VisualDensity.compact,
      iconSize: 18,
      padding: const EdgeInsets.all(2),
      onPressed: onSpice == null ? null : () => onSpice!(i),
      icon: Icon(
        i <= spice ? Icons.local_fire_department_rounded : Icons.local_fire_department_outlined,
      ),
    );

    return Row(
      children: [
        ...List.generate(5, (i) => star(i + 1)),
        const SizedBox(width: 12),
        ...List.generate(3, (i) => flame(i + 1)),
      ],
    );
  }
}
