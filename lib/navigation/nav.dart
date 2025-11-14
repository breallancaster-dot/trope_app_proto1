// lib/navigation/nav.dart
import 'package:flutter/material.dart';

import '../screens/book_detail_screen.dart';

class Nav {
  /// Open the book detail screen for a given [bookId].
  static Future<void> toBook(BuildContext context, String bookId) {
    return Navigator.of(context).pushNamed(
      BookDetailScreen.route,
      arguments: {'bookId': bookId},
    );
  }
}
