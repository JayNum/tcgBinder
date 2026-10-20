import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../data/settings_store.dart';

/// AdMob: a banner on every screen (above the tab bar) and one full-screen
/// video ad per day, shown when the first card of the day is added. Pro
/// removes both.
///
/// The unit IDs below are Google's official TEST IDs, which always show
/// test ads. Replace them with your own from the AdMob console before
/// publishing (and the app IDs in AndroidManifest.xml / Info.plist).
class AdsService extends ChangeNotifier {
  AdsService({required this.enabled});

  /// False in tests and on platforms without ads.
  final bool enabled;

  static String get _bannerUnit => Platform.isIOS
      ? 'ca-app-pub-3940256099942544/2934735716'
      : 'ca-app-pub-3940256099942544/6300978111';

  // Google's test unit for full-screen *video* ads.
  static String get _interstitialUnit => Platform.isIOS
      ? 'ca-app-pub-3940256099942544/5135589807'
      : 'ca-app-pub-3940256099942544/8691691433';

  bool _ready = false;
  InterstitialAd? _interstitial;

  /// Asks for ad consent where the law requires it (EU), then starts AdMob.
  Future<void> init() async {
    if (!enabled) return;
    final consentDone = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () {
        ConsentForm.loadAndShowConsentFormIfRequired((FormError? error) {
          if (error != null) debugPrint('Consent form: ${error.message}');
          if (!consentDone.isCompleted) consentDone.complete();
        });
      },
      (FormError error) {
        debugPrint('Consent info: ${error.message}');
        if (!consentDone.isCompleted) consentDone.complete();
      },
    );
    await consentDone.future;
    if (!await ConsentInformation.instance.canRequestAds()) return;
    await MobileAds.instance.initialize();
    _ready = true;
    notifyListeners();
    _loadInterstitial();
  }

  bool get ready => _ready;

  /// Whether the user can change their ad choices (shown in Settings).
  Future<bool> hasPrivacyOptions() async {
    if (!enabled) return false;
    final status =
        await ConsentInformation.instance.getPrivacyOptionsRequirementStatus();
    return status == PrivacyOptionsRequirementStatus.required;
  }

  void showPrivacyOptions() {
    ConsentForm.showPrivacyOptionsForm((FormError? error) {
      if (error != null) debugPrint('Privacy options: ${error.message}');
    });
  }

  void _loadInterstitial() {
    if (!_ready) return;
    InterstitialAd.load(
      adUnitId: _interstitialUnit,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitial = ad,
        onAdFailedToLoad: (error) {
          debugPrint('Interstitial failed: ${error.message}');
          _interstitial = null;
        },
      ),
    );
  }

  /// Shows the full-screen ad if one is loaded. True if it was shown.
  bool showInterstitial() {
    final ad = _interstitial;
    if (!_ready || ad == null) {
      _loadInterstitial();
      return false;
    }
    _interstitial = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _loadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _loadInterstitial();
      },
    );
    ad.show();
    return true;
  }

  BannerAd? createBanner(VoidCallback onLoaded) {
    if (!_ready) return null;
    return BannerAd(
      adUnitId: _bannerUnit,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => onLoaded(),
        onAdFailedToLoad: (ad, error) {
          debugPrint('Banner failed: ${error.message}');
          ad.dispose();
        },
      ),
    )..load();
  }
}

class AdsScope extends InheritedWidget {
  const AdsScope({super.key, required this.ads, required super.child});

  final AdsService ads;

  static AdsService of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AdsScope>();
    assert(scope != null, 'No AdsScope above this widget');
    return scope!.ads;
  }

  @override
  bool updateShouldNotify(AdsScope oldWidget) => ads != oldWidget.ads;
}

/// A 320×50 banner. Takes no space until an ad has loaded.
class BannerAdView extends StatefulWidget {
  const BannerAdView({super.key});

  @override
  State<BannerAdView> createState() => _BannerAdViewState();
}

class _BannerAdViewState extends State<BannerAdView> {
  AdsService? _ads;
  BannerAd? _banner;
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ads = AdsScope.of(context);
    if (!identical(ads, _ads)) {
      _ads?.removeListener(_tryCreate);
      _ads = ads;
      ads.addListener(_tryCreate);
    }
    _tryCreate();
  }

  /// AdMob may still be starting; create the banner once it's ready.
  void _tryCreate() {
    if (_banner != null || !mounted) return;
    _banner = _ads?.createBanner(() {
      if (mounted) setState(() => _loaded = true);
    });
  }

  @override
  void dispose() {
    _ads?.removeListener(_tryCreate);
    _banner?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final banner = _banner;
    if (SettingsScope.of(context).isPro) return const SizedBox.shrink();
    if (banner == null || !_loaded) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: SizedBox(
        width: banner.size.width.toDouble(),
        height: banner.size.height.toDouble(),
        child: AdWidget(ad: banner),
      ),
    );
  }
}
