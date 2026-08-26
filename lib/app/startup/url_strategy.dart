import 'package:template/app/environment/app_url_strategy.dart';
import 'package:template/app/startup/url_strategy_stub.dart'
    if (dart.library.js_interop) 'package:template/app/startup/url_strategy_web.dart'
    as platform;

/// Configures Flutter's process-global browser URL representation.
///
/// Non-Web platforms safely ignore [strategy]. Path URLs remain an explicit
/// deployment opt-in because the host must rewrite direct requests to the
/// Flutter entry document.
void configureUrlStrategy(AppUrlStrategy strategy) {
  platform.configureUrlStrategy(strategy);
}
