import 'package:flutter_test/flutter_test.dart';

/// Pumps until [finder] observes a widget or the integration timeout expires.
///
/// Async startup may perform platform I/O without scheduling a Flutter frame.
/// `pumpAndSettle` can therefore return before the first `runApp`. This helper
/// waits for an observable UI handoff without introducing a production-ready
/// handle solely for tests.
Future<void> pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 30),
}) async {
  final stopwatch = Stopwatch()..start();

  while (finder.evaluate().isEmpty && stopwatch.elapsed < timeout) {
    await tester.pump(const Duration(milliseconds: 100));
  }

  expect(finder, findsOneWidget);
}
