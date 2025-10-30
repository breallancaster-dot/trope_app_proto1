// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  static const route = '/profile';
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // No AppBar: pastel background to the top
    return const Scaffold(
      body: SafeArea(
        child: Center(
          child: Text('Profile (coming soon)'),
        ),
      ),
    );
  }
}
