import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_kit/ui_kit.dart';

void main() {
  test('registers semantic, typography, and layout extensions', () {
    for (final theme in [AppTheme.light, AppTheme.dark]) {
      expect(theme.extension<AppColorTokens>(), isNotNull);
      expect(theme.extension<AppLayoutTokens>(), isNotNull);
      final type = theme.extension<AppTypographyTokens>();
      expect(type?.textTheme, theme.textTheme);
      expect(theme.useMaterial3, isTrue);
    }
  });

  test('breakpoint boundaries are stable', () {
    expect(AppLayoutTokens.breakpointFor(599), AppBreakpoint.compact);
    expect(AppLayoutTokens.breakpointFor(600), AppBreakpoint.medium);
    expect(AppLayoutTokens.breakpointFor(840), AppBreakpoint.expanded);
    expect(AppLayoutTokens.breakpointFor(1200), AppBreakpoint.large);
    expect(AppLayoutTokens.breakpointFor(1600), AppBreakpoint.extraLarge);
  });

  test('semantic foreground pairs meet normal-text AA contrast', () {
    for (final theme in [AppTheme.light, AppTheme.dark]) {
      final colors = theme.extension<AppColorTokens>()!;
      final pairs = <(Color, Color)>[
        (theme.colorScheme.primary, theme.colorScheme.onPrimary),
        (theme.colorScheme.error, theme.colorScheme.onError),
        (colors.success, colors.onSuccess),
        (colors.warning, colors.onWarning),
        (colors.info, colors.onInfo),
      ];
      for (final (background, foreground) in pairs) {
        expect(_contrast(background, foreground), greaterThanOrEqualTo(4.5));
      }
    }
  });

  test('Material component themes and 48dp controls are assembled', () {
    final theme = AppTheme.light;
    expect(theme.cardTheme, isNotNull);
    expect(theme.inputDecorationTheme.filled, isTrue);
    expect(theme.bottomSheetTheme.showDragHandle, isTrue);
    expect(theme.navigationBarTheme.height, 80);
    expect(
      theme.filledButtonTheme.style?.minimumSize?.resolve(
        const <WidgetState>{},
      ),
      const Size(48, 48),
    );
  });

  testWidgets('reduced motion resolves to zero', (tester) async {
    late Duration duration;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: Builder(
          builder: (context) {
            duration = AppLayoutTokens.accessibleMotion(
              context,
              AppLayoutTokens.normal,
            );
            return const SizedBox();
          },
        ),
      ),
    );
    expect(duration, Duration.zero);
  });
}

double _contrast(Color first, Color second) {
  final high = first.computeLuminance() > second.computeLuminance()
      ? first.computeLuminance()
      : second.computeLuminance();
  final low = first.computeLuminance() > second.computeLuminance()
      ? second.computeLuminance()
      : first.computeLuminance();
  return (high + 0.05) / (low + 0.05);
}
