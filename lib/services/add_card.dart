import 'package:flutter/widgets.dart';

import '../data/collection_store.dart';
import '../data/settings_store.dart';
import '../models/catalog.dart';
import 'ads.dart';

/// Adds one copy of [card] to the collection. The first card added each day
/// also brings the day's full-screen video ad (Pro users never see it).
void addCardToCollection(
  BuildContext context,
  CatalogCard card, {
  String? photoPath,
  String? language,
}) {
  final store = CollectionScope.of(context);
  final settings = SettingsScope.of(context);
  final ads = AdsScope.of(context);
  store.addCopy(card, photoPath: photoPath, language: language);
  if (settings.fullScreenAdDue && ads.showInterstitial()) {
    settings.markFullScreenAdShown();
  }
}
