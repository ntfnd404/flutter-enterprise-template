import 'package:catalog/catalog.dart';
import 'package:ephemeral_bloc/ephemeral_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:template/feature/catalog/bloc/catalog_bloc.dart';
import 'package:template/feature/catalog/di/catalog_scope.dart';

/// Catalog screen demonstrating facade-to-BLoC constructor injection.
final class CatalogScreen extends StatelessWidget {
  /// Creates the catalog screen.
  const CatalogScreen({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider<CatalogBloc>(
    create: (_) =>
        CatalogScope.createBloc(context)..add(const CatalogStarted()),
    child: const _CatalogView(),
  );
}

final class _CatalogView extends StatefulWidget {
  const _CatalogView();

  @override
  State<_CatalogView> createState() => _CatalogViewState();
}

final class _CatalogViewState extends State<_CatalogView> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _currencyController = TextEditingController(
    text: 'USD',
  );

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _currencyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      EphemeralBlocListener<CatalogBloc, CatalogState, CatalogAction>(
        listener: _onAction,
        child: Scaffold(
          appBar: AppBar(title: const Text('Catalog')),
          body: BlocBuilder<CatalogBloc, CatalogState>(
            builder: (context, state) {
              if (state.isLoading && state.items.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              return Column(
                children: <Widget>[
                  if (state.isLoading)
                    const LinearProgressIndicator(
                      key: ValueKey<String>('catalog-loading-progress'),
                    ),
                  if (state.observationStatus ==
                      CatalogObservationStatus.unavailable)
                    const _CatalogUnavailablePanel(),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: <Widget>[
                        TextField(
                          key: const ValueKey<String>('catalog-title-field'),
                          controller: _titleController,
                          maxLength: CatalogItemTitle.maxLength,
                          decoration: const InputDecoration(
                            labelText: 'Product title',
                          ),
                        ),
                        TextField(
                          key: const ValueKey<String>(
                            'catalog-description-field',
                          ),
                          controller: _descriptionController,
                          maxLength: CatalogItemDescription.maxLength,
                          decoration: const InputDecoration(
                            labelText: 'Description',
                          ),
                        ),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: TextField(
                                key: const ValueKey<String>(
                                  'catalog-price-field',
                                ),
                                controller: _priceController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Price in minor units',
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 96,
                              child: TextField(
                                key: const ValueKey<String>(
                                  'catalog-currency-field',
                                ),
                                controller: _currencyController,
                                maxLength: CatalogItemPrice.currencyCodeLength,
                                decoration: const InputDecoration(
                                  labelText: 'Currency',
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            FilledButton(
                              key: const ValueKey<String>(
                                'catalog-add-item',
                              ),
                              onPressed: () => _addDraft(context),
                              child: const Text('Create draft'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: state.items.isEmpty
                        ? const Center(
                            child: Text(
                              'No catalog items',
                              key: ValueKey<String>('catalog-empty'),
                            ),
                          )
                        : ListView.builder(
                            itemCount: state.items.length,
                            itemBuilder: (context, index) {
                              final item = state.items[index];

                              return ListTile(
                                key: ValueKey<String>(
                                  'catalog-item-${item.id}',
                                ),
                                leading: Icon(
                                  switch (item.status) {
                                    CatalogItemStatus.draft => Icons.edit_note,
                                    CatalogItemStatus.published =>
                                      Icons.check_circle_outline,
                                    CatalogItemStatus.archived =>
                                      Icons.archive_outlined,
                                  },
                                ),
                                title: Text(item.title.value),
                                subtitle: Text(
                                  '${item.description.value}\n'
                                  '${item.price.minorUnits} '
                                  '${item.price.currencyCode} · '
                                  '${item.status.name}',
                                ),
                                trailing: item.status == CatalogItemStatus.draft
                                    ? IconButton(
                                        tooltip: 'Delete item',
                                        onPressed: () =>
                                            context.read<CatalogBloc>().add(
                                              CatalogItemDeleted(
                                                id: item.id,
                                                expectedRevision: item.revision,
                                              ),
                                            ),
                                        icon: const Icon(
                                          Icons.delete_outline,
                                        ),
                                      )
                                    : null,
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      );

  void _addDraft(BuildContext context) {
    context.read<CatalogBloc>().add(
      CatalogDraftCreated(
        title: _titleController.text,
        description: _descriptionController.text,
        priceMinorUnits: int.tryParse(_priceController.text) ?? -1,
        currencyCode: _currencyController.text,
      ),
    );
    _titleController.clear();
    _descriptionController.clear();
    _priceController.clear();
  }

  void _onAction(BuildContext context, CatalogAction action) {
    switch (action) {
      case ShowCatalogFailureAction(:final failure):
        final message = switch (failure) {
          CatalogFailure.invalidTitle =>
            'Enter a title from 1 to '
                '${CatalogItemTitle.maxLength} characters.',
          CatalogFailure.invalidDescription =>
            'Description must not exceed '
                '${CatalogItemDescription.maxLength} characters.',
          CatalogFailure.invalidPrice =>
            'Enter a non-negative minor-unit price and a '
                '${CatalogItemPrice.currencyCodeLength}-letter currency code.',
          CatalogFailure.itemNotFound => 'The item no longer exists.',
          CatalogFailure.itemChanged =>
            'The item changed. Review the latest state and try again.',
          CatalogFailure.storageUnavailable =>
            'Catalog storage is temporarily unavailable.',
        };
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(message)));
    }
  }
}

final class _CatalogUnavailablePanel extends StatelessWidget {
  const _CatalogUnavailablePanel();

  @override
  Widget build(BuildContext context) => Material(
    key: const ValueKey<String>('catalog-unavailable'),
    color: Theme.of(context).colorScheme.errorContainer,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: <Widget>[
          const Expanded(
            child: Text('Catalog updates are temporarily unavailable.'),
          ),
          TextButton(
            key: const ValueKey<String>('catalog-retry'),
            onPressed: () => context.read<CatalogBloc>().add(
              const CatalogRetryRequested(),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    ),
  );
}
