// lib/navigation/nav.dart
import 'package:flutter/material.dart';
import '../screens/book_detail_screen.dart';

class Nav {
  static Future<void> toBook(BuildContext context, String bookId) {
    return Navigator.of(context).pushNamed(
      BookDetailScreen.route,
      arguments: {'id': bookId},
    );
  }
}
