import 'package:catalog/catalog.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:template/feature/catalog/bloc/catalog_bloc.dart';

/// Route-lifetime owner that narrows the Catalog application facade.
final class CatalogScope extends StatelessWidget {
  /// Creates a Catalog feature scope.
  const CatalogScope({
    required this.catalog,
    required this.child,
    super.key,
  });

  /// Borrowed Catalog application facade.
  final CatalogFacade catalog;

  /// Feature subtree whose BLoC is owned by this provider.
  final Widget child;

  @override
  Widget build(BuildContext context) => BlocProvider<CatalogBloc>(
    create: (_) => CatalogBloc(catalog: catalog)..add(const CatalogStarted()),
    child: child,
  );
}
