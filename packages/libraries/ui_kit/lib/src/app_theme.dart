import 'package:flutter/material.dart';
import 'package:ui_kit/src/tokens.dart';

/// Assembles the sole runtime source of UI theme truth.
final class AppTheme {
  AppTheme._();

  /// Light Material 3 theme.
  static final ThemeData light = _build(Brightness.light);

  /// Dark Material 3 theme.
  static final ThemeData dark = _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    const primarySeed = Color(0xFF00A86B);
    final scheme = ColorScheme.fromSeed(
      seedColor: primarySeed,
      brightness: brightness,
    );
    final success = _status(const Color(0xFF2E7D32), brightness);
    final warning = _status(const Color(0xFFED6C02), brightness);
    final info = _status(const Color(0xFF1976D2), brightness);
    final error = _status(const Color(0xFFBA1A1A), brightness);
    final textTheme = Typography.material2021().black.apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );
    final colors = AppColorTokens(
      success: success.primary,
      onSuccess: success.onPrimary,
      successContainer: success.primaryContainer,
      onSuccessContainer: success.onPrimaryContainer,
      warning: warning.primary,
      onWarning: warning.onPrimary,
      warningContainer: warning.primaryContainer,
      onWarningContainer: warning.onPrimaryContainer,
      info: info.primary,
      onInfo: info.onPrimary,
      infoContainer: info.primaryContainer,
      onInfoContainer: info.onPrimaryContainer,
      canvas: scheme.surfaceContainerLowest,
      elevatedSurface: scheme.surfaceContainerHigh,
      input: scheme.surfaceContainerHighest,
      disabledSurface: scheme.onSurface.withValues(alpha: 0.12),
      tertiaryContent: scheme.onSurfaceVariant,
      disabledContent: scheme.onSurface.withValues(alpha: 0.38),
      strongBorder: scheme.outline,
      divider: scheme.outlineVariant,
      focus: scheme.primary,
      scrim: scheme.scrim,
    );
    final minimumSize = WidgetStateProperty.all(const Size(48, 48));
    final overlay = WidgetStateProperty.resolveWith<Color?>((states) {
      if (states.contains(WidgetState.pressed) ||
          states.contains(WidgetState.focused)) {
        return scheme.primary.withValues(alpha: AppLayoutTokens.focusOpacity);
      }
      if (states.contains(WidgetState.hovered)) {
        return scheme.primary.withValues(alpha: AppLayoutTokens.hoverOpacity);
      }
      return null;
    });

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme.copyWith(
        error: error.primary,
        onError: error.onPrimary,
      ),
      textTheme: textTheme,
      extensions: <ThemeExtension<dynamic>>[
        colors,
        const AppLayoutTokens(),
        AppTypographyTokens(textTheme),
      ],
      cardTheme: CardThemeData(
        elevation: AppLayoutTokens.elevation[2],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppLayoutTokens.radius[2]),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(minimumSize: minimumSize, overlayColor: overlay),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(minimumSize: minimumSize, overlayColor: overlay),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(minimumSize: minimumSize, overlayColor: overlay),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.input,
        border: const OutlineInputBorder(),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: colors.focus,
            width: AppLayoutTokens.border[1],
          ),
        ),
      ),
      dialogTheme: const DialogThemeData(),
      bottomSheetTheme: const BottomSheetThemeData(showDragHandle: true),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
      checkboxTheme: CheckboxThemeData(overlayColor: overlay),
      radioTheme: RadioThemeData(overlayColor: overlay),
      switchTheme: SwitchThemeData(overlayColor: overlay),
      navigationBarTheme: const NavigationBarThemeData(height: 80),
      navigationRailTheme: const NavigationRailThemeData(minWidth: 80),
      tooltipTheme: const TooltipThemeData(
        waitDuration: Duration(milliseconds: 500),
      ),
      focusColor: colors.focus.withValues(
        alpha: AppLayoutTokens.focusOpacity,
      ),
      dividerColor: colors.divider,
      disabledColor: colors.disabledContent,
    );
  }

  static ColorScheme _status(Color seed, Brightness brightness) =>
      ColorScheme.fromSeed(seedColor: seed, brightness: brightness);
}
