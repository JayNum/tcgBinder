# TCG Binder

A digital binder for trading card collections — Pokémon, Magic, One Piece,
Lorcana and Riftbound. Cards are filed into 9-pocket binder pages using the
collector's own photos; missing cards show as empty pockets with their number
and name. Everything stays on the phone.

## First-time setup (Windows)

1. Install Flutter (see the setup script from the chat) and run `flutter doctor`.
2. Clone this repository and open a terminal in it.
3. Generate the Android and iOS project folders (only once):

   ```powershell
   flutter create --org com.jaynum --project-name tcg_binder --platforms=android,ios .
   ```

   This only adds missing files; it does not touch `lib/` or `test/`.
4. Get packages, check, and run:

   ```powershell
   flutter pub get
   flutter analyze
   flutter test
   flutter run
   ```

5. Commit the new `android/` and `ios/` folders.

In Android Studio: install the **Flutter** plugin (Settings → Plugins), open
this folder, set the Flutter SDK path to `C:\Users\<you>\dev\flutter`, pick an
emulator from Device Manager and press Run.

## What's in v0.1

- Shelf of binders with completion progress
- Set binder: swipeable 9-pocket pages, number above / name below each pocket,
  owned / owned-without-photo / missing states, quantity badges
- Card detail: quantity, condition (Cardmarket scale), edition, language,
  and **Check prices** links to Cardmarket, TCGplayer and eBay sold listings
  (no prices are shown or stored in the app)
- Settings: collection stats, Premium offer, backup & transfer entries
- Light and dark mode following the system
- A small sample catalog (Base Set #1–22) and demo collection

## Project layout

```
lib/
  app.dart                 MaterialApp, themes, collection scope
  theme/app_theme.dart     colors and tokens from the design mockups
  models/                  catalog (games, sets, cards) and collection entries
  data/                    sample catalog, in-memory collection store
  services/price_links.dart marketplace links
  screens/                 shelf, binder, card detail, settings, scan
  widgets/                 pocket, card photo, ad banner placeholder
```

## Roadmap

1. Local database (Drift/SQLite) for the collection
2. Catalog import for all five games (Scryfall, pokemontcg.io, optcgapi,
   Lorcast, Riftcodex) published as a static file
3. Scanning: camera + ML Kit text recognition of set code and number,
   auto-crop, confirm sheet
4. AdMob banner + interstitial every 3rd added card, UMP consent
5. Premium via RevenueCat (€2.99/month, €29.99/year): no ads, backup export,
   binder customization
6. QR transfer to a new phone, backup export/import
