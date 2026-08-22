import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Aster's visual language: one seed color, two schemes, shared shape and
/// component styling so every surface in the app agrees.
abstract final class AppTheme {
  /// Brand seed — a deep violet that reads well in both schemes.
  static const Color seed = Color(0xFF6C4DF6);

  static const Color accent = Color(0xFFFF7A5A);
  static const Color success = Color(0xFF1E9E6A);

  static const double radiusSm = 12;
  static const double radiusMd = 18;
  static const double radiusLg = 28;

  /// Contrast level asked of [ColorScheme.fromSeed] when the OS reports that
  /// the shopper wants high contrast. 1.0 is the top of the Material scale.
  static const double _highContrastLevel = 1.0;

  /// Light theme. [dynamicScheme] wins when the platform supplies one;
  /// otherwise the scheme is derived from [seedColor] (a preset, or the brand
  /// seed by default).
  ///
  /// [highContrast] pulls the pairs further apart — see [_scheme].
  static ThemeData light(
    ColorScheme? dynamicScheme, {
    Color? seedColor,
    bool highContrast = false,
  }) => _build(
    _scheme(
      dynamicScheme,
      seedColor: seedColor,
      brightness: Brightness.light,
      highContrast: highContrast,
    ),
  );

  /// Dark theme. With [amoled] the surfaces collapse to true black so OLED
  /// panels can switch those pixels off entirely.
  static ThemeData dark(
    ColorScheme? dynamicScheme, {
    bool amoled = false,
    Color? seedColor,
    bool highContrast = false,
  }) {
    final ColorScheme base = _scheme(
      dynamicScheme,
      seedColor: seedColor,
      brightness: Brightness.dark,
      highContrast: highContrast,
    );
    return _build(amoled ? _toAmoled(base) : base);
  }

  /// The scheme to paint with.
  ///
  /// A wallpaper palette arrives already mixed, with no contrast dial to turn,
  /// so asking for high contrast drops it and derives from the seed instead —
  /// legibility is the thing being asked for, and it outranks the wallpaper.
  static ColorScheme _scheme(
    ColorScheme? dynamicScheme, {
    required Brightness brightness,
    required bool highContrast,
    Color? seedColor,
  }) {
    if (dynamicScheme != null && !highContrast) return dynamicScheme;
    return ColorScheme.fromSeed(
      seedColor: seedColor ?? seed,
      brightness: brightness,
      contrastLevel: highContrast ? _highContrastLevel : 0.0,
    );
  }

  /// Pushes a dark scheme to true black.
  ///
  /// Only the surface family is flattened — keeping the accent, container and
  /// "on" colors intact preserves contrast and the brand palette. Elevation
  /// tiers stay faintly distinguishable so cards and sheets don't dissolve
  /// into the background.
  static ColorScheme _toAmoled(ColorScheme scheme) => scheme.copyWith(
    surface: const Color(0xFF000000),
    surfaceDim: const Color(0xFF000000),
    surfaceBright: const Color(0xFF1A1A1A),
    surfaceContainerLowest: const Color(0xFF000000),
    surfaceContainerLow: const Color(0xFF0A0A0A),
    surfaceContainer: const Color(0xFF101010),
    surfaceContainerHigh: const Color(0xFF161616),
    surfaceContainerHighest: const Color(0xFF1E1E1E),
    onSurface: const Color(0xFFF2F2F2),
    outlineVariant: const Color(0xFF2A2A2A),
  );

  static ThemeData _build(ColorScheme scheme) {
    final bool isDark = scheme.brightness == Brightness.dark;
    final TextTheme text = _textTheme(scheme);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: isDark
          ? scheme.surface
          : Color.alphaBlend(
              scheme.primary.withValues(alpha: 0.018),
              scheme.surface,
            ),
      textTheme: text,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge,
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLow,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          textStyle: text.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          side: BorderSide(color: scheme.outlineVariant),
          textStyle: text.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        hintStyle: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: scheme.error, width: 1.4),
        ),
      ),
      chipTheme: ChipThemeData(
        showCheckmark: false,
        side: BorderSide.none,
        backgroundColor: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
        selectedColor: scheme.primary,
        labelStyle: text.labelLarge,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        elevation: 0,
        backgroundColor: scheme.surfaceContainer,
        indicatorColor: scheme.primary.withValues(alpha: 0.16),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (Set<WidgetState> states) => text.labelMedium!.copyWith(
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? scheme.primary
                : scheme.onSurfaceVariant,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (Set<WidgetState> states) => IconThemeData(
            size: 24,
            color: states.contains(WidgetState.selected)
                ? scheme.primary
                : scheme.onSurfaceVariant,
          ),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radiusLg)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: text.bodyMedium?.copyWith(
          color: scheme.onInverseSurface,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSm),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: 0.6),
        thickness: 1,
        space: 1,
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSm),
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          // Android's own back gesture: dragging from the edge peels this
          // page back to show where it would land, and lets go of the drag
          // rather than committing to it. Falls back to the same fade this
          // used to do where the platform can't drive it.
          TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
          TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
        },
      ),
    );
  }

  static TextTheme _textTheme(ColorScheme scheme) {
    // Display copy gets a distinctive serif-adjacent grotesk; body stays neutral.
    final TextTheme base = Typography.material2021(colorScheme: scheme)
        .englishLike
        .apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface);

    return base.copyWith(
      displaySmall: GoogleFonts.plusJakartaSans(
        textStyle: base.displaySmall,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.0,
      ),
      headlineMedium: GoogleFonts.plusJakartaSans(
        textStyle: base.headlineMedium,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.8,
      ),
      headlineSmall: GoogleFonts.plusJakartaSans(
        textStyle: base.headlineSmall,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
      titleLarge: GoogleFonts.plusJakartaSans(
        textStyle: base.titleLarge,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
      titleMedium: GoogleFonts.plusJakartaSans(
        textStyle: base.titleMedium,
        fontWeight: FontWeight.w600,
      ),
      titleSmall: GoogleFonts.plusJakartaSans(
        textStyle: base.titleSmall,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: GoogleFonts.inter(textStyle: base.bodyLarge, height: 1.5),
      bodyMedium: GoogleFonts.inter(textStyle: base.bodyMedium, height: 1.5),
      bodySmall: GoogleFonts.inter(textStyle: base.bodySmall, height: 1.45),
      labelLarge: GoogleFonts.inter(
        textStyle: base.labelLarge,
        fontWeight: FontWeight.w600,
      ),
      labelMedium: GoogleFonts.inter(
        textStyle: base.labelMedium,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
