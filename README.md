# TCG Binder

A digital binder for trading card collections: One Piece, Pokémon, Magic,
Lorcana and Riftbound. Every set is its own binder with 9-pocket pages;
cards you own show your own photo, missing cards show their number and name.
Everything stays on the phone.

## Features (v0.3)

- **Look:** follows iOS conventions (large titles, grouped lists, action
  sheets, swipe back, translucent tab bar), in light and dark.
- **Tab bar:** Favorites, **Scan**, Binders, Settings. Each tab keeps its own
  screens, so the bar and the Scan button stay visible everywhere.
- **Favorites:** cards you gave a heart turn slowly on a carousel; drag it to
  spin it yourself, tap the front card to open it.
- **Binders tab:** one tile per game (long-press a tile to use your own image,
  Arrange to reorder or hide games) and a search for single cards.
- **Search and labels:** search cards by name, code, set or rarity (all
  downloaded sets). Give cards your own labels ("Trade", "Deck"...) on the
  card page and switch labels on as filters to see only those cards.
- **Game → sets:** every set of the game as a binder, empty by default.
  Filter by boosters / extra boosters / starter decks / promos; sort by
  newest, oldest or name.
- **Binders:** card lists are downloaded the first time you open a set and
  kept offline. Alt arts and parallels are tagged (P1, Alt art…); reprints of
  older cards sit at the end of the binder of the set they come in.
- **Scanner:** point the camera at a card and tap the shutter. The app reads
  the card number (ML Kit text recognition, on the phone), finds the card,
  crops the photo to the card and files it into the right binder. When a
  number has several versions you pick yours.
- **Card detail:** your photo, all versions of the card (with the set each
  comes from and whether you own it), quantity, condition, edition, language,
  and links to Cardmarket, TCGplayer and eBay sold listings.
- **Ads:** AdMob banner + a full-screen ad after every 3rd card added, with
  the EU consent prompt. Uses Google's **test** ad IDs for now.

## Card data

| Game | Source |
|---|---|
| One Piece | optcgapi.com |
| Pokémon | api.pokemontcg.io |
| Magic | api.scryfall.com |
| Lorcana | api.lorcast.com |
| Riftbound | api.riftcodex.com |

All are free and need no API key. The code for each is in
`lib/catalog/sources/`.

## Before publishing

- Replace the AdMob **test** IDs with your own: app IDs in
  `android/app/src/main/AndroidManifest.xml` and `ios/Runner/Info.plist`,
  unit IDs in `lib/services/ads.dart`.
- Premium (no ads, backup export, binder customization) via RevenueCat.
- Move to a new phone (QR) and backup export / import.

## Development

Open the project in Android Studio with the Flutter plugin, then:

- `pubspec.yaml` → **Pub get**
- Right-click `test` → **Run 'Tests in test'**
- Pick a device and press **Run**. The scanner needs a real camera: on the
  emulator it shows the emulator's virtual scene; a real phone works best.

## Project layout

```
lib/
  main.dart / app.dart        start-up, stores, themes
  catalog/                    games, downloaders per database, offline cache
  data/                       collection + settings saved on the phone
  models/                     sets, cards, collection entries
  scanner/                    reading card numbers + matching cards
  screens/                    home, game sets, binder, card detail, scan, settings
  services/                   ads, photos, marketplace links
  widgets/                    pocket, card photo
```
