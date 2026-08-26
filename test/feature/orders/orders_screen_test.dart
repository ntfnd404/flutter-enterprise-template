import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:template/core/event_bus/app_event_bus.dart';
import 'package:template/feature/orders/di/orders_scope.dart';
import 'package:template/feature/orders/view/orders_screen.dart';

import 'support/recording_ordering_facade.dart';

void main() {
  testWidgets('is usable at 320px and emits a monitor callback', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final ordering = RecordingOrderingFacade();
    final bus = AppEventBus();
    addTearDown(() async {
      await ordering.dispose();
      await bus.dispose();
    });
    int? monitoredSequence;

    await tester.pumpWidget(
      MaterialApp(
        home: OrdersScope(
          ordering: ordering,
          eventPublisher: bus,
          child: OrdersScreen(
            onMonitorDraftCreation: (sequence) {
              monitoredSequence = sequence;
            },
          ),
        ),
      ),
    );
    await ordering.waitForWatchCount(1);
    ordering.emitOrders(const []);
    await tester.pump();

    await tester.tap(
      find.byKey(const ValueKey<String>('orders-create-draft')),
    );
    await tester.pump();

    expect(monitoredSequence, 1);
    expect(tester.takeException(), isNull);
  });
}
