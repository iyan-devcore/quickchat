import 'package:flutter/material.dart';

class AppColors {
  // Snapchat Brand Colors
  static const Color primary = Color(0xFFFFFC00);     // Snapchat Yellow
  static const Color primaryDark = Color(0xFFE8E500); // Pressed yellow
  static const Color secondary = Color(0xFFFFFC00);   // Same yellow for accents

  // Backgrounds — light only
  static const Color backgroundLight = Color(0xFFFFFFFF);
  static const Color backgroundDark = Color(0xFFFFFFFF);   // Force light
  static const Color chatBackgroundLight = Color(0xFFF5F5F5);
  static const Color chatBackgroundDark = Color(0xFFF5F5F5); // Force light

  // Text
  static const Color textLight = Color(0xFF1A1A1A);
  static const Color textDark = Color(0xFF1A1A1A);    // Force light
  static const Color textGrey = Color(0xFF8A8A8A);
  static const Color textSecondary = Color(0xFF5A5A5A);

  // UI Elements
  static const Color dividerLight = Color(0xFFEEEEEE);
  static const Color dividerDark = Color(0xFFEEEEEE);   // Force light
  static const Color inputBackground = Color(0xFFF2F2F2);
  static const Color inputBackgroundLight = Color(0xFFF2F2F2);
  static const Color inputBackgroundDark = Color(0xFFF2F2F2);  // Force light

  // Status & Badges
  static const Color unreadBadge = Color(0xFFFFFC00);
  static const Color online = Color(0xFF2ECC71);
  static const Color red = Color(0xFFE74C3C);

  // Message Bubbles
  static const Color myMessageBubble = Color(0xFFFFFC00);      // Yellow for sent
  static const Color otherMessageBubble = Color(0xFFEDEDED);   // Grey for received

  // Surface
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF7F7F7);
  static const Color border = Color(0xFFEEEEEE);

  // Snapchat-specific
  static const Color snapBlack = Color(0xFF1A1A1A);
  static const Color snapStroke = Color(0xFFE0E0E0);
}
