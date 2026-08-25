import 'package:catalog/catalog.dart';
import 'package:flutter/widgets.dart';
import 'package:template/core/di/typedefs/factory.dart';
import 'package:template/feature/catalog/bloc/catalog_bloc.dart';

/// Factory-only composition boundary for catalog presentation.
final class CatalogScope extends StatelessWidget {
  /// Creates a scope that captures only the catalog application facade.
  const CatalogScope({
    required this.catalog,
    required this.child,
    super.key,
  });

  /// Creates a new BLoC from the nearest catalog scope.
  static CatalogBloc createBloc(BuildContext context) {
    final scope = context
        .getInheritedWidgetOfExactType<_InheritedCatalogScope>();
    if (scope == null) {
      throw StateError('CatalogScope not found in widget tree.');
    }

    return scope.blocFactory();
  }

  /// Narrow application API captured by this feature boundary.
  final CatalogFacade catalog;

  /// Feature subtree allowed to request BLoC instances.
  final Widget child;

  CatalogBloc _createBloc() => CatalogBloc(catalog: catalog);

  @override
  Widget build(BuildContext context) => _InheritedCatalogScope(
    blocFactory: _createBloc,
    child: child,
  );
}

final class _InheritedCatalogScope extends InheritedWidget {
  const _InheritedCatalogScope({
    required this.blocFactory,
    required super.child,
  });

  final Factory<CatalogBloc> blocFactory;

  @override
  bool updateShouldNotify(_InheritedCatalogScope oldWidget) => false;
}
