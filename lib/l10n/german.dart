/// German texts for the app. Keys are the exact English strings used in the
/// app; anything missing simply stays English.
String translateToGerman(String english) {
  final exact = _de[english];
  if (exact != null) return exact;
  for (final rule in _rules) {
    final m = rule.$1.firstMatch(english);
    if (m != null) return rule.$2(m);
  }
  return english;
}

String _plural(int n, String one, String many) => n == 1 ? one : many;

String _t(String s) => translateToGerman(s);

final List<(RegExp, String Function(Match))> _rules = [
  (RegExp(r'^(\d+) cards? · (\d+) binders? started$'),
      (m) => '${m[1]} ${_plural(int.parse(m[1]!), 'Karte', 'Karten')} · ${m[2]} Binder angelegt'),
  (RegExp(r'^(\d+) cards? · (\d+) binders?$'),
      (m) => '${m[1]} ${_plural(int.parse(m[1]!), 'Karte', 'Karten')} · ${m[2]} Binder'),
  (RegExp(r'^(\d+) cards?$'),
      (m) => '${m[1]} ${_plural(int.parse(m[1]!), 'Karte', 'Karten')}'),
  (RegExp(r'^(\d+) sets? · (.+)$'),
      (m) => '${m[1]} ${_plural(int.parse(m[1]!), 'Set', 'Sets')} · ${_t(m[2]!)}'),
  (RegExp(r'^Page (\d+) of (\d+)$'), (m) => 'Seite ${m[1]} von ${m[2]}'),
  (RegExp(r'^(\d+) versions of this card$'),
      (m) => '${m[1]} Versionen dieser Karte'),
  (RegExp(r'^You have (\d+) · (\d+) missing$'),
      (m) => 'Du hast ${m[1]} · ${m[2]} fehlen'),
  (RegExp(r'^In (.+) · (.+)$'), (m) => 'In ${m[1]} · ${m[2]}'),
  (RegExp(r'^Owned ×(\d+)$'), (m) => 'Vorhanden ×${m[1]}'),
  (RegExp(r'^pulled from (.+)$'), (m) => 'aus ${m[1]} übernommen'),
  (RegExp(r'^Delete “(.+)”\?$'), (m) => '„${m[1]}“ löschen?'),
  (RegExp(r'^Colour for “(.+)”$'), (m) => 'Farbe für „${m[1]}“'),
  (RegExp(r'^(.+) and its photo will be removed from your binder\.$'),
      (m) => '${m[1]} und das Foto werden aus deinem Binder entfernt.'),
  (RegExp(r'^No set matches "(.+)"\.$'),
      (m) => 'Kein Set passt zu „${m[1]}“.'),
  (RegExp(r'^Added (.+) to (.+)$'), (m) => '${m[1]} zu ${m[2]} hinzugefügt'),
  (RegExp(r'^Scan failed: (.+)$'), (m) => 'Scan fehlgeschlagen: ${m[1]}'),
  (RegExp(r'^Could not load sets: (.+)$'),
      (m) => 'Sets konnten nicht geladen werden: ${m[1]}'),
  (RegExp(r'^No (.+) text found for this card\.$'),
      (m) => 'Kein Text auf ${_t(m[1]!)} für diese Karte gefunden.'),
  (RegExp(r'^All (.+) sets are already on your phone\.$'),
      (m) => 'Alle Sets von ${m[1]} sind schon auf deinem Handy.'),
  (RegExp(r'^Downloading (.+)$'), (m) => '${m[1]} wird geladen'),
  (RegExp(r'^Download (.+)$'), (m) => '${m[1]} herunterladen'),
  (RegExp(r'^(\d+) of (\d+) sets$'), (m) => '${m[1]} von ${m[2]} Sets'),
  (RegExp(r'^Set (\d+) of (\d+): (\d+) / (\d+) cards$'),
      (m) => 'Set ${m[1]} von ${m[2]}: ${m[3]} / ${m[4]} Karten'),
  (RegExp(r'^(.*) · you have (\d+)$'), (m) => '${m[1]} · du hast ${m[2]}'),
  (RegExp(r'^(\d+) card lists will be downloaded once, so you can search every (.+) card\. Use Wi-Fi; it can take a few minutes\.$'),
      (m) => '${m[1]} Kartenlisten werden einmalig geladen, damit du jede ${m[2]}-Karte suchen kannst. Nutze WLAN; das kann ein paar Minuten dauern.'),
  (RegExp(r'^The app downloads the pictures of (\d+) cards once \((\d+) sets?\) and remembers what their artwork looks like\. This can take a few minutes on Wi-Fi\.$'),
      (m) => 'Die App lädt einmalig die Bilder von ${m[1]} Karten (${m[2]} ${_plural(int.parse(m[2]!), 'Set', 'Sets')}) und merkt sich, wie ihr Motiv aussieht. Im WLAN kann das einige Minuten dauern.'),
  (RegExp(r'^Searching the (\d+) sets? downloaded on this phone\. Open a binder to add its cards to the search\.$'),
      (m) => 'Durchsucht werden die ${m[1]} auf diesem Handy geladenen ${_plural(int.parse(m[1]!), 'Set', 'Sets')}. Öffne ein Binder, um seine Karten zur Suche hinzuzufügen.'),
  (RegExp(r'^Search the (\d+) downloaded sets by name or code\. Give your cards labels on their card page and they appear here as colourful filters\.$'),
      (m) => 'Durchsuche die ${m[1]} geladenen Sets nach Name oder Code. Gib deinen Karten auf der Kartenseite Labels, dann erscheinen sie hier als bunte Filter.'),
  (RegExp(r'^Search the (\d+) downloaded sets by name or code, or tap a label to see only those cards\.$'),
      (m) => 'Durchsuche die ${m[1]} geladenen Sets nach Name oder Code, oder tippe auf ein Label, um nur diese Karten zu sehen.'),
  (RegExp(r'^Read (.+), but no card with that number was found(.*)\.$'),
      (m) => 'Gelesen: ${m[1]}, aber keine Karte mit dieser Nummer gefunden${m[2]}.'),
  (RegExp(r'^Read (.+)$'), (m) => 'Gelesen: ${m[1]}'),
  (RegExp(r'^Check your internet connection\. The card list comes from (.+)\. Once downloaded, the binder works offline\.\n\n(.*)$', dotAll: true),
      (m) => 'Prüfe deine Internetverbindung. Die Kartenliste kommt von ${m[1]}. Nach dem Download funktioniert das Binder offline.\n\n${m[2]}'),
  (RegExp(r'^Check your internet connection\. The set list comes from (.+)\.$'),
      (m) => 'Prüfe deine Internetverbindung. Die Setliste kommt von ${m[1]}.'),
  (RegExp(r'^(.+) has no cards for this set yet\. Try again later\.$'),
      (m) => '${m[1]} hat für dieses Set noch keine Karten. Versuche es später noch einmal.'),
  (RegExp(r'^ of (\d+) collected$'), (m) => ' von ${m[1]} gesammelt'),
  (RegExp(r'^ · (\d+) alt arts?$'),
      (m) => ' · ${m[1]} Alternativ-${_plural(int.parse(m[1]!), 'Artwork', 'Artworks')}'),
  (RegExp(r'^(.+) image$'), (m) => 'Bild für ${m[1]}'),
  (RegExp(r'^Drag to move (.+)$'), (m) => '${m[1]} verschieben'),
];

const Map<String, String> _de = {
  'Decks': 'Decks',
  'No decks yet': 'Noch keine Decks',
  'New deck': 'Neues Deck',
  'Which game is the deck for?': 'Für welches Spiel ist das Deck?',
  'One deck per game': 'Ein Deck pro Spiel',
  'See Pro': 'Pro ansehen',
  'Name your deck': 'Deck benennen',
  'e.g. Red aggro': 'z. B. Rotes Aggro',
  'Create': 'Erstellen',
  'Rename': 'Umbenennen',
  'Delete deck': 'Deck löschen',
  'Rename deck': 'Deck umbenennen',
  'Delete this deck?': 'Dieses Deck löschen?',
  'The deck list is removed. Your collection is not touched.': 'Die Deckliste wird entfernt. Deine Sammlung bleibt unverändert.',
  'Touch and hold a deck to rename or delete it.': 'Deck gedrückt halten zum Umbenennen oder Löschen.',
  'Build decks and see what you still need': 'Baue Decks und sieh, was dir noch fehlt',
  'Add cards': 'Karten hinzufügen',
  'You have': 'Vorhanden',
  'This deck was deleted.': 'Dieses Deck wurde gelöscht.',
  'Opens the marketplace in your browser.': 'Öffnet den Marktplatz im Browser.',
  'Deck builder': 'Deck-Builder',
  'Build as many decks as you like. Free has one deck per game.': 'Baue so viele Decks, wie du möchtest. Kostenlos gibt es ein Deck pro Spiel.',
  'App skins': 'App-Designs',
  'Vault and Playmat: two more looks for the whole app.': 'Vault und Playmat: zwei weitere Looks für die ganze App.',
  'Look': 'Look',
  'App skin': 'App-Design',
  'Free: 1 deck per game. Pro: as many as you like.': 'Kostenlos: 1 Deck pro Spiel. Pro: so viele du willst.',
  // Tabs and titles
  'Favorites': 'Favoriten',
  'Favorite': 'Favorit',
  'Binders': 'Binder',
  'Search': 'Suche',
  'Settings': 'Einstellungen',
  'Scan cards': 'Karten scannen',
  'Scan card': 'Karte scannen',
  'Recent additions': 'Zuletzt hinzugefügt',
  'Cards': 'Karten',
  'No favorites yet': 'Noch keine Favoriten',
  'Tap the heart on a card you own and it shows up here, turning slowly like a display case.':
      'Tippe bei einer Karte, die du besitzt, auf das Herz, und sie erscheint hier wie in einer Vitrine.',
  'Saved card': 'Gespeicherte Karte',
  'Open this binder once to load its card list.':
      'Öffne dieses Binder einmal, um die Kartenliste zu laden.',

  // Binders / games
  'Arrange': 'Anordnen',
  'Arrange games': 'Spiele anordnen',
  'Not started yet': 'Noch nicht begonnen',
  'Tip: touch and hold a game to give it your own image.':
      'Tipp: Halte ein Spiel gedrückt, um ein eigenes Bild festzulegen.',
  'All games are hidden. Tap Arrange to show them again.':
      'Alle Spiele sind ausgeblendet. Tippe auf „Anordnen“, um sie wieder einzublenden.',
  'Drag a game by its handle to move it. Switch a game off to hide it from the Binders tab and the scanner — your cards stay saved.':
      'Ziehe ein Spiel am Griff, um es zu verschieben. Schalte ein Spiel aus, um es im Binder-Tab und im Scanner auszublenden – deine Karten bleiben gespeichert.',
  'Change image': 'Bild ändern',
  'Long-press to change the image': 'Gedrückt halten, um das Bild zu ändern',
  'Choose from gallery': 'Aus der Galerie wählen',
  'Take a photo': 'Foto aufnehmen',
  'Use the default colour': 'Standardfarbe verwenden',
  'Search sets and cards': 'Sets und Karten suchen',
  'Sort sets': 'Sets sortieren',
  'Newest first': 'Neueste zuerst',
  'Oldest first': 'Älteste zuerst',
  'Name A–Z': 'Name A–Z',
  'All': 'Alle',
  'Boosters': 'Booster',
  'Extra boosters': 'Extra-Booster',
  'Starter decks': 'Starterdecks',
  'Promos': 'Promos',
  'Could not load the sets': 'Die Sets konnten nicht geladen werden',
  'Could not load this set': 'Dieses Set konnte nicht geladen werden',
  'Try again': 'Erneut versuchen',
  'Try again later.': 'Versuche es später noch einmal.',
  'No sets of this kind.': 'Keine Sets dieser Art.',
  'Empty binder': 'Leeres Binder',
  'Check again': 'Erneut prüfen',
  'No cards listed yet': 'Noch keine Karten gelistet',
  'Download card list again': 'Kartenliste erneut laden',
  'Previous page': 'Vorherige Seite',
  'Next page': 'Nächste Seite',
  'More': 'Mehr',
  'Owned · add photo': 'Vorhanden · Foto hinzufügen',

  // Search
  'Find any card': 'Finde jede Karte',
  'Name, code or set': 'Name, Code oder Set',
  'Owned': 'Besitz',
  'No card matches.': 'Keine Karte gefunden.',
  'No card lists are downloaded yet. Open a binder once and its cards can be searched here.':
      'Es sind noch keine Kartenlisten geladen. Öffne ein Binder einmal, dann lassen sich seine Karten hier suchen.',
  'Download all sets to search everything':
      'Alle Sets laden, um alles zu durchsuchen',
  'Download all sets of this game': 'Alle Sets dieses Spiels laden',
  'Download all card lists of…': 'Alle Kartenlisten laden von …',
  'Download': 'Herunterladen',
  'Stop': 'Stopp',
  'Starting…': 'Starte …',

  // Card detail
  'Add to favorites': 'Zu Favoriten hinzufügen',
  'Remove from favorites': 'Aus Favoriten entfernen',
  'Add photo': 'Foto hinzufügen',
  'Change photo': 'Foto ändern',
  'Add with photo': 'Mit Foto hinzufügen',
  'Add without photo': 'Ohne Foto hinzufügen',
  'Remove from collection': 'Aus der Sammlung entfernen',
  'Remove this card?': 'Diese Karte entfernen?',
  'Remove': 'Entfernen',
  'Delete': 'Löschen',
  'Labels': 'Labels',
  'New label': 'Neues Label',
  'Change colour': 'Farbe ändern',
  'Delete label from all cards': 'Label bei allen Karten löschen',
  'The label is taken off every card. The cards stay.':
      'Das Label wird von allen Karten entfernt. Die Karten bleiben.',
  'Labels are only for you, like "Trade", "Deck" or "Graded". Touch and hold a label to change its colour. Use them in Search to show only those cards.':
      'Labels sind nur für dich, z. B. „Tausch“, „Deck“ oder „Bewertet“. Halte ein Label gedrückt, um die Farbe zu ändern. In der Suche kannst du damit nur diese Karten anzeigen.',
  'Your copy': 'Deine Karte',
  'Quantity': 'Anzahl',
  'One less': 'Eine weniger',
  'One more': 'Eine mehr',
  'Condition': 'Zustand',
  'Language': 'Sprache',
  'Edition': 'Edition',
  'Your estimate': 'Deine Einschätzung',
  'Check prices': 'Preise prüfen',
  'Your region': 'Deine Region',
  'Opens the card on the marketplace in your browser. Prices are checked there, not stored in the app.':
      'Öffnet die Karte im Browser auf dem Marktplatz. Preise werden dort geprüft und nicht in der App gespeichert.',
  'Could not open the browser.': 'Der Browser konnte nicht geöffnet werden.',
  'Europe': 'Europa',
  'US market': 'US-Markt',
  'Recently sold listings': 'Zuletzt verkaufte Angebote',
  'Each version sits in the binder of the set it comes out of. Tap a version to open it or add it.':
      'Jede Version liegt im Binder des Sets, aus dem sie stammt. Tippe auf eine Version, um sie zu öffnen oder hinzuzufügen.',
  'You have all of them': 'Du hast alle',
  'This card': 'Diese Karte',
  'Missing': 'Fehlt',
  'Base': 'Basis',
  'Mint': 'Neuwertig',
  'Near Mint': 'Fast neuwertig',
  'Excellent': 'Sehr gut',
  'Good': 'Gut',
  'Light Played': 'Leicht bespielt',
  'Played': 'Bespielt',
  'Poor': 'Schlecht',
  '1st Edition': '1. Edition',
  'Shadowless': 'Shadowless',
  'Unlimited': 'Unlimitiert',

  // Card text
  'Card text': 'Kartentext',
  'Loading…': 'Lädt …',
  'No card text available for this card.':
      'Für diese Karte ist kein Kartentext verfügbar.',
  "This game's database only has English text.":
      'Die Datenbank dieses Spiels hat nur englische Texte.',

  // Labels dialogs
  'Add': 'Hinzufügen',
  'Cancel': 'Abbrechen',
  'Save': 'Sichern',
  'Colour': 'Farbe',
  'e.g. Trade': 'z. B. Tausch',

  // Languages
  'English': 'Englisch',
  'German': 'Deutsch',
  'French': 'Französisch',
  'Italian': 'Italienisch',
  'Spanish': 'Spanisch',
  'Portuguese': 'Portugiesisch',
  'Japanese': 'Japanisch',
  'Korean': 'Koreanisch',
  'Chinese': 'Chinesisch',

  // Scan
  'Card number': 'Kartennummer',
  'Artwork · Pro': 'Motiv · Pro',
  'Fit the card in the frame. Keep the number at the bottom sharp and avoid glare.':
      'Lege die Karte in den Rahmen. Halte die Nummer unten scharf und vermeide Spiegelungen.',
  'Fit the whole card in the frame, picture sharp and without glare. You confirm the match.':
      'Lege die ganze Karte in den Rahmen, Bild scharf und ohne Spiegelung. Du bestätigst den Treffer.',
  'Retake': 'Neu aufnehmen',
  'Add to binder': 'Zum Binder hinzufügen',
  'Find it myself': 'Selbst suchen',
  'Found it': 'Gefunden',
  'Which version is it?': 'Welche Version ist es?',
  'Card not found': 'Karte nicht gefunden',
  'Is this your card?': 'Ist das deine Karte?',
  'Matched by artwork. Compare the pictures and pick the right one.':
      'Per Motiv gefunden. Vergleiche die Bilder und wähle die richtige.',
  'No artwork looked close enough. Try again with less glare, or find it yourself.':
      'Kein Motiv war nah genug. Versuche es mit weniger Spiegelung noch einmal oder suche selbst.',
  'No card number could be read. Try again closer, with less glare.':
      'Es konnte keine Kartennummer gelesen werden. Versuche es näher und mit weniger Spiegelung.',
  'Which language is this card?': 'In welcher Sprache ist diese Karte?',
  'Prepare artwork search': 'Motivsuche vorbereiten',
  'Preparing artwork search': 'Motivsuche wird vorbereitet',
  'Prepare': 'Vorbereiten',
  'Artwork search was not prepared.': 'Die Motivsuche wurde nicht vorbereitet.',
  'The photo could not be read.': 'Das Foto konnte nicht gelesen werden.',
  'No card lists of this game are on your phone yet. Open a binder of this game once, then try again.':
      'Von diesem Spiel sind noch keine Kartenlisten auf deinem Handy. Öffne einmal ein Binder dieses Spiels und versuche es dann erneut.',
  'Camera access is off. Allow it for Le Binder in your phone settings to scan cards.':
      'Der Kamerazugriff ist aus. Erlaube ihn für Le Binder in den Handy-Einstellungen, um Karten zu scannen.',
  'No camera found on this device.': 'Auf diesem Gerät wurde keine Kamera gefunden.',

  // Settings
  'Upgrade to Pro': 'Auf Pro upgraden',
  'Card text in every language, artwork scan, backup':
      'Kartentext in jeder Sprache, Motiverkennung, Backup',
  'Your collection and photos are stored only on this phone. There is no account.':
      'Deine Sammlung und Fotos werden nur auf diesem Handy gespeichert. Es gibt kein Konto.',
  'Ads & privacy': 'Werbung & Datenschutz',
  'Privacy & ad choices': 'Datenschutz & Werbewahl',
  'Change your consent for personalised ads':
      'Deine Einwilligung für personalisierte Werbung ändern',
  'There are no ad choices to make in your region.':
      'In deiner Region gibt es keine Werbeoptionen zur Auswahl.',
  'About': 'Impressum',
  'Card data': 'Kartendaten',
  'Delete downloaded card lists': 'Geladene Kartenlisten löschen',
  'Frees space. Lists download again when you open a binder. Your collection stays.':
      'Gibt Speicher frei. Die Listen werden beim Öffnen eines Binders neu geladen. Deine Sammlung bleibt.',
  'Downloaded card lists deleted.': 'Geladene Kartenlisten gelöscht.',
  'Le Binder 0.3.0 · Card names and data © their publishers':
      'Le Binder 0.3.0 · Kartennamen und Daten © ihre Herausgeber',
  'App language': 'App-Sprache',
  'Same as phone': 'Wie das Handy',
  'Deutsch': 'Deutsch',

  // Pro
  'Le Binder Pro': 'Le Binder Pro',
  'Get more from your binders': 'Hol mehr aus deinen Bindern heraus',
  'Your collection stays free and on your phone. Pro adds tools for people with big collections.':
      'Deine Sammlung bleibt kostenlos und auf deinem Handy. Pro bringt Werkzeuge für große Sammlungen.',
  'Included': 'Enthalten',
  'No ads': 'Keine Werbung',
  'No banners and no daily video. Just your cards.':
      'Keine Banner und kein tägliches Video. Nur deine Karten.',
  'Card text in every language': 'Kartentext in jeder Sprache',
  'Read the printed card text in German, French, Japanese and more (Pokémon; Magic is free).':
      'Lies den gedruckten Kartentext auf Deutsch, Französisch, Japanisch und mehr (Pokémon; bei Magic kostenlos).',
  'Recognise by artwork': 'Per Motiv erkennen',
  'Scan a card and the app finds it by its picture, then you confirm. Works when the code is hard to read.':
      'Scanne eine Karte, die App findet sie über ihr Bild, du bestätigst. Funktioniert auch, wenn der Code schwer lesbar ist.',
  'Backup & restore': 'Sichern & Wiederherstellen',
  'Save your whole collection, photos included, as one file. Keep it anywhere and restore it on any phone.':
      'Sichere deine ganze Sammlung samt Fotos als eine Datei. Bewahre sie überall auf und stelle sie auf jedem Handy wieder her.',
  'Binder looks': 'Binder-Designs',
  'Choose colours and covers, or use your own images for every binder.':
      'Wähle Farben und Cover oder nutze eigene Bilder für jedes Binder.',
  'Batch scanning': 'Stapel-Scan',
  'Scan a whole stack in a row. The camera stays open and files each card.':
      'Scanne einen ganzen Stapel am Stück. Die Kamera bleibt offen und legt jede Karte ab.',
  'Moving to a new phone stays free for everyone.':
      'Der Umzug auf ein neues Handy bleibt für alle kostenlos.',
  'Monthly': 'Monatlich',
  'Yearly': 'Jährlich',
  'per month': 'pro Monat',
  'per year · save 16%': 'pro Jahr · 16 % sparen',
  'Continue': 'Weiter',
  'Restore purchases': 'Käufe wiederherstellen',
  'Not switched on yet': 'Noch nicht aktiviert',
  'Subscriptions are not connected in this test version, so nothing was charged.':
      'Abos sind in dieser Testversion nicht verbunden, es wurde nichts abgebucht.',
  'Switch Pro on (test build)': 'Pro einschalten (Testversion)',
  'Switch Pro off (test build)': 'Pro ausschalten (Testversion)',

  // Impressum
  'Provider of this app': 'Anbieter dieser App',
  'Name': 'Name',
  'Address': 'Adresse',
  'E-mail': 'E-Mail',
  'Le Binder is a private project. Card data comes from the public databases listed in Settings. Card names and images belong to their respective owners; this app is not affiliated with them.':
      'Le Binder ist ein privates Projekt. Die Kartendaten stammen aus den in den Einstellungen genannten öffentlichen Datenbanken. Kartennamen und Bilder gehören ihren jeweiligen Inhabern; diese App steht in keiner Verbindung zu ihnen.',
  'Austria': 'Österreich',
};
