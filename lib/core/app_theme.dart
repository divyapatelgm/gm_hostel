import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Official GM Group of Hostel app theme.
/// Light theme: clear white background, primary #5b1f1f, accent #e2b458.
class AppTheme {
  AppTheme._();

  static const Color primary = Color(0xFF5b1f1f);
  static const Color accent = Color(0xFFe2b458);
  static const Color background = Colors.white;
  static const Color surface = Color(0xFFF8F8F8);
  static const Color onPrimary = Colors.white;
  static const Color onBackground = Color(0xFF1a1a1a);
  static const Color muted = Color(0xFF6b6b6b);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: accent,
        surface: surface,
        onPrimary: onPrimary,
        onSurface: onBackground,
        onSecondary: onBackground,
      ),
      // Apply Google Fonts to the entire TextTheme
      textTheme: GoogleFonts.poppinsTextTheme().copyWith(
        displayLarge: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: onBackground),
        displayMedium: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: onBackground),
        titleLarge: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: onBackground),
        bodyLarge: GoogleFonts.poppins(color: onBackground),
        bodyMedium: GoogleFonts.poppins(color: onBackground),
      ),
      appBarTheme: AppBarTheme(
        titleTextStyle: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
        backgroundColor: primary,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: background,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary),
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
        hintStyle: GoogleFonts.poppins(color: Colors.grey, fontSize: 14),
        labelStyle: GoogleFonts.poppins(color: onBackground, fontSize: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  static PreferredSizeWidget appBar(BuildContext context, {String? title}) {
    return AppBar(
      title: Text(
        title ?? 'GM Group of Hostel',
        style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 18),
      ),
      backgroundColor: primary,
      foregroundColor: Colors.white,
      iconTheme: const IconThemeData(color: Colors.white),
      elevation: 0,
      centerTitle: true,
    );
  }
}
