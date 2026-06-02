import 'dart:async';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PremiumService extends ChangeNotifier {
  PremiumService._();
  static final PremiumService instance = PremiumService._();

  // Reemplazá este ID cuando tengas la llave de Google Play
  static const String _productId = 'hivefi_premium';
  static const String _keyIsPremium = 'is_premium';

  bool _isPremium = false;
  bool _disponible = false;
  bool _cargando = false;
  ProductDetails? _producto;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  bool get isPremium => _isPremium;
  bool get disponible => _disponible;
  bool get cargando => _cargando;
  ProductDetails? get producto => _producto;

  Future<void> inicializar() async {
    // Cargar estado guardado
    final prefs = await SharedPreferences.getInstance();
    _isPremium = prefs.getBool(_keyIsPremium) ?? false;
    notifyListeners();

    // Verificar disponibilidad de la tienda
    _disponible = await InAppPurchase.instance.isAvailable();
    if (!_disponible) return;

    // Escuchar compras
    _subscription = InAppPurchase.instance.purchaseStream.listen(
      _onPurchaseUpdate,
      onError: (_) {},
    );

    // Cargar detalles del producto
    await _cargarProducto();
  }

  Future<void> _cargarProducto() async {
    final response = await InAppPurchase.instance.queryProductDetails(
      {_productId},
    );
    if (response.productDetails.isNotEmpty) {
      _producto = response.productDetails.first;
      notifyListeners();
    }
  }

  Future<bool> comprar() async {
    if (_producto == null) await _cargarProducto();
    if (_producto == null) return false;

    final param = PurchaseParam(productDetails: _producto!);
    return await InAppPurchase.instance.buyNonConsumable(
      purchaseParam: param,
    );
  }

  Future<void> restaurar() async {
    await InAppPurchase.instance.restorePurchases();
  }

  void _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.productID == _productId) {
        if (purchase.status == PurchaseStatus.purchased ||
            purchase.status == PurchaseStatus.restored) {
          await _activarPremium();
        }
        if (purchase.pendingCompletePurchase) {
          await InAppPurchase.instance.completePurchase(purchase);
        }
      }
    }
  }

  Future<void> _activarPremium() async {
    _isPremium = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsPremium, true);
    notifyListeners();
  }

  String get precioFormateado {
    if (_producto != null) return _producto!.price;
    return '\$7.99';
  }

  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}