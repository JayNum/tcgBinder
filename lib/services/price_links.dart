import '../models/catalog.dart';
import '../models/collection.dart';

/// Where users can check prices. The app never shows or stores prices;
/// it only opens the marketplace page for the card.
enum Marketplace {
  cardmarket('Cardmarket', 'Europe'),
  tcgplayer('TCGplayer', 'US market'),
  ebay('eBay', 'Recently sold listings');

  const Marketplace(this.label, this.description);
  final String label;
  final String description;
}

class PriceLinks {
  const PriceLinks._();

  static const _europe = {
    'AT', 'BE', 'BG', 'CH', 'CY', 'CZ', 'DE', 'DK', 'EE', 'ES', 'FI', 'FR',
    'GB', 'GR', 'HR', 'HU', 'IE', 'IS', 'IT', 'LI', 'LT', 'LU', 'LV', 'MT',
    'NL', 'NO', 'PL', 'PT', 'RO', 'SE', 'SI', 'SK',
  };

  static const _ebayHosts = {
    'AT': 'www.ebay.at',
    'DE': 'www.ebay.de',
    'CH': 'www.ebay.ch',
    'GB': 'www.ebay.co.uk',
    'FR': 'www.ebay.fr',
    'IT': 'www.ebay.it',
    'ES': 'www.ebay.es',
    'NL': 'www.ebay.nl',
  };

  static bool isEurope(String? countryCode) =>
      countryCode != null && _europe.contains(countryCode.toUpperCase());

  /// Marketplaces in the order to show them: the user's region first.
  static List<Marketplace> orderedFor(String? countryCode) => isEurope(countryCode)
      ? const [Marketplace.cardmarket, Marketplace.tcgplayer, Marketplace.ebay]
      : const [Marketplace.tcgplayer, Marketplace.cardmarket, Marketplace.ebay];

  /// eBay listings usually mention the code (`OP16-001`) or the printed
  /// number (`4/102`), so include it next to the name.
  static String ebayQuery({
    required Game game,
    required CatalogCard card,
    required CardSet set,
    Edition? edition,
  }) {
    final parts = <String>[];
    switch (game.codeStyle) {
      case CardCodeStyle.dashed:
        parts.addAll([card.code, card.name]);
      case CardCodeStyle.slashed:
        parts.addAll([card.name, card.code, set.name]);
      case CardCodeStyle.number:
        parts.addAll([card.fullName.replaceAll(' - ', ' '), set.name]);
    }
    if (edition != null && edition != Edition.unlimited) {
      parts.add(edition.label);
    }
    return parts.join(' ');
  }

  /// TCGplayer lists cards with their code ("Charizard - 4/102",
  /// "OP17-001"), so the code finds the exact card; adding a set name only
  /// widens the results.
  static String tcgplayerQuery({
    required Game game,
    required CatalogCard card,
    required CardSet set,
  }) {
    final name = card.fullName.replaceAll(' - ', ' ');
    switch (game.codeStyle) {
      case CardCodeStyle.dashed:
        return '${card.code} $name';
      case CardCodeStyle.slashed:
        return '$name ${card.code}';
      case CardCodeStyle.number:
        return '$name ${set.name}';
    }
  }

  static Uri forMarketplace(
    Marketplace marketplace, {
    required Game game,
    required CatalogCard card,
    required CardSet set,
    Edition? edition,
    String? countryCode,
  }) {
    switch (marketplace) {
      case Marketplace.cardmarket:
        final direct = card.cardmarketUrl;
        if (direct != null) return Uri.parse(direct);
        return Uri.https(
          'www.cardmarket.com',
          '/en/${game.cardmarketSlug}/Products/Search',
          {'searchString': card.cardmarketQuery},
        );
      case Marketplace.tcgplayer:
        final direct = card.tcgplayerUrl;
        if (direct != null) return Uri.parse(direct);
        return Uri.https('www.tcgplayer.com', '/search/all/product', {
          'q': tcgplayerQuery(game: game, card: card, set: set),
        });
      case Marketplace.ebay:
        final host = _ebayHosts[countryCode?.toUpperCase()] ?? 'www.ebay.com';
        return Uri.https(host, '/sch/i.html', {
          '_nkw': ebayQuery(game: game, card: card, set: set, edition: edition),
          'LH_Sold': '1',
        });
    }
  }
}
