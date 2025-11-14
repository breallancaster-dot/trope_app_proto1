import 'package:flutter/material.dart';

import 'navigation/app_shell.dart';
import 'screens/welcome_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'features/search/trope_picker_screen.dart';
import 'features/search/trope_search_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BookApp());
}

class BookApp extends StatelessWidget {
  const BookApp({super.key});
  
  get appTheme => null;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Trope App',
      theme: appTheme,

      /// Start at the welcome screen. From there, you navigate to:
      /// - Login
      /// - Signup
      /// - AppShell (main app, with its own tab navigation)
      initialRoute: WelcomeScreen.route,

      routes: {
        // Entry / auth-ish flow
        WelcomeScreen.route: (_) => const WelcomeScreen(),
        LoginScreen.route: (_) => const LoginScreen(),
        SignupScreen.route: (_) => const SignupScreen(),

        // Main app shell (bottom nav, nested navigators, etc)
        AppShell.route: (_) => const AppShell(),

        // These are only here so you *can* push them from outside the shell
        // if you ever decide to (rare). Inside the shell, navigation is
        // handled by AppShell's own onGenerateRoute.
        TropePickerScreen.route: (_) =>
            const TropePickerScreen(prefill: []),
        TropeSearchScreen.route: (_) => const TropeSearchScreen(),
      },

      // If some nonsense route is requested, fall back gracefully
      onUnknownRoute: (_) =>
          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
    );
  }
}
