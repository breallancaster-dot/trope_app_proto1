// lib/widgets/rating_row.dart
import 'package:flutter/material.dart';

class RatingRow extends StatelessWidget {
  final int stars; // 0..5
  final int spice; // 0..3 or 0..5, up to you
  final ValueChanged<int> onStars;
  final ValueChanged<int> onSpice;

  const RatingRow({
    super.key,
    required this.stars,
    required this.spice,
    required this.onStars,
    required this.onSpice,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main star rating row
        Row(
          children: [
            Text(
              'My rating',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 12),
            Wrap(
              spacing: 4,
              children: List.generate(5, (index) {
                final value = index + 1;
                final filled = value <= stars;
                return IconButton(
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 32, minHeight: 32),
                  onPressed: () => onStars(value),
                  icon: Icon(
                    filled ? Icons.star : Icons.star_border,
                    size: 20,
                    color: filled
                        ? theme.colorScheme.secondary
                        : theme.disabledColor,
                  ),
                );
              }),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Spice row underneath
        Row(
          children: [
            Text(
              'Spice',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 12),
            Wrap(
              spacing: 4,
              children: List.generate(3, (index) {
                final value = index + 1;
                final filled = value <= spice;
                return IconButton(
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 32, minHeight: 32),
                  onPressed: () => onSpice(value),
                  icon: Icon(
                    Icons.local_fire_department,
                    size: 20,
                    color: filled
                        ? theme.colorScheme.error
                        : theme.disabledColor,
                  ),
                );
              }),
            ),
          ],
        ),
      ],
    );
  }
}
