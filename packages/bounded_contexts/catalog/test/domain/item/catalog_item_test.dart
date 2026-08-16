import 'package:catalog/catalog.dart';
import 'package:test/test.dart';

void main() {
  test('reconstitutes a valid immutable product entity', () {
    final item = _item();

    expect(item.id, 1);
    expect(item.title.value, 'Product');
    expect(item.description.value, 'Description');
    expect(item.price.minorUnits, 2500);
    expect(item.price.currencyCode, 'USD');
    expect(item.status, CatalogItemStatus.draft);
    expect(item.categoryId, 7);
    expect(item.revision.value, 0);
  });

  test('strictly rejects invalid persisted identity and category', () {
    for (final values in <(int, int?)>[(0, 1), (-1, 1), (1, 0), (1, -1)]) {
      expect(
        () => _item(id: values.$1, categoryId: values.$2),
        throwsA(isA<CatalogDataIntegrityException>()),
      );
    }
  });

  test('strictly rejects incomplete persisted non-draft offers', () {
    for (final values
        in <({String description, int price, String currency, int? category})>[
          (
            description: '',
            price: 2500,
            currency: 'USD',
            category: 7,
          ),
          (
            description: 'Description',
            price: 0,
            currency: 'USD',
            category: 7,
          ),
          (
            description: 'Description',
            price: 2500,
            currency: 'XXX',
            category: 7,
          ),
          (
            description: 'Description',
            price: 2500,
            currency: 'USD',
            category: null,
          ),
        ]) {
      expect(
        () => _item(
          description: values.description,
          priceMinorUnits: values.price,
          currencyCode: values.currency,
          categoryId: values.category,
          statusValue: CatalogItemStatus.published.value,
        ),
        throwsA(isA<CatalogDataIntegrityException>()),
      );
      expect(
        () => _item(
          description: values.description,
          priceMinorUnits: values.price,
          currencyCode: values.currency,
          categoryId: values.category,
          statusValue: CatalogItemStatus.archived.value,
        ),
        throwsA(isA<CatalogDataIntegrityException>()),
      );
    }
  });

  test('uses stable identity rather than renderable fields for equality', () {
    final original = _item();
    final changed = _item(
      title: 'Changed',
      statusValue: CatalogItemStatus.published.value,
    );
    final other = _item(id: 2);

    expect(original, changed);
    expect(original.hashCode, changed.hashCode);
    expect(original, isNot(other));
  });

  test('archives only a published item', () {
    final published = _item(
      statusValue: CatalogItemStatus.published.value,
    );

    expect(published.archive().status, CatalogItemStatus.archived);
    expect(
      _item().archive,
      throwsA(
        isA<CatalogItemTransitionException>().having(
          (error) => error.failure,
          'failure',
          CatalogItemTransitionFailure.itemNotPublished,
        ),
      ),
    );
  });

  test('revises product details only while the item is a draft', () {
    final revised = _item().reviseDraft(
      title: CatalogItemTitle.fromUserInput('Revised product'),
      description: CatalogItemDescription.fromUserInput('New description'),
      price: CatalogItemPrice.fromUserInput(
        minorUnits: 3000,
        currencyCode: 'EUR',
      ),
      categoryId: null,
    );

    expect(revised.id, 1);
    expect(revised.title.value, 'Revised product');
    expect(revised.description.value, 'New description');
    expect(revised.price.minorUnits, 3000);
    expect(revised.categoryId, isNull);
    expect(
      () =>
          _item(
            statusValue: CatalogItemStatus.published.value,
          ).reviseDraft(
            title: CatalogItemTitle.fromUserInput('Revised product'),
            description: CatalogItemDescription.fromUserInput(
              'New description',
            ),
            price: CatalogItemPrice.fromUserInput(
              minorUnits: 3000,
              currencyCode: 'EUR',
            ),
            categoryId: null,
          ),
      throwsA(
        isA<CatalogItemTransitionException>().having(
          (error) => error.failure,
          'failure',
          CatalogItemTransitionFailure.itemNotDraft,
        ),
      ),
    );
  });

  test('published offer revision preserves intrinsic offer invariants', () {
    final published = _item(
      statusValue: CatalogItemStatus.published.value,
    );
    final title = CatalogItemTitle.fromUserInput('Revised product');

    for (final values
        in <
          ({
            CatalogItemDescription description,
            CatalogItemPrice price,
            CatalogItemPublicationFailure failure,
          })
        >[
          (
            description: CatalogItemDescription.fromUserInput(''),
            price: CatalogItemPrice.fromUserInput(
              minorUnits: 3000,
              currencyCode: 'EUR',
            ),
            failure: CatalogItemPublicationFailure.descriptionRequired,
          ),
          (
            description: CatalogItemDescription.fromUserInput('Description'),
            price: CatalogItemPrice.fromUserInput(
              minorUnits: 0,
              currencyCode: 'EUR',
            ),
            failure: CatalogItemPublicationFailure.positivePriceRequired,
          ),
          (
            description: CatalogItemDescription.fromUserInput('Description'),
            price: CatalogItemPrice.fromUserInput(
              minorUnits: 3000,
              currencyCode: 'XXX',
            ),
            failure: CatalogItemPublicationFailure.concreteCurrencyRequired,
          ),
        ]) {
      expect(
        () => published.revisePublishedOffer(
          title: title,
          description: values.description,
          price: values.price,
          categoryId: 7,
        ),
        throwsA(
          isA<CatalogItemPublicationException>().having(
            (error) => error.failure,
            'failure',
            values.failure,
          ),
        ),
      );
    }
  });
}

CatalogItem _item({
  int id = 1,
  String title = 'Product',
  String description = 'Description',
  int priceMinorUnits = 2500,
  String currencyCode = 'USD',
  int statusValue = 0,
  int? categoryId = 7,
}) => CatalogItem.fromValues(
  id: id,
  title: title,
  description: description,
  priceMinorUnits: priceMinorUnits,
  currencyCode: currencyCode,
  statusValue: statusValue,
  categoryId: categoryId,
  revision: 0,
);
