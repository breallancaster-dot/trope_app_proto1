import 'package:flutter/material.dart';
import '../navigation/app_shell.dart';

class LoginScreen extends StatelessWidget {
  static const route = '/login';
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Log in')),
      body: Center(
        child: FilledButton(
          onPressed: () {
            // Fake success → go to home
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Logged in (demo)')),
            );
            Navigator.of(context).pushReplacementNamed(AppShell.route);
          },
          child: const Text('Fake Login Success'),
        ),
      ),
    );
  }
}
