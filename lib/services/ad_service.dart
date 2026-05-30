import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdService {
  AdService._();
  static final AdService instance = AdService._();

  // IDs de producción
  static const _bannerAdUnitId = 'ca-app-pub-2628699742979891/6869686673';
  static const _interstitialAdUnitId = 'ca-app-pub-2628699742979891/6039998340';
  static const _rewardedAdUnitId = 'ca-app-pub-2628699742979891/9800754738';

  static const _keyAdFreeUntil = 'ad_free_until';
  static const _keyGastoCount = 'gasto_count';

  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;

  // ─── Premium ───────────────────────────────────────────────────────────────

  bool _isPremium = false;

  void setPremium(bool value) {
    _isPremium = value;
  }

  bool get isPremium => _isPremium;

  // ─── Sin anuncios 6hs ──────────────────────────────────────────────────────

  Future<bool> isAdFree() async {
    if (_isPremium) return true;
    final prefs = await SharedPreferences.getInstance();
    final until = prefs.getInt(_keyAdFreeUntil) ?? 0;
    return DateTime.now().millisecondsSinceEpoch < until;
  }

  Future<void> _setAdFree6Hours() async {
    final prefs = await SharedPreferences.getInstance();
    final until = DateTime.now().add(const Duration(hours: 6)).millisecondsSinceEpoch;
    await prefs.setInt(_keyAdFreeUntil, until);
  }

  // ─── Banner ────────────────────────────────────────────────────────────────

  BannerAd createBannerAd() {
    return BannerAd(
      adUnitId: _bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: const BannerAdListener(),
    );
  }

  // ─── Intersticial ──────────────────────────────────────────────────────────

  Future<void> cargarIntersticial() async {
    if (_interstitialAd != null) return;
    await InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitialAd = ad,
        onAdFailedToLoad: (_) => _interstitialAd = null,
      ),
    );
  }

  Future<void> mostrarInterstitialSiCorresponde() async {
    if (await isAdFree()) return;

    final prefs = await SharedPreferences.getInstance();
    int count = prefs.getInt(_keyGastoCount) ?? 0;
    count++;
    await prefs.setInt(_keyGastoCount, count);

    // Mostrar en 1, 3, 5, 7... (impares)
    if (count % 2 == 1) {
      if (_interstitialAd != null) {
        _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
          onAdDismissedFullScreenContent: (ad) {
            ad.dispose();
            _interstitialAd = null;
            cargarIntersticial();
          },
          onAdFailedToShowFullScreenContent: (ad, _) {
            ad.dispose();
            _interstitialAd = null;
          },
        );
        await _interstitialAd!.show();
      } else {
        await cargarIntersticial();
      }
    }
  }

  // ─── Rewarded ──────────────────────────────────────────────────────────────

  Future<void> cargarRewarded() async {
    if (_rewardedAd != null) return;
    await RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) => _rewardedAd = ad,
        onAdFailedToLoad: (_) => _rewardedAd = null,
      ),
    );
  }

  Future<bool> mostrarRewarded() async {
    if (_rewardedAd == null) {
      await cargarRewarded();
      if (_rewardedAd == null) return false;
    }

    bool recompensado = false;

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        cargarRewarded();
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        _rewardedAd = null;
      },
    );

    await _rewardedAd!.show(
      onUserEarnedReward: (_, __) async {
        recompensado = true;
        await _setAdFree6Hours();
      },
    );

    return recompensado;
  }

  // ─── Precarga inicial ──────────────────────────────────────────────────────

  Future<void> precargar() async {
    await cargarIntersticial();
    await cargarRewarded();
  }
}