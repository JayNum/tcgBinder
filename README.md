# leBinder

A digital binder for trading card collections: One Piece, Pokémon, Magic,
Lorcana and Riftbound. Every set is its own binder with 9-pocket pages;
cards you own show your own photo, missing cards show their number and name.
Everything stays on the phone.

## Features (v0.4)

- **Look:** follows iOS conventions (large titles, grouped lists, action
  sheets, swipe back, translucent tab bar), in light and dark.
- **Tab bar:** Favorites, Binders, a big **Scan** button in the middle,
  Search, Settings. Each tab keeps its own screens, so the bar and the Scan
  button stay visible everywhere.
- **Favorites:** cards you gave a heart turn slowly on a carousel; drag it to
  spin it yourself, tap the front card to open it. Below: your last 10
  additions. With more than 5 the strip scrolls sideways and loops.
- **Binders tab:** one tile per game (long-press a tile to use your own image,
  Arrange to reorder or hide games).
- **Search tab:** find single cards by name, code, set or rarity (all
  downloaded sets). Give cards your own coloured labels ("Trade", "Deck"...)
  on the card page (touch and hold a label to change its colour) and switch
  labels on as filters.
- **Settings:** Pro upgrade screen (backup & restore, binder looks, batch
  scanning; purchases are not connected yet).
- **Ads, kept low:** one small banner above the tab bar on every screen and
  one full-screen video at most once a day (when you add a card). Pro removes
  both. Uses Google's test ad IDs until you put in your own (see `lib/services/ads.dart`).
- **Card text (Pro for other languages):** an expandable "Card text" block on
  every card. English is free; German, French, Japanese and more come from
  Scryfall (Magic) and TCGdex (Pokémon). Other games only publish English.
- **Scan by artwork (Pro, experimental):** switch the scanner to "Artwork",
  the app compares your photo with the card pictures of the downloaded sets
  (a perceptual hash, all on the phone) and shows the closest cards with their
  pictures for you to confirm. Lorcana pictures are AVIF and may be skipped.
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

- Pro (backup export, binder customization, batch scanning) via RevenueCat;
  the screen exists in `lib/screens/pro_screen.dart`.
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
  services/                   photos, marketplace links
  widgets/                    pocket, card photo
```
