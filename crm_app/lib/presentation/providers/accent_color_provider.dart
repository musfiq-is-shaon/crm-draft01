import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _accentKey = 'accent_color_argb';
const _recentKey = 'accent_color_recent';

Color _decodeColor(String? raw) {
  if (raw == null || raw.isEmpty) return AppAccent.defaultAccent;
  final v = int.tryParse(raw, radix: 10);
  if (v == null) return AppAccent.defaultAccent;
  return Color(v);
}

class AppAccent {
  AppAccent._();

  static const Color defaultAccent = Color(0xFF2563EB);

  static String encodeColor(Color c) => c.toARGB32().toString();

  static List<Color> decodeRecent(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => Color(int.parse(e.toString())))
          .take(12)
          .toList();
    } catch (_) {
      return [];
    }
  }

  static String encodeRecent(List<Color> colors) {
    final limited = colors.take(12).toList();
    return jsonEncode(limited.map((c) => c.toARGB32().toString()).toList());
  }
}

class AccentColorNotifier extends StateNotifier<Color> {
  AccentColorNotifier(this._storage) : super(AppAccent.defaultAccent);

  final FlutterSecureStorage _storage;
  List<Color> _recent = [];
  bool _ready = false;

  List<Color> get recentColors => List.unmodifiable(_recent);

  bool get isReady => _ready;

  Future<void> init() async {
    if (_ready) return;
    final raw = await _storage.read(key: _accentKey);
    state = _decodeColor(raw);
    final r = await _storage.read(key: _recentKey);
    _recent = AppAccent.decodeRecent(r);
    _ready = true;
  }

  Future<void> setAccent(Color color) async {
    final opaque = Color.fromARGB(
      255,
      (color.r * 255.0).round().clamp(0, 255),
      (color.g * 255.0).round().clamp(0, 255),
      (color.b * 255.0).round().clamp(0, 255),
    );
    state = opaque;
    await _storage.write(key: _accentKey, value: AppAccent.encodeColor(opaque));
    await _pushRecent(opaque);
  }

  Future<void> _pushRecent(Color color) async {
    final argb = color.toARGB32();
    _recent.removeWhere((c) => c.toARGB32() == argb);
    _recent.insert(0, color);
    if (_recent.length > 12) {
      _recent = _recent.sublist(0, 12);
    }
    await _storage.write(
        key: _recentKey, value: AppAccent.encodeRecent(_recent));
  }

  Future<void> setRecentFromPicker(List<Color> next) async {
    _recent = next.take(12).toList();
    await _storage.write(key: _recentKey, value: AppAccent.encodeRecent(_recent));
  }
}

final accentColorProvider =
    StateNotifierProvider<AccentColorNotifier, Color>((ref) {
  return AccentColorNotifier(
    const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
      iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
    ),
  );
});
