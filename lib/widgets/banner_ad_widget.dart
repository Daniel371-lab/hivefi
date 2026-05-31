import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/ad_service.dart';

class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _cargado = false;
  bool _adFree = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final adFree = await AdService.instance.isAdFree();
    if (adFree) {
      if (mounted) setState(() => _adFree = true);
      return;
    }

    final banner = AdService.instance.createBannerAd();
    await banner.load();
    if (mounted) {
      setState(() {
        _bannerAd = banner;
        _cargado = true;
      });
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_adFree || !_cargado || _bannerAd == null) return const SizedBox.shrink();

    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Container(
      color: Theme.of(context).colorScheme.surface,
      width: double.infinity,
      height: _bannerAd!.size.height.toDouble() + bottomInset,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}