import 'package:flutter_test/flutter_test.dart';
import 'package:template/app/routing/app_route_fallback.dart';
import 'package:template/feature/not_found/bloc/not_found_bloc.dart';

void main() {
  for (final reason in AppRouteFailureReason.values) {
    test('exposes the sanitized $reason initial state', () {
      final bloc = NotFoundBloc(reason: reason);
      addTearDown(bloc.close);

      expect(bloc.state.reason, reason);
    });
  }
}
