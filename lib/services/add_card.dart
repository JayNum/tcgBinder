import 'package:flutter/widgets.dart';

import '../data/collection_store.dart';
import '../models/catalog.dart';

/// Adds one copy of [card] to the collection.
void addCardToCollection(
  BuildContext context,
  CatalogCard card, {
  String? photoPath,
}) {
  CollectionScope.of(context).addCopy(card, photoPath: photoPath);
}
