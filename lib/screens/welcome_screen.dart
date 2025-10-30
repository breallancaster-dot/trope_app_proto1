import 'package:flutter/material.dart';
import '../navigation/app_shell.dart';
import 'login_screen.dart';
import 'signup_screen.dart';

class WelcomeScreen extends StatelessWidget {
  static const route = '/welcome';
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Welcome')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Welcome to Trope App', style: TextStyle(fontSize: 22)),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () {
                  debugPrint('→ Login tapped');
                  Navigator.of(context).pushNamed(LoginScreen.route);
                },
                child: const Text('Log in'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () {
                  debugPrint('→ Signup tapped');
                  Navigator.of(context).pushNamed(SignupScreen.route);
                },
                child: const Text('Sign up'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  debugPrint('→ Continue as guest tapped');
                  Navigator.of(context).pushReplacementNamed(AppShell.route);
                },
                child: const Text('Continue as guest'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
