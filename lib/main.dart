import 'package:flutter/material.dart';

import 'navigation/app_shell.dart';
import 'screens/welcome_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/book_detail_screen.dart';
import 'features/search/trope_picker_screen.dart';
import 'features/search/trope_search_screen.dart';
import 'features/search/trope_results_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BookApp());
}

class BookApp extends StatelessWidget {
  const BookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Trope App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,

      initialRoute: WelcomeScreen.route,
      routes: {
        WelcomeScreen.route: (_) => const WelcomeScreen(),
        LoginScreen.route: (_) => const LoginScreen(),
        SignupScreen.route: (_) => const SignupScreen(),

        // Main shell (bottom tabs)
        AppShell.route: (_) => const AppShell(),

        // Detail & Search flows (use the *fromRouteArgs* helpers)
        BookDetailScreen.route: (ctx) => BookDetailScreen.fromRouteArgs(ctx),
        TropePickerScreen.route: (_) => const TropePickerScreen(prefill: [],),
        TropeSearchScreen.route: (_) => const TropeSearchScreen(),
        TropeResultsScreen.route: (ctx) => TropeResultsScreen.fromRouteArgs(ctx),
      },

      // Fallback
      onUnknownRoute: (_) =>
          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
    );
  }
}
