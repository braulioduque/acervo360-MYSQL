import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Gerencia o tema (dark/light) do app com persistência.
class ThemeService {
  ThemeService._();

  static const _key = 'theme_mode';

  static final ValueNotifier<ThemeMode> themeMode =
      ValueNotifier(ThemeMode.dark);

  /// Carrega a preferência salva. Chamar antes de `runApp`.
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    if (saved == 'light') {
      themeMode.value = ThemeMode.light;
    } else {
      themeMode.value = ThemeMode.dark;
    }
  }

  /// Alterna entre dark e light e persiste.
  static Future<void> toggle() async {
    final next = themeMode.value == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;
    themeMode.value = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, next == ThemeMode.light ? 'light' : 'dark');
  }

  /// Define um modo específico e persiste.
  static Future<void> setMode(ThemeMode mode) async {
    themeMode.value = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode == ThemeMode.light ? 'light' : 'dark');
  }

  static bool get isDark => themeMode.value == ThemeMode.dark;
}
