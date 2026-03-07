import 'package:flutter/material.dart';

class LunaraThemeExtension extends ThemeExtension<LunaraThemeExtension> {
  // Cycle Phase Colors (Remains constant across themes usually, but could tweak)
  final Color periodRed;
  final Color fertileGreen;
  final Color ovulationBlue;
  final Color lutealPurple;
  final Color follicularTeal;

  // Custom Backgrounds
  final Color backgroundPink;
  final Color backgroundLavender;

  // Gradients
  final LinearGradient primaryGradient;
  final LinearGradient backgroundGradient;
  final LinearGradient softBackground;

  // Shadows
  final List<BoxShadow> softShadow;
  final List<BoxShadow> glowShadow;

  const LunaraThemeExtension({
    required this.periodRed,
    required this.fertileGreen,
    required this.ovulationBlue,
    required this.lutealPurple,
    required this.follicularTeal,
    required this.backgroundPink,
    required this.backgroundLavender,
    required this.primaryGradient,
    required this.backgroundGradient,
    required this.softBackground,
    required this.softShadow,
    required this.glowShadow,
  });

  @override
  ThemeExtension<LunaraThemeExtension> copyWith() {
    return this; // Keep simple for now
  }

  @override
  ThemeExtension<LunaraThemeExtension> lerp(
      ThemeExtension<LunaraThemeExtension>? other, double t) {
    if (other is! LunaraThemeExtension) return this;
    return LunaraThemeExtension(
      periodRed: Color.lerp(periodRed, other.periodRed, t)!,
      fertileGreen: Color.lerp(fertileGreen, other.fertileGreen, t)!,
      ovulationBlue: Color.lerp(ovulationBlue, other.ovulationBlue, t)!,
      lutealPurple: Color.lerp(lutealPurple, other.lutealPurple, t)!,
      follicularTeal: Color.lerp(follicularTeal, other.follicularTeal, t)!,
      backgroundPink: Color.lerp(backgroundPink, other.backgroundPink, t)!,
      backgroundLavender:
          Color.lerp(backgroundLavender, other.backgroundLavender, t)!,
      primaryGradient:
          LinearGradient.lerp(primaryGradient, other.primaryGradient, t)!,
      backgroundGradient:
          LinearGradient.lerp(backgroundGradient, other.backgroundGradient, t)!,
      softBackground:
          LinearGradient.lerp(softBackground, other.softBackground, t)!,
      softShadow: BoxShadow.lerpList(softShadow, other.softShadow, t)!,
      glowShadow: BoxShadow.lerpList(glowShadow, other.glowShadow, t)!,
    );
  }
}

class AppTheme {
  // ─── STATIC HELPER METHODS FOR EASY MIGRATION ────────────────────────────
  // We define dynamic getters so UI components don't require massive rewrites.

  static Color primary(BuildContext context) =>
      Theme.of(context).colorScheme.primary;
  static Color background(BuildContext context) =>
      Theme.of(context).colorScheme.surface;
  static Color textDark(BuildContext context) =>
      Theme.of(context).colorScheme.onSurface;
  static Color textLight(BuildContext context) =>
      Theme.of(context).colorScheme.onSurfaceVariant;
  static Color textBrown(BuildContext context) =>
      Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.8);
  static Color divider(BuildContext context) =>
      Theme.of(context).colorScheme.outlineVariant;

  // Semantic Surface Colors
  static Color cardColor(BuildContext context) =>
      Theme.of(context).colorScheme.surfaceContainerHighest;
  static Color subtleBackground(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light
          ? const Color(0xFFFCE4EC)
          : const Color(0xFF2A1525);

  // Shimmer Loading Colors
  static Color shimmerBase(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light
          ? Colors.grey.shade300
          : Colors.grey.shade700;
  static Color shimmerHighlight(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light
          ? Colors.grey.shade100
          : Colors.grey.shade600;

  // Custom Extensions Accessors
  static LunaraThemeExtension _ext(BuildContext context) =>
      Theme.of(context).extension<LunaraThemeExtension>()!;

  static Color periodRed(BuildContext context) => _ext(context).periodRed;
  static Color fertileGreen(BuildContext context) => _ext(context).fertileGreen;
  static Color ovulationBlue(BuildContext context) =>
      _ext(context).ovulationBlue;
  static Color lutealPurple(BuildContext context) => _ext(context).lutealPurple;
  static Color follicularTeal(BuildContext context) =>
      _ext(context).follicularTeal;

  static Color backgroundPink(BuildContext context) =>
      _ext(context).backgroundPink;

  static LinearGradient primaryGradient(BuildContext context) =>
      _ext(context).primaryGradient;
  static LinearGradient backgroundGradient(BuildContext context) =>
      _ext(context).backgroundGradient;
  static LinearGradient softBackground(BuildContext context) =>
      _ext(context).softBackground;

  static List<BoxShadow> softShadow(BuildContext context) =>
      _ext(context).softShadow;
  static List<BoxShadow> glowShadow(BuildContext context) =>
      _ext(context).glowShadow;

  // ─── LIGHT THEME ────────────────────────────
  static ThemeData get lightTheme {
    const primary = Color(0xFFFF8989);
    const primaryDark = Color(0xFFD8405B);
    const background = Color(0xFFFDFBF7);

    return ThemeData(
      brightness: Brightness.light,
      primaryColor: primary,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: primaryDark,
        surface: background,
        onSurface: Color(0xFF3E2723), // textDark
        onSurfaceVariant: Color(0xFF8D6E63), // textLight
        outlineVariant: Color(0xFFEEEEEE), // divider
        error: Color(0xFFEF5350),
        surfaceContainerHighest: Colors.white, // Cards
      ),
      extensions: [
        LunaraThemeExtension(
          periodRed: const Color(0xFFFF8989),
          fertileGreen: const Color(0xFF81C784),
          ovulationBlue: const Color(0xFF64B5F6),
          lutealPurple: const Color(0xFFCE93D8),
          follicularTeal: const Color(0xFF4DB6AC),
          backgroundPink: const Color(0xFFF8BBD0),
          backgroundLavender: const Color(0xFFF3E5F5),
          primaryGradient: const LinearGradient(colors: [primary, primaryDark]),
          backgroundGradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFCE4EC), Color(0xFFF8BBD0), Color(0xFFF3E5F5)],
          ),
          softBackground: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFFCE4EC).withOpacity(0.4),
              const Color(0xFFF8BBD0).withOpacity(0.3),
              background,
            ],
          ),
          softShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 15,
              offset: const Offset(0, 3),
            ),
          ],
          glowShadow: [
            BoxShadow(
              color: primary.withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
      ],
    );
  }

  // ─── DARK THEME ────────────────────────────
  static ThemeData get darkTheme {
    const primary = Color(0xFFFF7A8A); // Slightly brighter for dark mode
    const primaryDark = Color(0xFFC2185B);
    const background = Color(0xFF121212); // Deep premium slate
    const cardColor = Color(0xFF1E1E1E);

    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primary,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: primaryDark,
        surface: background,
        onSurface: Color(0xFFF5F5F5), // Light text
        onSurfaceVariant: Color(0xFFAAAAAA), // Muted text
        outlineVariant: Color(0xFF333333), // Darker dividers
        error: Color(0xFFEF5350),
        surfaceContainerHighest: cardColor, // Dark cards
      ),
      extensions: [
        LunaraThemeExtension(
          periodRed: const Color(0xFFEF5350), // Deeper red
          fertileGreen: const Color(0xFF66BB6A),
          ovulationBlue: const Color(0xFF42A5F5),
          lutealPurple: const Color(0xFFAB47BC),
          follicularTeal: const Color(0xFF26A69A),
          backgroundPink: const Color(0xFF3E2723), // Muted dark warm background
          backgroundLavender: const Color(0xFF311B92).withOpacity(0.3),
          primaryGradient: const LinearGradient(colors: [primary, primaryDark]),
          backgroundGradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2A1525), Color(0xFF1A121A), background],
          ),
          softBackground: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF2A1525).withOpacity(0.4),
              const Color(0xFF1A121A).withOpacity(0.3),
              background,
            ],
          ),
          softShadow: [
            BoxShadow(
              color: Colors.black
                  .withOpacity(0.3), // Stronger shadow for dark mode
              blurRadius: 15,
              offset: const Offset(0, 3),
            ),
          ],
          glowShadow: [
            BoxShadow(
              color: primary.withOpacity(0.2), // Softer glow
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
      ],
    );
  }
}

// ──────────────────────────── RADII ──────────────────────────────
class LunaraRadius {
  LunaraRadius._();
  static const double sm = 12;
  static const double md = 18;
  static const double lg = 22;
  static const double xl = 28;
}

// ──────────────────────────── BACKWARD-COMPAT HELPERS ──────────────────────────
// These provide static color/gradient/shadow constants so older screens
// (insights_screen, etc.) keep compiling while the full migration to
// context-aware AppTheme accessors is completed later.

class LunaraColors {
  LunaraColors._();

  static const Color primary = Color(0xFFFF8989);
  static const Color primaryLight = Color(0xFFFCE4EC);
  static const Color primaryDark = Color(0xFFD8405B);
  static const Color background = Color(0xFFFDFBF7);
  static const Color backgroundPink = Color(0xFFF8BBD0);
  static const Color textDark = Color(0xFF3E2723);
  static const Color textLight = Color(0xFF8D6E63);
  static const Color textBrown = Color(0xFF8D6E63);
  static const Color divider = Color(0xFFEEEEEE);
  static const Color warning = Color(0xFFFFB74D);

  // Cycle phase colors
  static const Color periodRed = Color(0xFFFF8989);
  static const Color fertileGreen = Color(0xFF81C784);
  static const Color ovulationBlue = Color(0xFF64B5F6);
  static const Color lutealPurple = Color(0xFFCE93D8);
  static const Color follicularTeal = Color(0xFF4DB6AC);
}

class LunaraShadows {
  LunaraShadows._();

  static final List<BoxShadow> soft = [
    BoxShadow(
      color: Colors.black.withOpacity(0.06),
      blurRadius: 15,
      offset: const Offset(0, 3),
    ),
  ];

  static final List<BoxShadow> glow = [
    BoxShadow(
      color: const Color(0xFFFF8989).withOpacity(0.4),
      blurRadius: 15,
      offset: const Offset(0, 5),
    ),
  ];
}

class LunaraGradients {
  LunaraGradients._();

  static const LinearGradient primary = LinearGradient(
    colors: [Color(0xFFFF8989), Color(0xFFD8405B)],
  );
}
