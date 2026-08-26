import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:template/core/event_bus/app_event.dart';
import 'package:template/core/event_bus/app_event_bus.dart';

void main() {
  test('delivers matching events asynchronously and in order', () async {
    final eventBus = AppEventBus();
    final received = <_TestEvent>[];
    final subscription = eventBus.on<_TestEvent>().listen(received.add);

    eventBus
      ..emit(const _TestEvent(1))
      ..emit(const _OtherEvent())
      ..emit(const _TestEvent(2));
    expect(received, isEmpty);

    await Future<void>.delayed(Duration.zero);
    expect(received.map((event) => event.sequence), <int>[1, 2]);

    await subscription.cancel();
    await eventBus.dispose();
  });

  test('does not replay events to late subscribers', () async {
    final eventBus = AppEventBus();
    eventBus.emit(const _TestEvent(1));
    await Future<void>.delayed(Duration.zero);

    final received = <_TestEvent>[];
    final subscription = eventBus.on<_TestEvent>().listen(received.add);
    await Future<void>.delayed(Duration.zero);

    expect(received, isEmpty);
    await subscription.cancel();
    await eventBus.dispose();
  });

  test('isolates listener failures in their zone', () async {
    final eventBus = AppEventBus();
    final failures = <Object>[];
    final received = <_TestEvent>[];

    final run = runZonedGuarded(
      () async {
        final failing = eventBus.on<_TestEvent>().listen(
          (_) => throw StateError('listener'),
        );
        final healthy = eventBus.on<_TestEvent>().listen(received.add);

        eventBus.emit(const _TestEvent(1));
        await Future<void>.delayed(Duration.zero);

        await failing.cancel();
        await healthy.cancel();
      },
      (error, _) => failures.add(error),
    );
    if (run == null) {
      fail('Guarded zone did not return the test future.');
    }
    await run;

    expect(failures, <Object>[isA<StateError>()]);
    expect(received, const <_TestEvent>[_TestEvent(1)]);
    await eventBus.dispose();
  });

  test('rejects publish and subscription after disposal starts', () async {
    final eventBus = AppEventBus();

    final first = eventBus.dispose();
    final concurrent = eventBus.dispose();

    expect(identical(first, concurrent), isTrue);
    expect(eventBus.on<_TestEvent>, throwsStateError);
    expect(() => eventBus.emit(const _TestEvent(1)), throwsStateError);
    await first;
  });
}

final class _TestEvent extends AppEvent {
  const _TestEvent(this.sequence);

  final int sequence;
}

final class _OtherEvent extends AppEvent {
  const _OtherEvent();
}
