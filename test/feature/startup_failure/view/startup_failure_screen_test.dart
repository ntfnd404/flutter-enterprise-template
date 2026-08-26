import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:template/feature/startup_failure/di/startup_failure_scope.dart';
import 'package:template/feature/startup_failure/view/startup_failure_screen.dart';

void main() {
  testWidgets('shows only generic text and a safe diagnostic code', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: StartupFailureScope(
          diagnosticCode: 'APP-STARTUP-001',
          child: StartupFailureScreen(),
        ),
      ),
    );

    expect(find.byKey(const ValueKey<String>('startup-failure-marker')), findsOneWidget);
    expect(find.text('APP-STARTUP-001'), findsOneWidget);
    expect(find.textContaining('Exception'), findsNothing);
    expect(find.textContaining('StackTrace'), findsNothing);
    expect(find.textContaining('APP_ENVIRONMENT'), findsNothing);
  });
}
