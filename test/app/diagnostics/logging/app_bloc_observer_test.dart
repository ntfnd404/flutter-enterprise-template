import 'package:ephemeral_bloc/ephemeral_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:template/app/diagnostics/logging/app_bloc_observer.dart';
import 'package:template/app/diagnostics/logging/app_log_record.dart';
import 'package:template/app/diagnostics/logging/app_logger.dart';
import 'package:template/app/diagnostics/logging/records/app_bloc_log_records.dart';

void main() {
  late BlocObserver previousObserver;

  setUp(() {
    previousObserver = Bloc.observer;
  });

  tearDown(() {
    Bloc.observer = previousObserver;
  });

  test(
    'records every Bloc lifecycle breadcrumb with runtime types only',
    () async {
      final logger = _RecordingAppLogger();
      Bloc.observer = AppBlocObserver(logger: logger);
      final bloc = _TestBloc(const _InitialState());
      addTearDown(() async {
        if (!bloc.isClosed) {
          await bloc.close();
        }
      });

      final nextState = bloc.stream.first;
      bloc.add(const _SetStateEvent(_NextState()));
      await nextState;
      bloc.emitTestAction(const _TestAction());
      bloc.reportTestError(const _TestFailure(), StackTrace.empty);
      await bloc.close();

      expect(
        logger.records.map((record) => record.descriptor.eventName),
        [
          'app.bloc.created',
          'app.bloc.event',
          'app.bloc.state_changed',
          'app.bloc.action',
          'app.bloc.error_breadcrumb',
          'app.bloc.closed',
        ],
      );
      expect(logger.records, <Matcher>[
        isA<AppBlocCreatedLogRecord>().having(
          (record) => record.componentType,
          'componentType',
          _TestBloc,
        ),
        isA<AppBlocEventLogRecord>()
            .having(
              (record) => record.componentType,
              'componentType',
              _TestBloc,
            )
            .having(
              (record) => record.eventType,
              'eventType',
              _SetStateEvent,
            ),
        isA<AppBlocStateChangedLogRecord>()
            .having(
              (record) => record.componentType,
              'componentType',
              _TestBloc,
            )
            .having(
              (record) => record.previousStateType,
              'previousStateType',
              _InitialState,
            )
            .having(
              (record) => record.nextStateType,
              'nextStateType',
              _NextState,
            ),
        isA<AppBlocActionLogRecord>()
            .having(
              (record) => record.componentType,
              'componentType',
              _TestBloc,
            )
            .having(
              (record) => record.actionType,
              'actionType',
              _TestAction,
            ),
        isA<AppBlocErrorBreadcrumbLogRecord>()
            .having(
              (record) => record.componentType,
              'componentType',
              _TestBloc,
            )
            .having(
              (record) => record.errorType,
              'errorType',
              _TestFailure,
            ),
        isA<AppBlocClosedLogRecord>().having(
          (record) => record.componentType,
          'componentType',
          _TestBloc,
        ),
      ]);
    },
  );

  test('records one state-change breadcrumb for a Cubit emission', () async {
    final logger = _RecordingAppLogger();
    Bloc.observer = AppBlocObserver(logger: logger);
    final cubit = _TestCubit(const _InitialState());
    addTearDown(() async {
      if (!cubit.isClosed) {
        await cubit.close();
      }
    });

    final nextState = cubit.stream.first;
    cubit.setState(const _NextState());
    await nextState;

    final changes = logger.records
        .whereType<AppBlocStateChangedLogRecord>()
        .toList();

    expect(changes, hasLength(1));
    expect(changes.single.componentType, _TestCubit);
    expect(changes.single.previousStateType, _InitialState);
    expect(changes.single.nextStateType, _NextState);
  });

  test('a manual addError emits one breadcrumb and no other error record', () {
    final logger = _RecordingAppLogger();
    Bloc.observer = AppBlocObserver(logger: logger);
    final cubit = _TestCubit(const _InitialState());
    addTearDown(() async {
      await cubit.close();
    });

    cubit.addTestError(const _TestFailure(), StackTrace.empty);

    final errorRecords = logger.records
        .whereType<AppBlocErrorBreadcrumbLogRecord>()
        .toList();
    expect(errorRecords, hasLength(1));
    expect(errorRecords.single.componentType, _TestCubit);
    expect(errorRecords.single.errorType, _TestFailure);
    expect(logger.records.whereType<AppBlocEventLogRecord>(), isEmpty);
  });

  test('never stringifies event, state, action, or error payloads', () async {
    final logger = _RecordingAppLogger();
    Bloc.observer = AppBlocObserver(logger: logger);
    final initialState = _HostilePayload();
    final nextState = _HostilePayload();
    final event = _HostileEvent(nextState);
    final action = _HostilePayload();
    final error = _HostileFailure();
    final bloc = _HostileBloc(initialState);
    addTearDown(() async {
      if (!bloc.isClosed) {
        await bloc.close();
      }
    });

    final emittedState = bloc.stream.first;
    bloc.add(event);
    await emittedState;
    bloc.emitTestAction(action);
    bloc.reportTestError(error, StackTrace.empty);
    await bloc.close();

    expect(initialState.toStringCalls, 0);
    expect(nextState.toStringCalls, 0);
    expect(event.toStringCalls, 0);
    expect(action.toStringCalls, 0);
    expect(error.toStringCalls, 0);
  });

  test('a hostile logger cannot alter Bloc behavior', () async {
    Bloc.observer = const AppBlocObserver(logger: _ThrowingAppLogger());

    final bloc = _TestBloc(const _InitialState());
    addTearDown(() async {
      if (!bloc.isClosed) {
        await bloc.close();
      }
    });

    final nextState = bloc.stream.first;
    expect(
      () => bloc.add(const _SetStateEvent(_NextState())),
      returnsNormally,
    );
    expect(await nextState, isA<_NextState>());
    expect(
      () => bloc.emitTestAction(const _TestAction()),
      returnsNormally,
    );
    expect(
      () => bloc.reportTestError(const _TestFailure(), StackTrace.empty),
      returnsNormally,
    );
    await expectLater(bloc.close(), completes);
  });
}

final class _RecordingAppLogger implements AppLogger {
  final records = <AppLogRecord>[];

  @override
  void log(AppLogRecord record) {
    records.add(record);
  }
}

final class _ThrowingAppLogger implements AppLogger {
  const _ThrowingAppLogger();

  @override
  void log(AppLogRecord record) {
    throw StateError('Hostile test logger.');
  }
}

final class _TestBloc extends Bloc<_TestEvent, Object?>
    with EphemeralBlocMixin<Object?, Object> {
  _TestBloc(super.initialState) {
    on<_SetStateEvent>((event, emit) {
      emit(event.state);
    });
  }

  void emitTestAction(Object action) {
    emitAction(action);
  }

  void reportTestError(Object error, StackTrace stackTrace) {
    addError(error, stackTrace);
  }
}

sealed class _TestEvent {
  const _TestEvent();
}

final class const _SetStateEvent(final Object state) extends _TestEvent;

final class _TestCubit extends Cubit<Object?> {
  _TestCubit(super.initialState);

  void addTestError(Object error, StackTrace stackTrace) {
    addError(error, stackTrace);
  }

  void setState(Object state) {
    emit(state);
  }
}

final class _InitialState {
  const _InitialState();
}

final class _NextState {
  const _NextState();
}

final class _TestAction {
  const _TestAction();
}

final class _TestFailure implements Exception {
  const _TestFailure();
}

final class _HostileBloc extends Bloc<_HostileEvent, _HostilePayload>
    with EphemeralBlocMixin<_HostilePayload, _HostilePayload> {
  _HostileBloc(super.initialState) {
    on<_HostileEvent>((event, emit) {
      emit(event.state);
    });
  }

  void emitTestAction(_HostilePayload action) {
    emitAction(action);
  }

  void reportTestError(Object error, StackTrace stackTrace) {
    addError(error, stackTrace);
  }
}

final class _HostileEvent(final _HostilePayload state) {
  int toStringCalls = 0;

  @override
  String toString() {
    toStringCalls += 1;
    throw StateError('Event payload must not be stringified.');
  }
}

final class _HostilePayload {
  int toStringCalls = 0;

  @override
  String toString() {
    toStringCalls += 1;
    throw StateError('State or action payload must not be stringified.');
  }
}

final class _HostileFailure implements Exception {
  int toStringCalls = 0;

  @override
  String toString() {
    toStringCalls += 1;
    throw StateError('Failure must not be stringified.');
  }
}
