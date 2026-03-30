import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ThemeNotifier extends StateNotifier<ThemeMode> {
  final FlutterSecureStorage _storage;
  static const String _themeKey = 'theme_mode';
  bool _isInitialized = false;

  ThemeNotifier()
    : _storage = const FlutterSecureStorage(
        aOptions: AndroidOptions(encryptedSharedPreferences: true),
        iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
      ),
      super(ThemeMode.light);

  bool get isInitialized => _isInitialized;

  Future<void> init() async {
    if (_isInitialized) return;
    final isDarkMode = await _getThemeMode();
    state = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    _isInitialized = true;
  }

  Future<void> _saveThemeMode(bool isDark) async {
    await _storage.write(key: _themeKey, value: isDark.toString());
  }

  Future<bool> _getThemeMode() async {
    final value = await _storage.read(key: _themeKey);
    return value == 'true';
  }

  /// Toggles immediately; persistence runs in the background so animation isn’t delayed.
  void toggleTheme() {
    state = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    _saveThemeMode(state == ThemeMode.dark);
  }

  void setThemeMode(ThemeMode mode) {
    state = mode;
    _saveThemeMode(mode == ThemeMode.dark);
  }

  bool get isDarkMode => state == ThemeMode.dark;
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});
