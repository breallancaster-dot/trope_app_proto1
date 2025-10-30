// lib/widgets/bookshelf_grid.dart
// (Optional helper if you want to reuse a wood grid elsewhere in the app)

import 'dart:math';
import 'package:flutter/material.dart';
import '../data/book.dart';
import 'book_cover.dart';

class BookshelfGrid extends StatelessWidget {
  final List<Book> books;
  final void Function(Book) onTap;

  const BookshelfGrid({super.key, required this.books, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return _WoodBackground(
      child: LayoutBuilder(
        builder: (ctx, constraints) {
          final w = constraints.maxWidth;
          final colCount = max(3, (w / 140).floor());
          const spacing = 16.0;
          final totalGutters = spacing * (colCount - 1);
          final itemW = (w - totalGutters) / colCount;
          final itemH = itemW * 1.5;

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: colCount,
              crossAxisSpacing: spacing,
              mainAxisSpacing: spacing,
              childAspectRatio: itemW / itemH,
            ),
            itemCount: books.length,
            itemBuilder: (ctx, i) {
              final b = books[i];
              return InkWell(
                onTap: () => onTap(b),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    bookCoverWidget(
                      b.coverUrl,
                      w: itemW,
                      h: itemH,
                      borderRadius: const BorderRadius.all(Radius.circular(10)),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      b.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.white),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _WoodBackground extends StatelessWidget {
  final Widget child;
  const _WoodBackground({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image:
              AssetImage('assets/wood/brown-oak-wood-textured-design-background.jpg'),
          fit: BoxFit.cover,
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(color: Colors.black.withOpacity(0.15)),
        child: child,
      ),
    );
  }
}
