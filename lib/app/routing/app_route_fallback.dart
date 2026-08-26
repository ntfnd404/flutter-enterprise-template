import 'package:template/app/routing/app_route.dart';

/// Privacy-safe reason why application routing could not produce a destination.
///
/// The value deliberately excludes the attempted URI, route parameters, and
/// query values so presentation and diagnostics cannot expose untrusted input.
enum AppRouteFailureReason {
  /// No registered feature decoder matched the requested route name.
  unknownRoute,

  /// A known feature route received malformed or unsupported parameters.
  invalidParameters,
}

/// Creates an application-owned fallback route for a safe [reason].
///
/// Feature decoder maps receive this strategy instead of importing a concrete
/// recovery feature. The application route registry owns the final mapping.
typedef AppRouteFallbackBuilder =
    AppRoute Function(
      AppRouteFailureReason reason,
    );
