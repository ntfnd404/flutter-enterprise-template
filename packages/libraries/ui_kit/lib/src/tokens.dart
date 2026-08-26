import 'package:flutter/material.dart';

/// Responsive layout classes with stable inclusive boundaries.
enum AppBreakpoint { compact, medium, expanded, large, extraLarge }

/// Immutable non-color design tokens registered on [ThemeData].
@immutable
final class AppLayoutTokens extends ThemeExtension<AppLayoutTokens> {
  /// Canonical v1 layout token set.
  const AppLayoutTokens();

  /// Spacing scale in logical pixels.
  static const spacing = <double>[4, 8, 12, 16, 24, 32, 48];

  /// Corner radius scale in logical pixels.
  static const radius = <double>[4, 6, 12, 16, 24, 999];

  /// Border width scale in logical pixels.
  static const border = <double>[1, 1.5];

  /// Elevation scale.
  static const elevation = <double>[0, 1, 3, 6, 8, 12];

  /// Interaction state opacities.
  static const disabledOpacity = 0.38;

  /// Hovered-state overlay opacity.
  static const hoverOpacity = 0.08;

  /// Focused-state overlay opacity.
  static const focusOpacity = 0.12;

  /// Pressed-state overlay opacity.
  static const pressedOpacity = 0.12;

  /// Dragged-state overlay opacity.
  static const draggedOpacity = 0.16;

  /// Motion duration scale.
  static const fast = Duration(milliseconds: 100);

  /// Default motion duration.
  static const normal = Duration(milliseconds: 200);

  /// Slow motion duration.
  static const slow = Duration(milliseconds: 300);

  /// Deliberate motion duration.
  static const deliberate = Duration(milliseconds: 500);

  /// Returns zero when platform accessibility settings disable animations.
  static Duration accessibleMotion(BuildContext context, Duration duration) =>
      MediaQuery.disableAnimationsOf(context) ? Duration.zero : duration;

  /// Classifies [width] using the v1 breakpoint contract.
  static AppBreakpoint breakpointFor(double width) => switch (width) {
    < 600 => AppBreakpoint.compact,
    < 840 => AppBreakpoint.medium,
    < 1200 => AppBreakpoint.expanded,
    < 1600 => AppBreakpoint.large,
    _ => AppBreakpoint.extraLarge,
  };

  @override
  AppLayoutTokens copyWith() => this;

  @override
  AppLayoutTokens lerp(covariant AppLayoutTokens? other, double t) => this;
}

/// Semantic colors beyond Material's standard [ColorScheme].
@immutable
final class AppColorTokens extends ThemeExtension<AppColorTokens> {
  /// Creates the complete semantic color contract.
  const AppColorTokens({
    required this.success,
    required this.onSuccess,
    required this.successContainer,
    required this.onSuccessContainer,
    required this.warning,
    required this.onWarning,
    required this.warningContainer,
    required this.onWarningContainer,
    required this.info,
    required this.onInfo,
    required this.infoContainer,
    required this.onInfoContainer,
    required this.canvas,
    required this.elevatedSurface,
    required this.input,
    required this.disabledSurface,
    required this.tertiaryContent,
    required this.disabledContent,
    required this.strongBorder,
    required this.divider,
    required this.focus,
    required this.scrim,
  });

  /// Success foreground color.
  final Color success;

  /// Content color drawn on [success].
  final Color onSuccess;

  /// Success container color.
  final Color successContainer;

  /// Content color drawn on [successContainer].
  final Color onSuccessContainer;

  /// Warning foreground color.
  final Color warning;

  /// Content color drawn on [warning].
  final Color onWarning;

  /// Warning container color.
  final Color warningContainer;

  /// Content color drawn on [warningContainer].
  final Color onWarningContainer;

  /// Informational foreground color.
  final Color info;

  /// Content color drawn on [info].
  final Color onInfo;

  /// Informational container color.
  final Color infoContainer;

  /// Content color drawn on [infoContainer].
  final Color onInfoContainer;

  /// Lowest-elevation application canvas.
  final Color canvas;

  /// Elevated surface color.
  final Color elevatedSurface;

  /// Filled input surface color.
  final Color input;

  /// Disabled surface color.
  final Color disabledSurface;

  /// Tertiary content color.
  final Color tertiaryContent;

  /// Disabled content color.
  final Color disabledContent;

  /// Strong border color.
  final Color strongBorder;

  /// Divider color.
  final Color divider;

  /// Focus indicator color.
  final Color focus;

  /// Scrim color.
  final Color scrim;

  @override
  AppColorTokens copyWith() => this;

  @override
  AppColorTokens lerp(covariant AppColorTokens? other, double t) =>
      other == null || t < 0.5 ? this : other;
}

/// Canonical parallel type scale mirrored into Material [TextTheme].
@immutable
final class AppTypographyTokens extends ThemeExtension<AppTypographyTokens> {
  /// Creates tokens from a Material-compatible scale.
  const AppTypographyTokens(this.textTheme);

  /// Canonical type scale; colors are supplied by semantic theme roles.
  final TextTheme textTheme;

  @override
  AppTypographyTokens copyWith({TextTheme? textTheme}) =>
      AppTypographyTokens(textTheme ?? this.textTheme);

  @override
  AppTypographyTokens lerp(
    covariant AppTypographyTokens? other,
    double t,
  ) => AppTypographyTokens(TextTheme.lerp(textTheme, other?.textTheme, t));
}
