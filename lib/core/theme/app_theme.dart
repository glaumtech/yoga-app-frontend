import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Instant route changes (no slide/fade) for sidebar and other navigation.
class NoAnimationPageTransitionsBuilder extends PageTransitionsBuilder {
  const NoAnimationPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}

const PageTransitionsTheme _noAnimationPageTransitions = PageTransitionsTheme(
  builders: {
    TargetPlatform.android: NoAnimationPageTransitionsBuilder(),
    TargetPlatform.iOS: NoAnimationPageTransitionsBuilder(),
    TargetPlatform.linux: NoAnimationPageTransitionsBuilder(),
    TargetPlatform.macOS: NoAnimationPageTransitionsBuilder(),
    TargetPlatform.windows: NoAnimationPageTransitionsBuilder(),
    TargetPlatform.fuchsia: NoAnimationPageTransitionsBuilder(),
  },
);

/// Static neutral palette — does not change per role.
/// Use [AppTheme] for role-based accent, button, and tinted colours.
class AppColors {
  AppColors._();

  // Backgrounds & surfaces
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Colors.white;
  static const Color surfaceAlt = Color(0xFFFAFAFA);
  static const Color panelBackground = Color(0xFFF5F5F5);

  // Text
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF424242);
  static const Color textBody = Color(0xFF333333);
  static const Color textMuted = Color(0xFF616161);
  static const Color textHint = Color(0xFF757575);
  static const Color textDisabled = Color(0xFFBDBDBD);
  static const Color textOnAccent = Colors.white;

  // Borders & dividers
  static const Color border = Color(0xFFE0E0E0);
  static const Color borderLight = Color(0xFFEEEEEE);
  static const Color divider = Color(0xFFEEEEEE);

  // Table / list
  static const Color rowAlt = Color(0xFFFAFAFA);
  static const Color chipBackground = Color(0xFFEEEEEE);
  static const Color chipBorder = Color(0xFFBDBDBD);

  // Input
  static const Color inputFill = Color(0xFFFAFAFA);

  // Status
  static const Color error = Colors.red;
  static const Color warning = Color(0xFFE65100);
}

/// Central theme — role accent colour and reusable semantic tokens.
/// All screens should import this file and use [AppColors] / [AppTheme] getters.
class AppTheme {
  AppTheme._();

  /// Branch admin default — yoga green.
  static const Color defaultPrimaryColor = Color(0xFF4CAF50);

  /// Active role accent; updated on login from {@code user_types.theme_color}.
  static Color primaryColor = defaultPrimaryColor;

  // ── Role accent (changes per logged-in role) ──────────────────────────────

  static Color get accent => primaryColor;

  static Color secondaryColorFor(Color primary) =>
      Color.lerp(primary, Colors.white, 0.35) ?? const Color(0xFF81C784);

  static Color get secondaryColor => secondaryColorFor(primaryColor);

  static Color accentSoft([double alpha = 0.08]) =>
      primaryColor.withValues(alpha: alpha);

  static Color accentBorder([double alpha = 0.25]) =>
      primaryColor.withValues(alpha: alpha);

  static Color accentHover([double alpha = 0.12]) =>
      primaryColor.withValues(alpha: alpha);

  // ── Buttons ───────────────────────────────────────────────────────────────

  static Color get buttonBackground => primaryColor;
  static Color get buttonForeground => AppColors.textOnAccent;
  static Color get buttonOutlinedForeground => primaryColor;
  static Color get buttonOutlinedBorder => primaryColor;
  static Color get buttonTextForeground => primaryColor;
  static Color get buttonDisabledBackground => AppColors.chipBackground;
  static Color get buttonDisabledForeground => AppColors.textDisabled;

  static ButtonStyle get elevatedButtonStyle => ElevatedButton.styleFrom(
        backgroundColor: buttonBackground,
        foregroundColor: buttonForeground,
        disabledBackgroundColor: buttonDisabledBackground,
        disabledForegroundColor: buttonDisabledForeground,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      );

  static ButtonStyle get outlinedButtonStyle => OutlinedButton.styleFrom(
        foregroundColor: buttonOutlinedForeground,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: BorderSide(color: buttonOutlinedBorder, width: 2),
        textStyle: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      );

  static ButtonStyle get textButtonStyle => TextButton.styleFrom(
        foregroundColor: buttonTextForeground,
        textStyle: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      );

  // ── Text (role-aware where noted) ─────────────────────────────────────────

  static Color get textPrimary => AppColors.textPrimary;
  static Color get textSecondary => AppColors.textSecondary;
  static Color get textBody => AppColors.textBody;
  static Color get textMuted => AppColors.textMuted;
  static Color get textHint => AppColors.textHint;
  static Color get link => primaryColor;
  static Color get textOnAccent => AppColors.textOnAccent;

  // ── Backgrounds & surfaces ────────────────────────────────────────────────

  static Color get background => AppColors.background;
  static Color get surface => AppColors.surface;
  static Color get surfaceAlt => AppColors.surfaceAlt;
  static Color get panelBackground => AppColors.panelBackground;
  static Color get rowAlt => AppColors.rowAlt;

  // ── Borders ───────────────────────────────────────────────────────────────

  static Color get border => AppColors.border;
  static Color get borderLight => AppColors.borderLight;
  static Color get divider => AppColors.divider;

  // ── Headers & sections (tinted with role colour) ──────────────────────────

  static Color sectionHeaderBackground([Color? primary]) =>
      tintedHeaderBackground(primary);

  static Color sectionHeaderText([Color? primary]) => tintedHeaderText(primary);

  /// Light header/section background tinted with the active role colour.
  static Color tintedHeaderBackground([Color? primary]) {
    final p = primary ?? primaryColor;
    return Color.alphaBlend(p.withValues(alpha: 0.14), Colors.white);
  }

  /// Header/section title text on tinted surfaces.
  static Color tintedHeaderText([Color? primary]) {
    final p = primary ?? primaryColor;
    return Color.lerp(p, AppColors.textPrimary, 0.42) ?? p;
  }

  // ── Chips & badges ──────────────────────────────────────────────────────

  static Color chipTintBackground([Color? primary]) => softTintSurface(primary);
  static Color chipTintText([Color? primary]) => softTintText(primary);
  static Color get chipNeutralBackground => AppColors.chipBackground;
  static Color get chipNeutralText => AppColors.textSecondary;
  static Color get chipNeutralBorder => AppColors.chipBorder;

  /// Soft chip/badge background derived from theme.
  static Color softTintSurface([Color? primary]) {
    final p = primary ?? primaryColor;
    return Color.alphaBlend(p.withValues(alpha: 0.09), Colors.white);
  }

  /// Text on soft tint chips/badges.
  static Color softTintText([Color? primary]) {
    final p = primary ?? primaryColor;
    return Color.lerp(p, AppColors.textPrimary, 0.28) ?? p;
  }

  // ── Icons & interactive ───────────────────────────────────────────────────

  static Color get iconAccent => primaryColor;
  static Color get iconMuted => AppColors.textHint;
  static Color get iconDisabled => AppColors.textDisabled;

  // ── Legacy aliases (prefer semantic getters above) ────────────────────────

  @Deprecated('Use AppTheme.background')
  static const Color backgroundColor = AppColors.background;

  @Deprecated('Use AppTheme.textBody')
  static const Color textColor = AppColors.textBody;

  @Deprecated('Use AppTheme.accentSoft()')
  static Color get accentColor =>
      Color.alphaBlend(primaryColor.withValues(alpha: 0.2), Colors.white);

  // ── Parsing & theme building ──────────────────────────────────────────────

  static Color? parseHexColor(String? hex) {
    if (hex == null) return null;
    var value = hex.trim();
    if (value.isEmpty) return null;
    if (value.startsWith('#')) value = value.substring(1);
    if (value.length == 6) value = 'FF$value';
    final parsed = int.tryParse(value, radix: 16);
    if (parsed == null) return null;
    return Color(parsed);
  }

  static ThemeData get lightTheme => buildLightTheme(primaryColor);
  static ThemeData get darkTheme => buildDarkTheme(primaryColor);

  static ThemeData buildLightTheme(Color primary) {
    final secondary = secondaryColorFor(primary);
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: primary,
        secondary: secondary,
        surface: AppColors.surface,
        error: AppColors.error,
        onPrimary: AppColors.textOnAccent,
        onSecondary: AppColors.textOnAccent,
        onSurface: AppColors.textBody,
        onError: AppColors.textOnAccent,
      ),
      scaffoldBackgroundColor: AppColors.background,
      textTheme: GoogleFonts.poppinsTextTheme().copyWith(
        displayLarge: GoogleFonts.poppins(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: AppColors.textBody,
        ),
        displayMedium: GoogleFonts.poppins(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: AppColors.textBody,
        ),
        displaySmall: GoogleFonts.poppins(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: AppColors.textBody,
        ),
        headlineMedium: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textBody,
        ),
        titleLarge: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textBody,
        ),
        titleMedium: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.textBody,
        ),
        bodyLarge: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: AppColors.textBody,
        ),
        bodyMedium: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: AppColors.textBody,
        ),
        bodySmall: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: AppColors.textBody,
        ),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: primary,
        foregroundColor: AppColors.textOnAccent,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textOnAccent,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: AppColors.surface,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: AppColors.inputFill,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: elevatedButtonStyle.copyWith(
          backgroundColor: WidgetStatePropertyAll(primary),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: outlinedButtonStyle.copyWith(
          foregroundColor: WidgetStatePropertyAll(primary),
          side: WidgetStatePropertyAll(BorderSide(color: primary, width: 2)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: textButtonStyle.copyWith(
          foregroundColor: WidgetStatePropertyAll(primary),
        ),
      ),
      pageTransitionsTheme: _noAnimationPageTransitions,
    );
  }

  static ThemeData buildDarkTheme(Color primary) {
    final secondary = secondaryColorFor(primary);
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        surface: const Color(0xFF1E1E1E),
        error: AppColors.error,
        onPrimary: AppColors.textOnAccent,
        onSecondary: AppColors.textOnAccent,
        onSurface: Colors.white,
        onError: AppColors.textOnAccent,
      ),
      scaffoldBackgroundColor: const Color(0xFF121212),
      textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: const Color(0xFF1E1E1E),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: const Color(0xFF2C2C2C),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      pageTransitionsTheme: _noAnimationPageTransitions,
    );
  }
}
