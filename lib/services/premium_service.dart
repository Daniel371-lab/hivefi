import 'dart:async';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ad_service.dart';
import 'firestore_service.dart';

class PremiumService extends ChangeNotifier {
  PremiumService._();
  static final PremiumService instance = PremiumService._();

  static const String productIdPremium = 'premium_hivefi';
  static const String productIdCafe = 'donar_cafe_hivefi';
  static const String productIdComida = 'donar_comida_hivefi';
  static const String productIdBanquete = 'donar_banquete_hivefi';
  static const String _keyIsPremium = 'is_premium';

  bool _isPremium = false;
  bool _disponible = false;
  bool _cargando = false;

  ProductDetails? _productoPremium;
  ProductDetails? _productoCafe;
  ProductDetails? _productoComida;
  ProductDetails? _productoBanquete;

  StreamSubscription<List<PurchaseDetails>>? _subscription;

  bool get isPremium => _isPremium;
  bool get disponible => _disponible;
  bool get cargando => _cargando;
  ProductDetails? get productoPremium => _productoPremium;
  ProductDetails? get productoCafe => _productoCafe;
  ProductDetails? get productoComida => _productoComida;
  ProductDetails? get productoBanquete => _productoBanquete;

  Future<void> inicializar() async {
    final prefs = await SharedPreferences.getInstance();
    _isPremium = prefs.getBool(_keyIsPremium) ?? false;
    AdService.instance.setPremium(_isPremium);
    notifyListeners();

    _disponible = await InAppPurchase.instance.isAvailable();
    if (!_disponible) return;

    _subscription = InAppPurchase.instance.purchaseStream.listen(
      _onPurchaseUpdate,
      onError: (_) {},
    );

    await _cargarProductos();
  }

  // Se llama cuando el usuario inicia sesión.
  // Restaura el premium desde SharedPreferences y Firestore.
  Future<void> vincularUsuario(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final local = prefs.getBool(_keyIsPremium) ?? false;

    // Si ya sabemos localmente que es premium, no dependemos de la red
    if (local && !_isPremium) {
      _isPremium = true;
      AdService.instance.setPremium(true);
      AdService.instance.adFreeNotifier.value = true;
      notifyListeners();
    }

    // Consultamos Firestore como fuente de verdad
    try {
      final remoto = await FirestoreService().leerPremiumUsuario();
      if (remoto && !_isPremium) {
        _isPremium = true;
        await prefs.setBool(_keyIsPremium, true);
        AdService.instance.setPremium(true);
        AdService.instance.adFreeNotifier.value = true;
        notifyListeners();
      } else if (!remoto && !local) {
        // Restauración silenciosa por si Google Play tiene la compra registrada
        await restaurar();
      }
    } catch (_) {
      // Sin red y sin caché: confiamos en el estado local
    }
  }

  // Se llama cuando el usuario cierra sesión
  Future<void> desvincularUsuario() async {
    _isPremium = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyIsPremium);
    AdService.instance.setPremium(false);
    AdService.instance.adFreeNotifier.value = false;
    notifyListeners();
  }

  Future<void> _cargarProductos() async {
    final response = await InAppPurchase.instance.queryProductDetails({
      productIdPremium,
      productIdCafe,
      productIdComida,
      productIdBanquete,
    });
    for (final p in response.productDetails) {
      if (p.id == productIdPremium) _productoPremium = p;
      if (p.id == productIdCafe) _productoCafe = p;
      if (p.id == productIdComida) _productoComida = p;
      if (p.id == productIdBanquete) _productoBanquete = p;
    }
    notifyListeners();
  }

  Future<bool> comprarPremium() async {
    if (_productoPremium == null) await _cargarProductos();
    if (_productoPremium == null) return false;
    return await InAppPurchase.instance.buyNonConsumable(
      purchaseParam: PurchaseParam(productDetails: _productoPremium!),
    );
  }

  Future<bool> donar(String productId) async {
    if (_productoCafe == null) await _cargarProductos();
    ProductDetails? producto;
    if (productId == productIdCafe) producto = _productoCafe;
    if (productId == productIdComida) producto = _productoComida;
    if (productId == productIdBanquete) producto = _productoBanquete;
    if (producto == null) return false;
    return await InAppPurchase.instance.buyConsumable(
      purchaseParam: PurchaseParam(productDetails: producto),
    );
  }

  Future<void> restaurar() async {
    await InAppPurchase.instance.restorePurchases();
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        if (purchase.productID == productIdPremium) {
          await _activarPremium(
            token: purchase.verificationData.serverVerificationData,
          );
        }
      }
      if (purchase.pendingCompletePurchase) {
        await InAppPurchase.instance.completePurchase(purchase);
      }
    }
  }

  Future<void> _activarPremium({String? token}) async {
    _isPremium = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsPremium, true);

    AdService.instance.setPremium(true);
    AdService.instance.adFreeNotifier.value = true;

    try {
      await FirestoreService().guardarPremiumUsuario(
        premium: true,
        token: token,
      );
    } catch (_) {
      // Si falla la escritura remota, al menos queda persistido localmente
    }

    notifyListeners();
  }

  Future<void> limpiarEstado() async {
    _isPremium = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyIsPremium);

    AdService.instance.setPremium(false);
    AdService.instance.adFreeNotifier.value = false;

    notifyListeners();
  }

  String get precioFormateado => _productoPremium?.price ?? '\$8.00';
  String get precioCafe => _productoCafe?.price ?? '\$2.00';
  String get precioComida => _productoComida?.price ?? '\$7.00';
  String get precioBanquete => _productoBanquete?.price ?? '\$15.00';

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}