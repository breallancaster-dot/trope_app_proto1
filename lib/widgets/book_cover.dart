// lib/widgets/book_cover.dart
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// Unified cover image widget with *explicit* constraints.
/// No AspectRatio is used to avoid unbounded layout issues.
Widget bookCoverWidget(
  String? coverUrl, {
  double w = 48,
  double h = 72,
  BorderRadius borderRadius = const BorderRadius.all(Radius.circular(6)),
}) {
  Widget fallback() => SizedBox(
        width: w,
        height: h,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.black12,
            borderRadius: borderRadius,
          ),
          child: const Icon(Icons.menu_book, color: Colors.black38, size: 20),
        ),
      );

  final url = (coverUrl ?? '').trim();
  if (url.isEmpty) return fallback();

  final content = () {
    if (url.startsWith('assets/')) {
      return Image.asset(url, width: w, height: h, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => fallback());
    }
    if (url.startsWith('http')) {
      return Image.network(url, width: w, height: h, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => fallback());
    }
    if (kIsWeb) return fallback();

    try {
      return Image.file(File(url), width: w, height: h, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => fallback());
    } catch (_) {
      return fallback();
    }
  }();

  return ClipRRect(borderRadius: borderRadius, child: content);
}
