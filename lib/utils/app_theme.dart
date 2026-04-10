import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors
  static const Color primaryColor = Color(0xFF6C63FF);
  static const Color primaryLight = Color(0xFF9C97FF);
  static const Color primaryDark = Color(0xFF4A42D8);
  static const Color accentColor = Color(0xFF00D9C5);
  static const Color dangerColor = Color(0xFFFF4D6D);
  static const Color warningColor = Color(0xFFFFB347);
  static const Color successColor = Color(0xFF43E97B);

  // Dark Theme
  static const Color darkBg = Color(0xFF0F0F17);
  static const Color darkSurface = Color(0xFF1A1A2E);
  static const Color darkCard = Color(0xFF16213E);
  static const Color darkBorder = Color(0xFF2A2A45);
  static const Color darkTextPrimary = Color(0xFFF0F0FF);
  static const Color darkTextSecondary = Color(0xFF8888AA);

  // Light Theme
  static const Color lightBg = Color(0xFFF5F5FF);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFF0F0FF);
  static const Color lightBorder = Color(0xFFE0E0F0);
  static const Color lightTextPrimary = Color(0xFF1A1A2E);
  static const Color lightTextSecondary = Color(0xFF6666AA);

  static ThemeData darkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: accentColor,
        surface: darkSurface,
        background: darkBg,
        error: dangerColor,
        onPrimary: Colors.white,
        onSurface: darkTextPrimary,
        onBackground: darkTextPrimary,
      ),
      scaffoldBackgroundColor: darkBg,
      textTheme: GoogleFonts.spaceGroteskTextTheme().copyWith(
        displayLarge: GoogleFonts.spaceGrotesk(
          color: darkTextPrimary,
          fontWeight: FontWeight.w700,
          letterSpacing: -1,
        ),
        displayMedium: GoogleFonts.spaceGrotesk(
          color: darkTextPrimary,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: GoogleFonts.spaceGrotesk(
          color: darkTextPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 20,
        ),
        titleMedium: GoogleFonts.spaceGrotesk(
          color: darkTextPrimary,
          fontWeight: FontWeight.w500,
          fontSize: 16,
        ),
        bodyLarge: GoogleFonts.inter(color: darkTextPrimary, fontSize: 16),
        bodyMedium: GoogleFonts.inter(color: darkTextSecondary, fontSize: 14),
        bodySmall: GoogleFonts.inter(color: darkTextSecondary, fontSize: 12),
        labelSmall: GoogleFonts.inter(
          color: darkTextSecondary,
          fontSize: 11,
          letterSpacing: 0.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: darkBorder, width: 1),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: darkBg,
        elevation: 0,
        iconTheme: const IconThemeData(color: darkTextPrimary),
        titleTextStyle: GoogleFonts.spaceGrotesk(
          color: darkTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        hintStyle: GoogleFonts.inter(color: darkTextSecondary, fontSize: 14),
        labelStyle: GoogleFonts.inter(color: darkTextSecondary, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: darkSurface,
        selectedColor: primaryColor.withOpacity(0.2),
        labelStyle: GoogleFonts.inter(color: darkTextPrimary, fontSize: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: const BorderSide(color: darkBorder),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: darkCard,
        modalBackgroundColor: darkCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      dividerTheme: const DividerThemeData(color: darkBorder, thickness: 1),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: darkCard,
        contentTextStyle: GoogleFonts.inter(color: darkTextPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static ThemeData lightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: accentColor,
        surface: lightSurface,
        background: lightBg,
        error: dangerColor,
        onPrimary: Colors.white,
        onSurface: lightTextPrimary,
        onBackground: lightTextPrimary,
      ),
      scaffoldBackgroundColor: lightBg,
      textTheme: GoogleFonts.spaceGroteskTextTheme().copyWith(
        displayLarge: GoogleFonts.spaceGrotesk(
          color: lightTextPrimary,
          fontWeight: FontWeight.w700,
        ),
        titleLarge: GoogleFonts.spaceGrotesk(
          color: lightTextPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 20,
        ),
        bodyMedium: GoogleFonts.inter(color: lightTextSecondary, fontSize: 14),
      ),
      cardTheme: CardThemeData(
        color: lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: lightBorder, width: 1),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: lightBg,
        elevation: 0,
        iconTheme: const IconThemeData(color: lightTextPrimary),
        titleTextStyle: GoogleFonts.spaceGrotesk(
          color: lightTextPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        hintStyle: GoogleFonts.inter(color: lightTextSecondary, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: lightCard,
        selectedColor: primaryColor.withOpacity(0.15),
        labelStyle: GoogleFonts.inter(color: lightTextPrimary, fontSize: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: const BorderSide(color: lightBorder),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dividerTheme: const DividerThemeData(color: lightBorder, thickness: 1),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: lightSurface,
        contentTextStyle: GoogleFonts.inter(color: lightTextPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Tag colors
  static final List<Color> tagColors = [
    const Color(0xFF6C63FF),
    const Color(0xFF00D9C5),
    const Color(0xFFFF6B9D),
    const Color(0xFFFFB347),
    const Color(0xFF43E97B),
    const Color(0xFF4ECDC4),
    const Color(0xFFA29BFE),
    const Color(0xFFFF7675),
    const Color(0xFF74B9FF),
    const Color(0xFFFF9F43),
  ];

  static Color tagColor(String tag) {
    final index = tag.hashCode.abs() % tagColors.length;
    return tagColors[index];
  }

  // Category icons
  static IconData categoryIcon(String? category) {
    switch (category?.toLowerCase()) {
      case 'dev':
      case 'development':
        return Icons.code_rounded;
      case 'design':
        return Icons.palette_rounded;
      case 'article':
      case 'blog':
        return Icons.article_rounded;
      case 'video':
        return Icons.play_circle_rounded;
      case 'social':
        return Icons.people_rounded;
      case 'news':
        return Icons.newspaper_rounded;
      case 'docs':
      case 'documentation':
        return Icons.description_rounded;
      case 'research':
        return Icons.science_rounded;
      case 'shopping':
        return Icons.shopping_bag_rounded;
      case 'music':
        return Icons.music_note_rounded;
      case 'entertainment':
        return Icons.movie_rounded;
      case 'reference':
        return Icons.menu_book_rounded;
      case 'work':
        return Icons.work_rounded;
      case 'personal':
        return Icons.person_rounded;
      case 'tools':
        return Icons.build_rounded;
      default:
        return Icons.folder_rounded;
    }
  }
}
