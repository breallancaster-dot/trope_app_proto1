// lib/widgets/shelf_card.dart
import 'package:flutter/material.dart';
import '../data/book.dart';
import '../data/user_lists.dart';
import '../widgets/book_cover.dart';
import '../screens/shelf_detail_screen.dart';

class ShelfCard extends StatelessWidget {
  final Shelf shelf;
  final List<Book> books;          // pass books (can be empty)
  final int thumbCount;            // 3/5/10 previews supported by Library screen
  final EdgeInsets padding;

  const ShelfCard({
    super.key,
    required this.shelf,
    required this.books,
    this.thumbCount = 3,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  });

  String _title() => switch (shelf) {
        Shelf.tbr => 'To Be Read',
        Shelf.read => 'Read',
        Shelf.dnf => 'Did Not Finish',
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final count = books.length;

    final previews = books.take(thumbCount).toList();
    final deficit = thumbCount - previews.length;

    return Padding(
      padding: padding,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.of(context).push(
            ShelfDetailScreen.materialRoute(shelf: shelf),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Text(
                  _title(),
                  style: theme.textTheme.titleLarge!
                      .copyWith(fontWeight: FontWeight.w800),
                ),
                const Spacer(),
                Text(
                  '$count ${count == 1 ? "book" : "books"}',
                  style: theme.textTheme.bodyMedium!
                      .copyWith(color: theme.colorScheme.outline),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Preview slots
            LayoutBuilder(
              builder: (ctx, constraints) {
                final n = thumbCount;
                final gap = 12.0;
                final totalGaps = gap * (n - 1);
                final slotW = (constraints.maxWidth - totalGaps) / n;
                final slotH = slotW * 1.2; // slightly squarer for card

                List<Widget> slots = [
                  for (final b in previews)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: SizedBox(
                        width: slotW,
                        height: slotH,
                        child: bookCoverWidget(
                          b.coverUrl,
                          w: slotW,
                          h: slotH,
                          borderRadius:
                              const BorderRadius.all(Radius.circular(14)),
                        ),
                      ),
                    ),
                  for (int i = 0; i < deficit; i++)
                    Container(
                      width: slotW,
                      height: slotH,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant,
                        ),
                      ),
                    ),
                ];

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: slots,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
