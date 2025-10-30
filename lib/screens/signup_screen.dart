import 'package:flutter/material.dart';
import '../navigation/app_shell.dart';

class SignupScreen extends StatelessWidget {
  static const route = '/signup';
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign up')),
      body: Center(
        child: FilledButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Signed up (demo)')),
            );
            Navigator.of(context).pushReplacementNamed(AppShell.route);
          },
          child: const Text('Fake Signup Success'),
        ),
      ),
    );
  }
}
