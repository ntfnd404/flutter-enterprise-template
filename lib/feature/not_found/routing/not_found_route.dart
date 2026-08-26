import 'package:flutter/foundation.dart';
import 'package:rolter/rolter.dart';
import 'package:template/app/routing/app_route.dart';
import 'package:template/app/routing/app_route_fallback.dart';
import 'package:template/feature/not_found/routing/not_found_route_name.dart';

/// History-excluded recovery destination for privacy-safe routing failures.
///
/// The route stores only a safe category. Attempted URI and query data are
/// discarded by application routing before this feature is constructed.
final class NotFoundRoute extends AppRoute implements HistoryExcluded {
  /// Creates a recovery route for a sanitized routing failure [reason].
  const NotFoundRoute({required this.reason});

  /// Safe failure category available to recovery presentation.
  final AppRouteFailureReason reason;

  @override
  LocalKey get pageKey => ValueKey<String>(
    '${NotFoundRouteName.notFound.value}:${reason.name}',
  );

  @override
  String get name => NotFoundRouteName.notFound.value;

  @override
  Map<String, String> toParams() => const <String, String>{};
}
