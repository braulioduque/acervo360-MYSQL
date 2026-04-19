import 'package:flutter/material.dart';

/// Cores semânticas do app, usadas via `AppColors.of(context)`.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.scaffold,
    required this.card,
    required this.cardBorder,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.accent,
    required this.inputFill,
    required this.bottomSheet,
  });

  final Color scaffold;
  final Color card;
  final Color cardBorder;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color accent;
  final Color inputFill;
  final Color bottomSheet;

  /// Atalho para acessar as cores do tema atual.
  static AppColors of(BuildContext context) {
    return Theme.of(context).extension<AppColors>()!;
  }

  // ── Paletas ──

  static const dark = AppColors(
    scaffold: Color(0xFF0F172A),
    card: Color(0xFF1E293B),
    cardBorder: Color(0x1FFFFFFF), // white12
    textPrimary: Colors.white,
    textSecondary: Color(0x99FFFFFF), // white60
    textMuted: Color(0x66FFFFFF), // white40
    accent: Color(0xFF1E56D1),
    inputFill: Color(0xFF1E293B),
    bottomSheet: Color(0xFF111827),
  );

  static const light = AppColors(
    scaffold: Color(0xFFF8FAFC),
    card: Colors.white,
    cardBorder: Color(0xFFE2E8F0),
    textPrimary: Color(0xFF0F172A),
    textSecondary: Color(0xFF475569),
    textMuted: Color(0xFF94A3B8),
    accent: Color(0xFF1E56D1),
    inputFill: Color(0xFFF1F5F9),
    bottomSheet: Colors.white,
  );

  @override
  AppColors copyWith({
    Color? scaffold,
    Color? card,
    Color? cardBorder,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? accent,
    Color? inputFill,
    Color? bottomSheet,
  }) {
    return AppColors(
      scaffold: scaffold ?? this.scaffold,
      card: card ?? this.card,
      cardBorder: cardBorder ?? this.cardBorder,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      accent: accent ?? this.accent,
      inputFill: inputFill ?? this.inputFill,
      bottomSheet: bottomSheet ?? this.bottomSheet,
    );
  }

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      scaffold: Color.lerp(scaffold, other.scaffold, t)!,
      card: Color.lerp(card, other.card, t)!,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      inputFill: Color.lerp(inputFill, other.inputFill, t)!,
      bottomSheet: Color.lerp(bottomSheet, other.bottomSheet, t)!,
    );
  }
}

/// Temas pré-definidos do app.
class AppTheme {
  AppTheme._();

  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E56D1),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: AppColors.dark.scaffold,
        useMaterial3: true,
        extensions: const [AppColors.dark],
      );

  static ThemeData get light => ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E56D1),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: AppColors.light.scaffold,
        useMaterial3: true,
        extensions: const [AppColors.light],
      );
}
