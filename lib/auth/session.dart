// lib/auth/session.dart
import 'package:shared_preferences/shared_preferences.dart';

class Session {
  static const _kSignedIn = 'signed_in';
  static const _kIsGuest  = 'is_guest';

  static Future<bool> isSignedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kSignedIn) ?? false;
  }

  static Future<bool> isGuest() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kIsGuest) ?? false;
  }

  static Future<void> continueAsGuest() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kSignedIn, true);
    await prefs.setBool(_kIsGuest,  true);
  }

  static Future<void> signInUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kSignedIn, true);
    await prefs.setBool(_kIsGuest,  false);
  }

  static Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kSignedIn);
    await prefs.remove(_kIsGuest);
  }
}
