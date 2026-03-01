import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeProvider(SharedPreferences prefs);

  ThemeMode get themeMode => ThemeMode.light;
  bool get isDarkMode => false;

  void setThemeMode(ThemeMode mode) {}
}
