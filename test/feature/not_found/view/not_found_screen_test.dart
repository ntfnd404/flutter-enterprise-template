import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:template/feature/not_found/view/not_found_screen.dart';

void main() {
  testWidgets('renders only generic privacy-safe text', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: NotFoundScreen()),
    );

    expect(
      find.byKey(const ValueKey<String>('not-found-marker')),
      findsOneWidget,
    );
    expect(find.text('Page not found'), findsOneWidget);
    expect(find.textContaining('token'), findsNothing);
  });
}
