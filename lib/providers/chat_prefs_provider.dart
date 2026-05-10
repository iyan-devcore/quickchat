import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Wallpaper types the user can choose from.
enum WallpaperType { none, gradient, image }

/// Holds the chat customization preferences for the entire app.
/// Settings are stored locally via SharedPreferences and applied in ChatScreen.
class ChatPrefsProvider with ChangeNotifier {
  // ── Wallpaper ───────────────────────────────────────────────
  WallpaperType _wallpaperType = WallpaperType.none;
  int _wallpaperGradientIndex = 0; // index into predefined gradient list
  String? _wallpaperImagePath;     // local file path OR remote URL

  // ── Bubble colour ────────────────────────────────────────────
  int _myBubbleColorIndex = 0;     // index into predefined colour list

  // ── Getters ─────────────────────────────────────────────────
  WallpaperType get wallpaperType        => _wallpaperType;
  int           get wallpaperGradientIndex => _wallpaperGradientIndex;
  String?       get wallpaperImagePath   => _wallpaperImagePath;
  int           get myBubbleColorIndex   => _myBubbleColorIndex;

  // ── Static palettes (used in the UI picker) ─────────────────
  static const List<List<Color>> gradients = [
    [Color(0xFF0F172A), Color(0xFF1E293B)],   // Default dark
    [Color(0xFF0D1B2A), Color(0xFF1B4332)],   // Deep ocean-forest
    [Color(0xFF1A0533), Color(0xFF2D0657)],   // Midnight purple
    [Color(0xFF0F2027), Color(0xFF203A43)],   // Slate blue
    [Color(0xFF1A1A2E), Color(0xFF16213E)],   // Deep navy
    [Color(0xFF0D0D0D), Color(0xFF1A1A1A)],   // Pitch black
    [Color(0xFF1B0000), Color(0xFF3B0000)],   // Deep crimson
    [Color(0xFF003B2F), Color(0xFF00695C)],   // Dark teal
  ];

  static const List<Color> bubbleColors = [
    Color(0xFF6366F1),   // Indigo (default)
    Color(0xFFA855F7),   // Purple
    Color(0xFF06B6D4),   // Cyan
    Color(0xFF10B981),   // Emerald
    Color(0xFFF59E0B),   // Amber
    Color(0xFFEF4444),   // Red
    Color(0xFFEC4899),   // Pink
    Color(0xFFF97316),   // Orange
  ];

  Color get myBubbleColor => bubbleColors[_myBubbleColorIndex];

  // ── Persistence keys ─────────────────────────────────────────
  static const _kWpType     = 'chat_wp_type';
  static const _kWpGrad     = 'chat_wp_gradient';
  static const _kWpImg      = 'chat_wp_image';
  static const _kBubbleCol  = 'chat_bubble_color';

  /// Load saved prefs from disk.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _wallpaperType          = WallpaperType.values[prefs.getInt(_kWpType) ?? 0];
    _wallpaperGradientIndex = prefs.getInt(_kWpGrad) ?? 0;
    _wallpaperImagePath     = prefs.getString(_kWpImg);
    _myBubbleColorIndex     = prefs.getInt(_kBubbleCol) ?? 0;
    notifyListeners();
  }

  Future<void> setGradientWallpaper(int index) async {
    _wallpaperType          = WallpaperType.gradient;
    _wallpaperGradientIndex = index;
    _wallpaperImagePath     = null;
    await _save();
    notifyListeners();
  }

  Future<void> setImageWallpaper(String path) async {
    _wallpaperType      = WallpaperType.image;
    _wallpaperImagePath = path;
    await _save();
    notifyListeners();
  }

  Future<void> clearWallpaper() async {
    _wallpaperType      = WallpaperType.none;
    _wallpaperImagePath = null;
    await _save();
    notifyListeners();
  }

  Future<void> setBubbleColor(int index) async {
    _myBubbleColorIndex = index;
    await _save();
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kWpType,   _wallpaperType.index);
    await prefs.setInt(_kWpGrad,   _wallpaperGradientIndex);
    await prefs.setInt(_kBubbleCol, _myBubbleColorIndex);
    if (_wallpaperImagePath != null) {
      await prefs.setString(_kWpImg, _wallpaperImagePath!);
    } else {
      await prefs.remove(_kWpImg);
    }
  }
}
