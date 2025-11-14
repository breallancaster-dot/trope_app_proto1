// lib/widgets/book_results_list.dart
import 'package:flutter/material.dart';

import '../data/book.dart';
import 'book_cover.dart';
import '../navigation/nav.dart';

typedef BookTapCallback = void Function(BuildContext context, Book book);

class BookResultsList extends StatelessWidget {
  final List<Book> books;
  final EdgeInsetsGeometry padding;
  final BookTapCallback? onTap;
  final BookTapCallback? onLongPress;

  const BookResultsList({
    super.key,
    required this.books,
    this.padding = const EdgeInsets.only(bottom: 16),
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (books.isEmpty) {
      return const Center(child: Text('No results'));
    }

    return ListView.separated(
      padding: padding,
      itemCount: books.length,
      separatorBuilder: (_, __) =>
          Divider(height: 1, color: theme.dividerColor),
      itemBuilder: (context, i) {
        final b = books[i];

        void handleTap() {
          if (onTap != null) {
            onTap!(context, b);
          } else {
            Nav.toBook(context, b.id);
          }
        }

        void handleLongPress() {
          if (onLongPress != null) {
            onLongPress!(context, b);
          }
        }

        return ListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: bookCoverWidget(b.coverUrl, w: 48, h: 72),
          ),
          title: Text(b.title),
          subtitle: Text(
            '${b.author}${b.tropes.isNotEmpty ? ' • ${b.tropes.join(', ')}' : ''}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: handleTap,
          onLongPress: onLongPress == null ? null : handleLongPress,
        );
      },
    );
  }
}
