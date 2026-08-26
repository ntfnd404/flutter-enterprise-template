import 'package:flutter_test/flutter_test.dart';
import 'package:template/core/di/typedefs/factory.dart';

void main() {
  test('Factory creates an independently owned instance on every call', () {
    final exampleFactory = _ExampleFactory();
    final Factory<_ExampleDependency> factory = exampleFactory.create;

    final first = factory();
    final second = factory();

    expect(first.id, 1);
    expect(second.id, 2);
    expect(identical(first, second), isFalse);
  });

  test('ParamFactory passes a runtime parameter into construction', () {
    const ParamFactory<_ExampleDependency, int> factory =
        _ExampleDependency.new;

    final dependency = factory(42);

    expect(dependency.id, 42);
  });
}

final class _ExampleFactory {
  int _nextId = 0;

  _ExampleDependency create() => _ExampleDependency(++_nextId);
}

final class _ExampleDependency {
  const _ExampleDependency(this.id);

  final int id;
}
