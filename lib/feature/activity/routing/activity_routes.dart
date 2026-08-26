import 'package:rolter/rolter.dart';
import 'package:template/app/routing/app_route.dart';
import 'package:template/app/routing/app_route_fallback.dart';
import 'package:template/feature/activity/routing/activity_route.dart';
import 'package:template/feature/activity/routing/activity_route_name.dart';

/// Decoder contribution owned by the activity feature.
///
/// Invalid input is delegated to [onInvalidRoute], keeping the feature
/// independent from the application's concrete recovery destination.
Map<String, RouteDecoder<AppRoute>> activityRoutes({
  required AppRouteFallbackBuilder onInvalidRoute,
}) => <String, RouteDecoder<AppRoute>>{
  ActivityRouteName.activity.value: (params, children) {
    if (children.isNotEmpty ||
        params.length != 1 ||
        !params.containsKey('sequence')) {
      return onInvalidRoute(AppRouteFailureReason.invalidParameters);
    }

    final sequence = int.tryParse(params['sequence'] ?? '');
    if (sequence == null || sequence < 1) {
      return onInvalidRoute(AppRouteFailureReason.invalidParameters);
    }

    return ActivityRoute(sequence: sequence);
  },
};
