import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'app.dart';
import 'catalog/catalog_repository.dart';
import 'data/collection_store.dart';
import 'data/settings_store.dart';
import 'services/ads.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // The app is made for holding the phone upright, like a binder page.
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Collection, photos and settings: the user's data, kept in Documents.
  final docs = await getApplicationDocumentsDirectory();
  final photos = Directory(p.join(docs.path, 'photos'));
  final gameImages = Directory(p.join(docs.path, 'game_images'));
  await photos.create(recursive: true);
  await gameImages.create(recursive: true);

  // Downloaded card lists: can always be downloaded again.
  final support = await getApplicationSupportDirectory();

  final collection = CollectionStore(
    file: File(p.join(docs.path, 'collection.json')),
    photoDir: photos,
  );
  final settings = SettingsStore(
    file: File(p.join(docs.path, 'settings.json')),
    imageDir: gameImages,
  );
  final catalog = CatalogRepository.live(
    Directory(p.join(support.path, 'catalog')),
  );
  await Future.wait([collection.load(), settings.load(), catalog.loadCache()]);

  final ads = AdsService(enabled: Platform.isAndroid || Platform.isIOS);

  runApp(TcgBinderApp(
    collection: collection,
    settings: settings,
    catalog: catalog,
    ads: ads,
  ));

  // Consent prompt and AdMob start after the first frame.
  unawaited(ads.init());
}
