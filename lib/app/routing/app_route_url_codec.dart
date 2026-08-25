import 'package:flutter/foundation.dart';
import 'package:rolter/rolter.dart';
import 'package:template/app/routing/app_route.dart';
import 'package:template/app/routing/app_route_fallback.dart';
import 'package:template/feature/not_found/routing/not_found_route.dart';

/// Applies application input policy around the canonical Rolter URL grammar.
///
/// The delegate remains responsible for encoding and decoding route data. This
/// decorator adds only bounded-input and decoded-tree validation so malformed
/// external locations become one privacy-safe recovery route instead of a
/// partially valid or duplicate-key stack.
final class AppRouteUrlCodec implements RouteUrlCodec<AppRoute> {
  /// Creates a validating codec over the supplied canonical codec.
  const AppRouteUrlCodec(this._delegate);

  static const _maxLocationLength = 4096;
  static const _maxPathSegmentCount = 32;

  final RouteUrlCodec<AppRoute> _delegate;

  @override
  Uri encode(List<AppRoute> roots) => _delegate.encode(roots);

  @override
  List<AppRoute> decode(Uri uri) {
    if (uri.toString().length > _maxLocationLength ||
        uri.path.split('/').where((segment) => segment.isNotEmpty).length >
            _maxPathSegmentCount ||
        _hasInvalidOrDuplicateParameters(uri)) {
      return _invalidTree;
    }

    final decoded = _delegate.decode(_normalizeEntryQuery(uri));
    final pageKeys = <LocalKey>{};
    var nodeCount = 0;
    var fallbackCount = 0;
    var hasDuplicatePageKey = false;

    void visit(List<AppRoute> routes) {
      for (final route in routes) {
        nodeCount++;
        if (route is NotFoundRoute) {
          fallbackCount++;
        }
        if (!pageKeys.add(route.pageKey)) {
          hasDuplicatePageKey = true;
        }
        visit(route.children);
      }
    }

    visit(decoded);
    final isStandaloneFallback = nodeCount == 1 && fallbackCount == 1;
    if (hasDuplicatePageKey || fallbackCount > 0 && !isStandaloneFallback) {
      return _invalidTree;
    }

    return List<AppRoute>.unmodifiable(decoded);
  }

  /// Detects ambiguous parameter input without wrapping the trusted delegate.
  ///
  /// Standard query and inline parameters are separate channels because the
  /// canonical inline value has documented precedence. Repetition is rejected
  /// only within one channel and, for inline parameters, within one route
  /// segment. The scanner follows Rolter's raw segment grammar so encoded
  /// delimiters are not mistaken for structure.
  bool _hasInvalidOrDuplicateParameters(Uri uri) {
    if (_hasInvalidOrDuplicateParameterChannel(
      uri.query,
      isStandardQuery: true,
    )) {
      return true;
    }

    for (final segment in uri.path.split('/')) {
      final tildeIndex = segment.indexOf('~');
      if (tildeIndex >= 0 &&
          _hasInvalidOrDuplicateParameterChannel(
            segment.substring(tildeIndex + 1),
            isStandardQuery: false,
          )) {
        return true;
      }
    }

    return false;
  }

  bool _hasInvalidOrDuplicateParameterChannel(
    String source, {
    required bool isStandardQuery,
  }) {
    final keys = <String>{};

    for (final part in source.split('&')) {
      final separatorIndex = part.indexOf('=');
      if (separatorIndex <= 0) {
        continue;
      }

      final key = _decodeParameterComponent(
        part.substring(0, separatorIndex),
        isStandardQuery: isStandardQuery,
      );
      final value = _decodeParameterComponent(
        part.substring(separatorIndex + 1),
        isStandardQuery: isStandardQuery,
      );
      if (key == null || value == null || !keys.add(key)) {
        return true;
      }
    }

    return false;
  }

  String? _decodeParameterComponent(
    String source, {
    required bool isStandardQuery,
  }) {
    try {
      return isStandardQuery
          ? Uri.decodeQueryComponent(source)
          : Uri.decodeComponent(source);
    } on ArgumentError {
      return null;
    }
  }

  /// Moves a standard query onto the last root segment when that segment has
  /// no inline parameters yet.
  ///
  /// `TreeUrlCodec` normally merges a query after its first decode. A route
  /// with a required parameter cannot survive that first decode, so this
  /// narrow compatibility step supplies the same data in Rolter's canonical
  /// inline grammar. Existing inline parameters remain authoritative and are
  /// left for the delegate's normal merge behavior.
  Uri _normalizeEntryQuery(Uri uri) {
    if (uri.queryParameters.isEmpty) {
      return uri;
    }

    final segments = uri.path.split('/');
    final rootIndex = segments.lastIndexWhere(
      (segment) => segment.isNotEmpty && !segment.startsWith('.'),
    );
    if (rootIndex < 0 || segments[rootIndex].contains('~')) {
      return uri;
    }

    final queryEntries = uri.queryParameters.entries.toList()
      ..sort((left, right) => left.key.compareTo(right.key));
    final inlineQuery = queryEntries
        .map(
          (entry) =>
              '${_encodeQueryComponent(entry.key)}='
              '${_encodeQueryComponent(entry.value)}',
        )
        .join('&');
    segments[rootIndex] = '${segments[rootIndex]}~$inlineQuery';

    return Uri.parse(segments.join('/'));
  }

  static String _encodeQueryComponent(String value) =>
      Uri.encodeComponent(value).replaceAll('~', '%7E');

  static const List<AppRoute> _invalidTree = <AppRoute>[
    NotFoundRoute(reason: AppRouteFailureReason.invalidRouteTree),
  ];
}
