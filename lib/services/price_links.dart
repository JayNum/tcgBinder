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

  /// Search text such as `Charizard Base Set 1st Edition`.
  static String searchQuery({
    required CatalogCard card,
    required CardSet set,
    Edition? edition,
  }) {
    final parts = [card.name, set.name];
    if (edition != null && edition != Edition.unlimited) {
      parts.add(edition.label);
    }
    return parts.join(' ');
  }

  static Uri forMarketplace(
    Marketplace marketplace, {
    required Game game,
    required CatalogCard card,
    required CardSet set,
    Edition? edition,
    String? countryCode,
  }) {
    final query = searchQuery(card: card, set: set, edition: edition);
    switch (marketplace) {
      case Marketplace.cardmarket:
        final direct = card.cardmarketUrl;
        if (direct != null) return Uri.parse(direct);
        return Uri.https(
          'www.cardmarket.com',
          '/en/${game.cardmarketSlug}/Products/Search',
          {'searchString': query},
        );
      case Marketplace.tcgplayer:
        final direct = card.tcgplayerUrl;
        if (direct != null) return Uri.parse(direct);
        return Uri.https('www.tcgplayer.com', '/search/all/product', {'q': query});
      case Marketplace.ebay:
        final host = _ebayHosts[countryCode?.toUpperCase()] ?? 'www.ebay.com';
        return Uri.https(host, '/sch/i.html', {
          '_nkw': '$query ${game.name}',
          'LH_Sold': '1',
          'LH_Complete': '1',
        });
    }
  }
}
