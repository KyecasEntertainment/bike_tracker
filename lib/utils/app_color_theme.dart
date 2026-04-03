import 'package:flutter/material.dart';

enum AppThemeOption {
  light,
  dark,
  green,
  blue,
}

extension AppThemeOptionX on AppThemeOption {
  String get storageValue => switch (this) {
        AppThemeOption.light => 'light',
        AppThemeOption.dark => 'dark',
        AppThemeOption.green => 'green',
        AppThemeOption.blue => 'blue',
      };

  String get label => switch (this) {
        AppThemeOption.light => 'Light',
        AppThemeOption.dark => 'Dark',
        AppThemeOption.green => 'Green',
        AppThemeOption.blue => 'Blue',
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
    );
  }
}

class AppColorTheme {
  static ThemeData themeFor(AppThemeOption option) {
    return switch (option) {
      AppThemeOption.light => _buildTheme(
          seed: const Color(0xFF5E35B1),
          brightness: Brightness.light,
        ),
      AppThemeOption.dark => _buildTheme(
          seed: const Color(0xFF263238),
          brightness: Brightness.dark,
        ),
      AppThemeOption.green => _buildTheme(
          seed: const Color(0xFF2E7D32),
          brightness: Brightness.light,
        ),
      AppThemeOption.blue => _buildTheme(
          seed: const Color(0xFF1565C0),
          brightness: Brightness.light,
        ),
    };
  }

  static ThemeData _buildTheme({
    required Color seed,
    required Brightness brightness,
  }) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    );

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        elevation: 4,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      extensions: [
        AppSemanticColors(
          success: colorScheme.tertiary,
          warning: const Color(0xFFE67E22),
          danger: colorScheme.error,
          neutral: colorScheme.outline,
          statDistance: colorScheme.primary,
          statDuration: colorScheme.tertiary,
          statSpeed: const Color(0xFFF39C12),
          statPoints: colorScheme.secondary,
          trailStart: const Color(0xFF2ECC71),
          trailEnd: colorScheme.error,
        ),
      ],
    );
  }
}
