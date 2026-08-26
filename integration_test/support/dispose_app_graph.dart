import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:template/app/di/app_dependency_graph_owner.dart';

/// Removes the normal application tree and waits for its memoized graph close.
///
/// Integration scenarios call this before disposing their test-owned error
/// boundary so graph-disposal diagnostics cannot arrive after the boundary is
/// released.
Future<void> disposeAppGraph(WidgetTester tester) async {
  final owner = tester.widget<AppDependencyGraphOwner>(
    find.byType(AppDependencyGraphOwner),
  );
  final graph = owner.graph;

  await tester.pumpWidget(const SizedBox.shrink());
  await graph.dispose();
  await tester.pump();
}
