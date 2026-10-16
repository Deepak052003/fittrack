import 'package:flutter/material.dart';

const obsidian = Color(0xFF0B132B);
const coral = Color(0xFFFF6B35);
const coralLight = Color(0xFFFF8C61);
const iceBlue = Color(0xFF7AA2FF);
const caloriesOrange = coralLight;

/// Accent for rings, timers and main buttons.
const coralGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [coral, coralLight],
);

/// Frosted card fill and its 1px edge.
Color glassFill(BuildContext context) =>
    _isDark(context) ? const Color(0x12FFFFFF) : Colors.white;
Color glassEdge(BuildContext context) =>
    _isDark(context) ? const Color(0x1FFFFFFF) : const Color(0x140B132B);

bool _isDark(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark;

// Must match web/index.html and web/manifest.json.
const _darkScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: coral,
  onPrimary: obsidian,
  primaryContainer: Color(0xFF3A2430),
  onPrimaryContainer: Color(0xFFFFB59A),
  secondary: coralLight,
  onSecondary: obsidian,
  secondaryContainer: Color(0xFF3A2430),
  onSecondaryContainer: Color(0xFFFFB59A),
  tertiary: iceBlue,
  onTertiary: obsidian,
  error: Color(0xFFFF5C7A),
  onError: obsidian,
  surface: obsidian,
  onSurface: Color(0xFFEEF1FA),
  onSurfaceVariant: Color(0xFF8B95AD),
  surfaceContainerLowest: Color(0xFF080E22),
  surfaceContainerLow: Color(0xFF0F1833),
  surfaceContainer: Color(0xFF131D3B),
  surfaceContainerHigh: Color(0xFF182344),
  surfaceContainerHighest: Color(0xFF1E2A4D),
  outline: Color(0xFF3A4566),
  outlineVariant: Color(0xFF243052),
  inverseSurface: Color(0xFFEEF1FA),
  onInverseSurface: obsidian,
  inversePrimary: Color(0xFFC2410C),
  shadow: Colors.black,
  scrim: Colors.black,
  surfaceTint: Colors.transparent,
);

const _lightScheme = ColorScheme(
  brightness: Brightness.light,
  primary: coral,
  onPrimary: obsidian,
  primaryContainer: Color(0xFFFFE3D8),
  onPrimaryContainer: Color(0xFF7A2A0E),
  secondary: coralLight,
  onSecondary: obsidian,
  secondaryContainer: Color(0xFFFFE3D8),
  onSecondaryContainer: Color(0xFF7A2A0E),
  tertiary: Color(0xFF3D5AFE),
  onTertiary: Colors.white,
  error: Color(0xFFD92D4F),
  onError: Colors.white,
  surface: Color(0xFFF4F5F9),
  onSurface: obsidian,
  onSurfaceVariant: Color(0xFF5B6478),
  surfaceContainerLowest: Colors.white,
  surfaceContainerLow: Color(0xFFF9FAFC),
  surfaceContainer: Color(0xFFEEF0F5),
  surfaceContainerHigh: Color(0xFFE8EBF1),
  surfaceContainerHighest: Color(0xFFE1E5ED),
  outline: Color(0xFFC3C9D6),
  outlineVariant: Color(0xFFE2E5EC),
  inverseSurface: obsidian,
  onInverseSurface: Color(0xFFEEF1FA),
  inversePrimary: coralLight,
  shadow: Colors.black,
  scrim: Colors.black,
  surfaceTint: Colors.transparent,
);

final lightTheme = _buildTheme(_lightScheme);
final darkTheme = _buildTheme(_darkScheme);

ThemeData _buildTheme(ColorScheme scheme) {
  final dark = scheme.brightness == Brightness.dark;
  final fill = dark ? const Color(0x12FFFFFF) : Colors.white;
  final edge = dark ? const Color(0x1FFFFFFF) : const Color(0x140B132B);
  // Coral text is too light on white, so links get a deeper shade there.
  final link = dark ? coral : const Color(0xFFC2410C);
  final base = ThemeData(colorScheme: scheme, fontFamily: 'Inter');
  final text = base.textTheme;

  return base.copyWith(
    scaffoldBackgroundColor: scheme.surface,
    textTheme: text.copyWith(
      displayLarge: text.displayLarge?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -2,
      ),
      displayMedium: text.displayMedium?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -1.5,
      ),
      displaySmall: text.displaySmall?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -1,
      ),
      headlineMedium: text.headlineMedium?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.8,
      ),
      headlineSmall: text.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
      titleLarge: text.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
      titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      // No titleTextStyle here: it would override white titles on colored bars.
    ),
    cardTheme: CardThemeData(
      color: fill,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: edge),
      ),
    ),
    dividerTheme: DividerThemeData(color: edge, thickness: 1),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: dark ? const Color(0xB30B132B) : const Color(0xE6FFFFFF),
      elevation: 0,
      indicatorColor: coral.withValues(alpha: 0.16),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? coral
              : scheme.onSurfaceVariant,
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => text.labelMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: states.contains(WidgetState.selected)
              ? scheme.onSurface
              : scheme.onSurfaceVariant,
        ),
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: Colors.transparent,
      indicatorColor: coral.withValues(alpha: 0.16),
      selectedIconTheme: const IconThemeData(color: coral),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: const StadiumBorder(),
        textStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: const StadiumBorder(),
        foregroundColor: scheme.onSurface,
        side: BorderSide(color: edge.withValues(alpha: dark ? 0.3 : 0.2)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: link),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: coral,
      foregroundColor: obsidian,
    ),
    chipTheme: ChipThemeData(
      shape: const StadiumBorder(),
      side: BorderSide(color: edge),
      backgroundColor: fill,
      selectedColor: coral.withValues(alpha: 0.18),
      showCheckmark: false,
      labelStyle: TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w600,
        color: WidgetStateColor.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? link
              : scheme.onSurfaceVariant,
        ),
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? coral.withValues(alpha: 0.18)
              : fill,
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? link
              : scheme.onSurfaceVariant,
        ),
        side: WidgetStatePropertyAll(BorderSide(color: edge)),
      ),
    ),
    inputDecorationTheme: InputDecorationThemeData(
      filled: true,
      fillColor: fill,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: edge),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: edge),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: coral, width: 1.5),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: dark ? const Color(0xFF131D3B) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: BorderSide(color: edge),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: dark ? const Color(0xFF101935) : Colors.white,
      dragHandleColor: scheme.onSurfaceVariant.withValues(alpha: 0.4),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: dark ? const Color(0xFF18233F) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: edge),
      ),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: coral,
      linearTrackColor: edge,
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}
