import 'package:go_router/go_router.dart';
import 'package:template/app/di/app_dependencies.dart';
import 'package:template/feature/activity/di/activity_scope.dart';
import 'package:template/feature/activity/view/activity_screen.dart';
import 'package:template/feature/catalog/di/catalog_scope.dart';
import 'package:template/feature/catalog/view/catalog_screen.dart';
import 'package:template/feature/demo/view/demo_screen.dart';
import 'package:template/feature/not_found/view/not_found_screen.dart';
import 'package:template/feature/orders/di/orders_scope.dart';
import 'package:template/feature/orders/view/orders_screen.dart';

const _rootPath = '/';
const _activityPath = 'activity/:sequence';
const _catalogPath = 'catalog';
const _ordersPath = 'orders';
const _activityLocationPrefix = '/activity/';
const _catalogLocation = '/catalog';
const _ordersLocation = '/orders';
const _maxActivitySequence = 2147483647;
final _canonicalActivitySequence = RegExp(r'^[1-9][0-9]{0,9}$');

/// Creates one application-owned router over borrowed graph dependencies.
///
/// The returned router is synchronous to construct and owned by the root
/// `App` State. This factory starts no work and retains no disposal authority
/// over [dependencies].
GoRouter createAppRouter({required AppDependencies dependencies}) => GoRouter(
  routes: <RouteBase>[
    GoRoute(
      path: _rootPath,
      builder: (context, state) {
        if (state.uri.path == _rootPath && _hasUnsupportedSuffix(state.uri)) {
          return const NotFoundScreen();
        }

        return DemoScreen(
          onOpenActivity: (sequence) =>
              context.push<void>(_activityLocation(sequence)),
          onOpenCatalog: () => context.push<void>(_catalogLocation),
          onOpenOrders: () => context.push<void>(_ordersLocation),
        );
      },
      routes: <RouteBase>[
        GoRoute(
          path: _activityPath,
          builder: (context, state) {
            final sequence = _parseActivitySequence(state);
            if (sequence == null || _hasUnsupportedSuffix(state.uri)) {
              return const NotFoundScreen();
            }

            return ActivityScope(
              eventBus: dependencies.eventSubscriber,
              child: ActivityScreen(highlightSequence: sequence),
            );
          },
        ),
        GoRoute(
          path: _catalogPath,
          builder: (context, state) => _hasUnsupportedSuffix(state.uri)
              ? const NotFoundScreen()
              : CatalogScope(
                  catalog: dependencies.catalog,
                  child: const CatalogScreen(),
                ),
        ),
        GoRoute(
          path: _ordersPath,
          builder: (context, state) => _hasUnsupportedSuffix(state.uri)
              ? const NotFoundScreen()
              : OrdersScope(
                  ordering: dependencies.ordering,
                  eventPublisher: dependencies.eventPublisher,
                  child: OrdersScreen(
                    onMonitorDraftCreation: (sequence) =>
                        context.push<void>(_activityLocation(sequence)),
                  ),
                ),
        ),
      ],
    ),
  ],
  errorBuilder: (context, state) => const NotFoundScreen(),
  restorationScopeId: 'app-router',
);

bool _hasUnsupportedSuffix(Uri uri) => uri.hasQuery || uri.hasFragment;

int? _parseActivitySequence(GoRouterState state) {
  final encoded = state.pathParameters['sequence'];
  if (encoded == null || !_canonicalActivitySequence.hasMatch(encoded)) {
    return null;
  }
  final sequence = int.tryParse(encoded);
  if (sequence == null || sequence > _maxActivitySequence) {
    return null;
  }

  return sequence;
}

String _activityLocation(int sequence) {
  if (sequence <= 0 || sequence > _maxActivitySequence) {
    throw ArgumentError(
      'Activity sequence must be between 1 and 2147483647.',
    );
  }

  return '$_activityLocationPrefix$sequence';
}
