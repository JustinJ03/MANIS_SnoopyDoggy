import 'package:material_ui/material_ui.dart';

/// MANIS design tokens, mirrored from the design system's tokens.json:
/// https://claude.ai/artifact/51o4DT1bqRRDKLkCcVkPXd
class ManisColors {
  const ManisColors({
    required this.surface,
    required this.surfaceRaised,
    required this.ink,
    required this.inkMuted,
    required this.line,
    required this.lineStrong,
    required this.blush,
    required this.inkOnBlush,
    required this.blushSoft,
    required this.action,
    required this.onAction,
    required this.wine,
    required this.rose,
    required this.success,
    required this.successSoft,
    required this.warning,
    required this.warningSoft,
    required this.danger,
    required this.dangerSoft,
  });

  final Color surface, surfaceRaised, ink, inkMuted, line, lineStrong;
  final Color blush, inkOnBlush, blushSoft, action, onAction, wine, rose;
  final Color success, successSoft, warning, warningSoft, danger, dangerSoft;

  static const light = ManisColors(
    surface: Color(0xFFFAF6F3),
    surfaceRaised: Color(0xFFFFFFFF),
    ink: Color(0xFF2B1A21),
    inkMuted: Color(0xFF6B5A60),
    line: Color(0xFFECE2DF),
    lineStrong: Color(0xFF94838A),
    blush: Color(0xFFF6C9D8),
    inkOnBlush: Color(0xFF2B1A21),
    blushSoft: Color(0xFFFBE4EC),
    action: Color(0xFF2B1A21),
    onAction: Color(0xFFFFFFFF),
    wine: Color(0xFF6E1F36),
    rose: Color(0xFFC0395F),
    success: Color(0xFF2E6A4C),
    successSoft: Color(0xFFE3F1E9),
    warning: Color(0xFF8A5300),
    warningSoft: Color(0xFFFBEFD9),
    danger: Color(0xFFA32639),
    dangerSoft: Color(0xFFFBE3E6),
  );

  static const dark = ManisColors(
    surface: Color(0xFF1C1418),
    surfaceRaised: Color(0xFF271C21),
    ink: Color(0xFFF6ECE9),
    inkMuted: Color(0xFFB9A9AE),
    line: Color(0xFF3A2C32),
    lineStrong: Color(0xFF7A6A70),
    blush: Color(0xFFEAA9C1),
    inkOnBlush: Color(0xFF2B1A21),
    blushSoft: Color(0xFF3D2631),
    action: Color(0xFFF6ECE9),
    onAction: Color(0xFF2B1A21),
    wine: Color(0xFFC25A78),
    rose: Color(0xFFF28AAB),
    success: Color(0xFF8FD3AE),
    successSoft: Color(0xFF1F3329),
    warning: Color(0xFFF2BD6B),
    warningSoft: Color(0xFF3A2C16),
    danger: Color(0xFFFF9AAA),
    dangerSoft: Color(0xFF40202A),
  );

  /// The token set for the current theme brightness.
  static ManisColors of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}

/// Spacing and radius tokens.
abstract final class ManisSpace {
  static const s1 = 4.0, s2 = 8.0, s3 = 12.0, s4 = 16.0, s6 = 24.0, s8 = 32.0;
}

abstract final class ManisRadius {
  static const sm = 12.0, md = 16.0, lg = 28.0, pill = 999.0;
}

// Bundled in assets/fonts (DM Sans 400/500/600, DM Serif Display 400) and
// declared in pubspec.yaml under these family names.
const _sans = 'DM Sans';
const _serif = 'DM Serif Display';
// No tabular figures: DM Sans's tnum also widens colons and spaces, which
// turns "10:00 AM" into "10 : 00  AM".

ThemeData manisTheme(Brightness brightness) {
  final c = brightness == Brightness.dark
      ? ManisColors.dark
      : ManisColors.light;
  TextStyle t(
    double size,
    double line,
    FontWeight w, {
    String family = _sans,
    Color? color,
    double spacing = 0,
  }) => TextStyle(
    fontFamily: family,
    fontSize: size,
    height: line / size,
    fontWeight: w,
    color: color ?? c.ink,
    letterSpacing: spacing,
  );

  final pill = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(ManisRadius.pill),
  );
  const buttonSize = Size(64, 48);
  final label = t(15, 18, FontWeight.w500);

  return ThemeData(
    // MANIS ships on iPhone/iPad only (PRODUCT.md); pinning iOS also makes
    // Windows dev runs and widget tests render what the iPhone shows.
    platform: TargetPlatform.iOS,
    // iOS has no ink ripple; taps show the pressed highlight instead.
    splashFactory: NoSplash.splashFactory,
    highlightColor: c.line.withValues(alpha: 0.6),
    brightness: brightness,
    fontFamily: _sans,
    scaffoldBackgroundColor: c.surface,
    colorScheme: ColorScheme(
      brightness: brightness,
      primary: c.action,
      onPrimary: c.onAction,
      secondary: c.blush,
      onSecondary: c.inkOnBlush,
      secondaryContainer: c.blushSoft,
      onSecondaryContainer: c.ink,
      tertiary: c.rose,
      onTertiary: c.surfaceRaised,
      error: c.danger,
      onError: c.surfaceRaised,
      errorContainer: c.dangerSoft,
      onErrorContainer: c.danger,
      surface: c.surfaceRaised,
      onSurface: c.ink,
      onSurfaceVariant: c.inkMuted,
      outline: c.lineStrong,
      outlineVariant: c.line,
    ),
    textTheme: TextTheme(
      displayMedium: t(
        40,
        42,
        FontWeight.w400,
        family: _serif,
        spacing: -0.4,
      ), // display
      headlineSmall: t(28, 32, FontWeight.w400, family: _serif), // title
      titleLarge: t(24, 28, FontWeight.w400, family: _serif), // price
      titleSmall: t(15, 20, FontWeight.w600), // heading
      // Text fields, list and switch rows. Without it Material's default
      // (16/24, +0.5 tracking) applies, off the token scale.
      bodyLarge: t(16, 22, FontWeight.w400), // input
      bodyMedium: t(14, 20, FontWeight.w400), // body
      labelLarge: t(14, 18, FontWeight.w500), // label
      // Status labels and tab labels; caption size at label weight.
      labelMedium: t(12, 16, FontWeight.w500), // label-sm
      bodySmall: t(12, 16, FontWeight.w400, color: c.inkMuted), // caption
      labelSmall: t(11, 14, FontWeight.w500, spacing: 2.64), // overline, 0.24em
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: c.surface,
      foregroundColor: c.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: c.action,
        foregroundColor: c.onAction,
        minimumSize: buttonSize,
        shape: pill,
        textStyle: label,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      // The blush "Book Appointment" pill.
      style: ElevatedButton.styleFrom(
        backgroundColor: c.blush,
        foregroundColor: c.inkOnBlush,
        elevation: 0,
        minimumSize: buttonSize,
        shape: pill,
        textStyle: label,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: c.ink,
        side: BorderSide(color: c.lineStrong),
        minimumSize: buttonSize,
        shape: pill,
        textStyle: label,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: c.ink, shape: pill),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: c.surfaceRaised,
      selectedColor: c.blush,
      labelStyle: t(14, 18, FontWeight.w500),
      secondaryLabelStyle: t(14, 18, FontWeight.w500, color: c.inkOnBlush),
      side: BorderSide(color: c.line),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ManisRadius.sm),
      ),
      showCheckmark: false,
    ),
    cardTheme: CardThemeData(
      color: c.surfaceRaised,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ManisRadius.md),
        side: BorderSide(color: c.line),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.surfaceRaised,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(ManisRadius.sm),
        borderSide: BorderSide(color: c.lineStrong),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(ManisRadius.sm),
        borderSide: BorderSide(color: c.lineStrong),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(ManisRadius.sm),
        borderSide: BorderSide(color: c.action, width: 2),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(ManisRadius.lg),
        ),
      ),
    ),
    dividerTheme: DividerThemeData(color: c.line, thickness: 1),
  );
}
