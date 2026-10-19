import 'package:flutter/widgets.dart';

import '../data/collection_store.dart';
import '../data/settings_store.dart';
import '../models/catalog.dart';
import 'ads.dart';

/// Adds one copy of [card] and shows the full-screen ad every 3rd add.
void addCardToCollection(
  BuildContext context,
  CatalogCard card, {
  String? photoPath,
}) {
  CollectionScope.of(context).addCopy(card, photoPath: photoPath);
  final adDue = SettingsScope.of(context).countAddForAd();
  if (adDue) AdsScope.of(context).showInterstitial();
}
