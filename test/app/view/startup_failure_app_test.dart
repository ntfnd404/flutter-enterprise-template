import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:template/app/view/startup_failure_app.dart';
import 'package:template/feature/startup_failure/di/startup_failure_scope.dart';
import 'package:template/feature/startup_failure/view/startup_failure_screen.dart';
import 'package:ui_kit/ui_kit.dart';

void main() {
  testWidgets('builds the pre-DI feature boundary inside MaterialApp', (
    tester,
  ) async {
    await tester.pumpWidget(
      const StartupFailureApp(diagnosticCode: 'APP-STARTUP-001'),
    );

    expect(find.byType(StartupFailureScope), findsOneWidget);
    expect(find.byType(StartupFailureScreen), findsOneWidget);
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.theme, same(AppTheme.light));
    expect(app.darkTheme, same(AppTheme.dark));
    expect(
      find.byKey(const ValueKey('startup-failure-marker')),
      findsOneWidget,
    );
    expect(find.text('APP-STARTUP-001'), findsOneWidget);
  });
}
