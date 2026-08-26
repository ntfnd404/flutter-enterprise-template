import 'package:flutter_test/flutter_test.dart';
import 'package:template/feature/startup_failure/bloc/startup_failure_bloc.dart';

void main() {
  test('exposes the safe diagnostic code as initial state', () {
    final bloc = StartupFailureBloc(diagnosticCode: 'APP-STARTUP-001');
    addTearDown(bloc.close);

    expect(bloc.state.diagnosticCode, 'APP-STARTUP-001');
  });
}
