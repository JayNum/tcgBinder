import 'package:flutter/widgets.dart';

import 'catalog_repository.dart';

class CatalogScope extends InheritedNotifier<CatalogRepository> {
  const CatalogScope({
    super.key,
    required CatalogRepository repository,
    required super.child,
  }) : super(notifier: repository);

  static CatalogRepository of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<CatalogScope>();
    assert(scope != null, 'No CatalogScope above this widget');
    return scope!.notifier!;
  }
}
