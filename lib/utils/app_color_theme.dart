import 'package:flutter/material.dart';

enum AppThemeOption {
  light,
  dark,
}

extension AppThemeOptionX on AppThemeOption {
  String get storageValue => switch (this) {
        AppThemeOption.light => 'light',
        AppThemeOption.dark => 'dark',
      };

  String get label => switch (this) {
        AppThemeOption.light => 'Light',
        AppThemeOption.dark => 'Dark',
      };

  static AppThemeOption fromStorageValue(String? value) {
    return AppThemeOption.values.firstWhere(
      (option) => option.storageValue == value,
      orElse: () => AppThemeOption.dark,
    );
  }
}

@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  final Color success;
  final Color warning;
  final Color danger;
  final Color neutral;
  final Color statDistance;
  final Color statDuration;
  final Color statSpeed;
  final Color statPoints;
  final Color trailStart;
  final Color trailEnd;
  final Color heroBackground;
  final Color heroNeonText;

  const AppSemanticColors({
    required this.success,
    required this.warning,
    required this.danger,
    required this.neutral,
    required this.statDistance,
    required this.statDuration,
    required this.statSpeed,
    required this.statPoints,
    required this.trailStart,
    required this.trailEnd,
    required this.heroBackground,
    required this.heroNeonText,
  });

  @override
  AppSemanticColors copyWith({
    Color? success,
    Color? warning,
    Color? danger,
    Color? neutral,
    Color? statDistance,
    Color? statDuration,
    Color? statSpeed,
    Color? statPoints,
    Color? trailStart,
    Color? trailEnd,
    Color? heroBackground,
    Color? heroNeonText,
  }) {
    return AppSemanticColors(
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      neutral: neutral ?? this.neutral,
      statDistance: statDistance ?? this.statDistance,
      statDuration: statDuration ?? this.statDuration,
      statSpeed: statSpeed ?? this.statSpeed,
      statPoints: statPoints ?? this.statPoints,
      trailStart: trailStart ?? this.trailStart,
      trailEnd: trailEnd ?? this.trailEnd,
      heroBackground: heroBackground ?? this.heroBackground,
      heroNeonText: heroNeonText ?? this.heroNeonText,
    );
  }

  @override
  AppSemanticColors lerp(ThemeExtension<AppSemanticColors>? other, double t) {
    if (other is! AppSemanticColors) return this;
    return AppSemanticColors(
      success: Color.lerp(success, other.success, t) ?? success,
      warning: Color.lerp(warning, other.warning, t) ?? warning,
      danger: Color.lerp(danger, other.danger, t) ?? danger,
      neutral: Color.lerp(neutral, other.neutral, t) ?? neutral,
      statDistance:
          Color.lerp(statDistance, other.statDistance, t) ?? statDistance,
      statDuration:
          Color.lerp(statDuration, other.statDuration, t) ?? statDuration,
      statSpeed: Color.lerp(statSpeed, other.statSpeed, t) ?? statSpeed,
      statPoints: Color.lerp(statPoints, other.statPoints, t) ?? statPoints,
      trailStart: Color.lerp(trailStart, other.trailStart, t) ?? trailStart,
      trailEnd: Color.lerp(trailEnd, other.trailEnd, t) ?? trailEnd,
      heroBackground:
          Color.lerp(heroBackground, other.heroBackground, t) ?? heroBackground,
      heroNeonText:
          Color.lerp(heroNeonText, other.heroNeonText, t) ?? heroNeonText,
    );
  }
}

class AppColorTheme {
  static const primary = Color(0xFFB6FF3B);
  static const primaryPressed = Color(0xFF91D629);
  static const background = Color(0xFF090D0B);
  static const card = Color(0xFF151C17);
  static const surface = Color(0xFF202A23);
  static const border = Color(0xFF344036);
  static const textPrimary = Color(0xFFF3FFF5);
  static const textSecondary = Color(0xFFA0B2A5);
  static const success = Color(0xFF42E8A4);
  static const warning = Color(0xFFFFCA68);
  static const error = Color(0xFFFF637E);
  static const info = Color(0xFF63C7FF);

  static const lightBackground = Color(0xFFF1F7F3);
  static const lightCard = Color(0xFFFFFFFF);
  static const lightSurface = Color(0xFFE1F0E6);
  static const lightBorder = Color(0xFFCFE2D5);
  static const lightTextPrimary = Color(0xFF14251B);
  static const lightTextSecondary = Color(0xFF536B5C);
  static const lightSuccess = Color(0xFF168653);
  static const lightWarning = Color(0xFFB87900);
  static const lightError = Color(0xFFD63C52);
  static const lightInfo = Color(0xFF1675BE);
  static const lightPrimary = Color(0xFF20D967);
  static const lightPrimaryPressed = Color(0xFF0EAF4D);
  static const lightHeroBackground = Color(0xFF14271C);
  static const lightActiveIcon = Color(0xFF08783A);

  static ThemeData themeFor(AppThemeOption option) {
    return switch (option) {
      AppThemeOption.light => _buildTheme(
          seed: lightPrimary,
          brightness: Brightness.light,
          useLightPalette: true,
        ),
      AppThemeOption.dark => _buildTheme(
          seed: primary,
          brightness: Brightness.dark,
        ),
    };
  }

  static ThemeData _buildTheme({
    required Color seed,
    required Brightness brightness,
    bool useLightPalette = false,
  }) {
    final isDark = brightness == Brightness.dark;
    final generatedScheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    );
    final colorScheme = useLightPalette
        ? generatedScheme.copyWith(
            primary: lightPrimary,
            onPrimary: lightTextPrimary,
            primaryContainer: lightSurface,
            onPrimaryContainer: lightTextPrimary,
            secondary: lightSuccess,
            onSecondary: Colors.white,
            secondaryContainer: lightSurface,
            onSecondaryContainer: lightTextPrimary,
            tertiary: lightInfo,
            onTertiary: Colors.white,
            surface: lightCard,
            surfaceContainerLowest: lightBackground,
            surfaceContainerLow: lightBackground,
            surfaceContainer: lightSurface,
            surfaceContainerHigh: lightSurface,
            surfaceContainerHighest: lightSurface,
            onSurface: lightTextPrimary,
            onSurfaceVariant: lightTextSecondary,
            outline: lightBorder,
            outlineVariant: lightBorder,
            error: lightError,
            onError: Colors.white,
            surfaceTint: Colors.transparent,
          )
        : isDark
        ? generatedScheme.copyWith(
            primary: primary,
            onPrimary: background,
            primaryContainer: surface,
            onPrimaryContainer: textPrimary,
            secondary: success,
            onSecondary: background,
            secondaryContainer: surface,
            onSecondaryContainer: textPrimary,
            tertiary: info,
            onTertiary: background,
            surface: card,
            surfaceContainerLowest: background,
            surfaceContainerLow: card,
            surfaceContainer: surface,
            surfaceContainerHigh: surface,
            surfaceContainerHighest: surface,
            onSurface: textPrimary,
            onSurfaceVariant: textSecondary,
            outline: border,
            outlineVariant: border,
            error: error,
            onError: background,
            surfaceTint: Colors.transparent,
          )
        : generatedScheme;

    return ThemeData(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: useLightPalette
          ? lightBackground
          : isDark
              ? background
              : colorScheme.surface,
      useMaterial3: true,
      appBarTheme: AppBarTheme(
        backgroundColor: useLightPalette
            ? lightBackground
            : isDark
                ? background
                : colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        elevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: useLightPalette
            ? lightBackground
            : isDark
                ? background
                : colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: Colors.transparent,
        elevation: 0,
        height: 80,
        iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
              size: 27,
              color: states.contains(WidgetState.selected)
                  ? (useLightPalette ? lightActiveIcon : colorScheme.primary)
                  : colorScheme.onSurfaceVariant,
            )),
        labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: states.contains(WidgetState.selected)
                  ? (useLightPalette ? lightActiveIcon : colorScheme.primary)
                  : colorScheme.onSurfaceVariant,
            )),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        elevation: 4,
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      extensions: [
        AppSemanticColors(
          success: useLightPalette
              ? lightSuccess
              : isDark
                  ? success
                  : colorScheme.tertiary,
          warning: useLightPalette
              ? lightWarning
              : isDark
                  ? warning
                  : const Color(0xFFE67E22),
          danger: colorScheme.error,
          neutral: colorScheme.outline,
          statDistance: colorScheme.primary,
          statDuration: colorScheme.tertiary,
          statSpeed: isDark ? primary : const Color(0xFFF39C12),
          statPoints: colorScheme.secondary,
          trailStart: isDark ? success : const Color(0xFF2ECC71),
          trailEnd: colorScheme.error,
          heroBackground: useLightPalette ? lightHeroBackground : primary,
          heroNeonText: useLightPalette ? lightPrimary : background,
        ),
      ],
    );
  }
}
