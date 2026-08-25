import 'package:flutter/foundation.dart';
import 'package:template/app/routing/app_route.dart';
import 'package:template/feature/activity/routing/activity_route_name.dart';

/// Typed activity destination highlighting one observed demo sequence.
final class ActivityRoute extends AppRoute {
  /// Creates a route for a positive [sequence].
  ActivityRoute({required this.sequence}) {
    if (sequence < 1) {
      throw ArgumentError('Activity route sequence must be positive.');
    }
  }

  /// Sequence selected by the source feature.
  final int sequence;

  @override
  LocalKey get pageKey =>
      ValueKey<String>('${ActivityRouteName.activity.value}:$sequence');

  @override
  String get name => ActivityRouteName.activity.value;

  @override
  Map<String, String> toParams() => <String, String>{'sequence': '$sequence'};
}
