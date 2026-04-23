import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  // Force light-only — no dark mode
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      onPrimary: AppColors.snapBlack,
      secondary: AppColors.primary,
      onSecondary: AppColors.snapBlack,
      surface: AppColors.surface,
      onSurface: AppColors.textLight,
      outline: AppColors.border,
    ),
    scaffoldBackgroundColor: AppColors.backgroundLight,
    // White AppBar — Snapchat style
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.backgroundLight,
      foregroundColor: AppColors.snapBlack,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.black12,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      titleTextStyle: GoogleFonts.nunito(
        color: AppColors.snapBlack,
        fontSize: 20,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.3,
      ),
      iconTheme: const IconThemeData(color: AppColors.snapBlack),
      actionsIconTheme: const IconThemeData(color: AppColors.snapBlack),
    ),
    // Bottom nav — white with yellow indicator
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.backgroundLight,
      indicatorColor: AppColors.primary,
      indicatorShape: const CircleBorder(),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return GoogleFonts.nunito(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.snapBlack,
          );
        }
        return GoogleFonts.nunito(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: AppColors.textGrey,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: AppColors.snapBlack, size: 22);
        }
        return const IconThemeData(color: AppColors.textGrey, size: 22);
      }),
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
    ),
    // FAB — Yellow
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.snapBlack,
      elevation: 2,
      shape: CircleBorder(),
    ),
    // Text — Nunito font
    textTheme: GoogleFonts.nunitoTextTheme(ThemeData.light().textTheme).apply(
      bodyColor: AppColors.textLight,
      displayColor: AppColors.textLight,
    ),
    // Input fields
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.inputBackground,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      hintStyle: GoogleFonts.nunito(color: AppColors.textGrey, fontSize: 15),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    // Elevated buttons — yellow
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.snapBlack,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w800),
        minimumSize: const Size(double.infinity, 52),
      ),
    ),
    // Dividers
    dividerTheme: const DividerThemeData(
      color: AppColors.dividerLight,
      thickness: 0.8,
    ),
    // Tab bar
    tabBarTheme: TabBarThemeData(
      labelColor: AppColors.snapBlack,
      unselectedLabelColor: AppColors.textGrey,
      indicatorColor: AppColors.primary,
      labelStyle: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 14),
      unselectedLabelStyle: GoogleFonts.nunito(fontWeight: FontWeight.w600, fontSize: 14),
    ),
    // Card
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
    ),
    // Chip
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.surfaceVariant,
      selectedColor: AppColors.primary,
      labelStyle: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w600),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    // ListTile
    listTileTheme: const ListTileThemeData(
      iconColor: AppColors.textGrey,
      tileColor: Colors.transparent,
    ),
    // Switch
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return AppColors.snapBlack;
        return Colors.white;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return AppColors.primary;
        return AppColors.dividerLight;
      }),
    ),
    // Snackbar
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.snapBlack,
      contentTextStyle: GoogleFonts.nunito(color: Colors.white, fontSize: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );

  // Force light — dark theme is identical to light
  static ThemeData darkTheme = lightTheme;
}
