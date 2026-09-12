import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  final SharedPreferences sharedPreferences;
  bool _isDarkMode = false;

  ThemeProvider(this.sharedPreferences) {
    _isDarkMode = sharedPreferences.getBool('darkMode') ?? false;
  }

  bool get isDarkMode => _isDarkMode;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    sharedPreferences.setBool('darkMode', _isDarkMode);
    notifyListeners();
  }

  void setDarkMode(bool value) {
    _isDarkMode = value;
    sharedPreferences.setBool('darkMode', _isDarkMode);
    notifyListeners();
  }
}