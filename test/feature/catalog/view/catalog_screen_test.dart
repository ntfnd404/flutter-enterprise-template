import 'package:catalog/catalog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:template/feature/catalog/di/catalog_scope.dart';
import 'package:template/feature/catalog/view/catalog_screen.dart';

import '../support/recording_catalog_facade.dart';

void main() {
  testWidgets('creates its BLoC below scope and submits product drafts', (
    tester,
  ) async {
    final facade = RecordingCatalogFacade();
    addTearDown(facade.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: CatalogScope(
          catalog: facade,
          child: const CatalogScreen(),
        ),
      ),
    );
    await facade.whenWatchStarted;
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    facade.emitItems(const []);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('catalog-empty')),
      findsOneWidget,
    );
    expect(
      tester
          .getTopLeft(
            find.byKey(const ValueKey<String>('catalog-currency-field')),
          )
          .dx,
      greaterThan(
        tester
            .getTopLeft(
              find.byKey(const ValueKey<String>('catalog-price-field')),
            )
            .dx,
      ),
    );

    await tester.enterText(
      find.byKey(const ValueKey<String>('catalog-title-field')),
      'New item',
    );
    await tester.enterText(
      find.byKey(const ValueKey<String>('catalog-description-field')),
      'Description',
    );
    await tester.enterText(
      find.byKey(const ValueKey<String>('catalog-price-field')),
      '2500',
    );
    await tester.tap(find.byKey(const ValueKey<String>('catalog-add-item')));
    await tester.pump();

    expect(facade.createdDrafts.single.title, 'New item');
    expect(facade.createdDrafts.single.description, 'Description');
    expect(facade.createdDrafts.single.priceMinorUnits, 2500);
    expect(facade.createdDrafts.single.currencyCode, 'USD');
  });

  testWidgets('keeps draft controls usable in a narrow window', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final facade = RecordingCatalogFacade();
    addTearDown(facade.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: CatalogScope(
          catalog: facade,
          child: const CatalogScreen(),
        ),
      ),
    );
    await facade.whenWatchStarted;
    facade.emitItems(const <CatalogItem>[]);
    await tester.pumpAndSettle();

    final price = find.byKey(
      const ValueKey<String>('catalog-price-field'),
    );
    final currency = find.byKey(
      const ValueKey<String>('catalog-currency-field'),
    );
    final submit = find.byKey(const ValueKey<String>('catalog-add-item'));
    expect(tester.takeException(), isNull);
    expect(
      tester.getTopLeft(currency).dy,
      greaterThan(tester.getTopLeft(price).dy),
    );
    expect(
      tester.getTopLeft(submit).dy,
      greaterThan(tester.getTopLeft(currency).dy),
    );
    expect(tester.getSize(submit).width, tester.getSize(price).width);

    await tester.enterText(
      find.byKey(const ValueKey<String>('catalog-title-field')),
      'Compact item',
    );
    await tester.enterText(
      find.byKey(const ValueKey<String>('catalog-description-field')),
      'Compact description',
    );
    await tester.enterText(price, '1200');
    await tester.tap(submit);
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(facade.createdDrafts.single.title, 'Compact item');
    expect(facade.createdDrafts.single.priceMinorUnits, 1200);
    expect(facade.createdDrafts.single.currencyCode, 'USD');
  });

  testWidgets('uses the domain grapheme limit for text input', (tester) async {
    final facade = RecordingCatalogFacade();
    addTearDown(facade.dispose);
    const grapheme = '👨‍👩‍👦';
    final accepted = List<String>.filled(
      CatalogItemTitle.maxLength,
      grapheme,
    ).join();

    await tester.pumpWidget(
      MaterialApp(
        home: CatalogScope(
          catalog: facade,
          child: const CatalogScreen(),
        ),
      ),
    );
    await facade.whenWatchStarted;
    facade.emitItems(const <CatalogItem>[]);
    await tester.pumpAndSettle();

    final fieldFinder = find.byKey(
      const ValueKey<String>('catalog-title-field'),
    );
    expect(
      tester.widget<TextField>(fieldFinder).maxLength,
      CatalogItemTitle.maxLength,
    );
    expect(
      tester
          .widget<TextField>(
            find.byKey(
              const ValueKey<String>('catalog-description-field'),
            ),
          )
          .maxLength,
      CatalogItemDescription.maxLength,
    );
    expect(
      tester
          .widget<TextField>(
            find.byKey(const ValueKey<String>('catalog-currency-field')),
          )
          .maxLength,
      CatalogItemPrice.currencyCodeLength,
    );

    await tester.enterText(fieldFinder, '$accepted$grapheme');

    expect(tester.widget<TextField>(fieldFinder).controller!.text, accepted);
  });

  testWidgets('shows persistent unavailability and retries observation', (
    tester,
  ) async {
    final facade = RecordingCatalogFacade();
    addTearDown(facade.dispose);
    final item = _item();

    await tester.pumpWidget(
      MaterialApp(
        home: CatalogScope(
          catalog: facade,
          child: const CatalogScreen(),
        ),
      ),
    );
    await facade.whenWatchStarted;
    facade.emitItems(<CatalogItem>[item]);
    await tester.pumpAndSettle();
    await facade.emitError(const CatalogPersistenceException());
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('catalog-unavailable')),
      findsOneWidget,
    );
    expect(find.text('Persisted item'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('catalog-retry')));
    await facade.waitForWatchCount(2);
    await tester.pump();
    expect(
      find.byKey(const ValueKey<String>('catalog-loading-progress')),
      findsOneWidget,
    );

    facade.emitItems(<CatalogItem>[item]);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('catalog-unavailable')),
      findsNothing,
    );
  });

  testWidgets('shows command failures as one-shot SnackBars', (tester) async {
    final facade = RecordingCatalogFacade()
      ..addFailure = const CatalogInvalidTitleException();
    addTearDown(facade.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: CatalogScope(
          catalog: facade,
          child: const CatalogScreen(),
        ),
      ),
    );
    await facade.whenWatchStarted;
    facade.emitItems(const <CatalogItem>[]);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey<String>('catalog-title-field')),
      ' ',
    );
    await tester.tap(find.byKey(const ValueKey<String>('catalog-add-item')));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Enter a title from 1 to '
        '${CatalogItemTitle.maxLength} characters.',
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('catalog-unavailable')),
      findsNothing,
    );
  });
}

CatalogItem _item() => CatalogItem.fromValues(
  id: 1,
  title: 'Persisted item',
  description: 'Description',
  priceMinorUnits: 100,
  currencyCode: 'USD',
  statusValue: CatalogItemStatus.draft.value,
  categoryId: null,
  revision: 0,
);
