import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:template/app/diagnostics/logging/app_bloc_observer.dart';
import 'package:template/app/diagnostics/logging/records/app_bloc_log_records.dart';
import 'package:template/app/environment/app_environment.dart';
import 'package:template/app/startup/initialize_app_framework.dart';

import 'support/run_application_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('installs an AppBlocObserver backed by the exact logger', () async {
    final originalObserver = Bloc.observer;
    final logger = StartupTestLogger();

    try {
      await initializeAppFramework(
        environment: AppEnvironment.fromValues(
          environment: 'local',
          urlStrategy: 'hash',
        ),
        logger: logger,
      );

      expect(Bloc.observer, isA<AppBlocObserver>());
      final cubit = _TestCubit();
      try {
        cubit.increment();
      } finally {
        await cubit.close();
      }

      expect(logger.records.whereType<AppBlocCreatedLogRecord>(), hasLength(1));
      expect(
        logger.records.whereType<AppBlocStateChangedLogRecord>(),
        hasLength(1),
      );
      expect(logger.records.whereType<AppBlocClosedLogRecord>(), hasLength(1));
    } finally {
      Bloc.observer = originalObserver;
    }
  });
}

final class _TestCubit extends Cubit<int> {
  _TestCubit() : super(0);

  void increment() => emit(state + 1);
}
