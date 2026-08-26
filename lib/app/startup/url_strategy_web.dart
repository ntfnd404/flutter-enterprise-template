import 'package:flutter_web_plugins/url_strategy.dart' as flutter_web;
import 'package:template/app/environment/app_url_strategy.dart';

/// Applies the selected Flutter Web URL strategy.
void configureUrlStrategy(AppUrlStrategy strategy) {
  switch (strategy) {
    case AppUrlStrategy.hash:
      flutter_web.setUrlStrategy(const flutter_web.HashUrlStrategy());
    case AppUrlStrategy.path:
      flutter_web.usePathUrlStrategy();
  }
}
