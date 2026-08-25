import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:template/app/routing/app_route_fallback.dart';
import 'package:template/feature/not_found/di/not_found_scope.dart';
import 'package:template/feature/not_found/view/not_found_screen.dart';

void main() {
  for (final reason in AppRouteFailureReason.values) {
    testWidgets('renders generic privacy-safe text for $reason', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: NotFoundScope(
            reason: reason,
            child: const NotFoundScreen(),
          ),
        ),
      );

      expect(
        find.byKey(const ValueKey<String>('not-found-marker')),
        findsOneWidget,
      );
      expect(find.text('Page not found'), findsOneWidget);
      expect(find.text(reason.name), findsNothing);
      expect(find.textContaining('token'), findsNothing);
    });
  }
}
