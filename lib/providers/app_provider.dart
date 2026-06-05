import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class AppProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  Locale _locale = const Locale('es');
  String _currency = 'USD';

  bool? _monedaConfigurada;
  bool _esNuevoUsuario = false;

  // ─── NUEVAS PROPIEDADES PARA OPTIMIZACIÓN EN TIEMPO REAL ─────────────────
  List<QueryDocumentSnapshot> _todasLasCategorias = [];
  Map<String, double> _balance = {
    'balanceGeneral': 0.0,
    'balanceDisponible': 0.0,
    'progresoGeneral': 0.0,
    'progresoDisponible': 0.0,
  };
  
  // Controladores de suscripciones para evitar fugas de memoria
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<QuerySnapshot>? _categoriasSubscription;

  // Getters públicos para la UI
  ThemeMode get themeMode => _themeMode;
  Locale get locale => _locale;
  String get currency => _currency;
  bool? get monedaConfigurada => _monedaConfigurada;
  bool get esNuevoUsuario => _esNuevoUsuario;
  
  // Getters optimizados: Filtran en memoria local instantáneamente (0 FPS de impacto)
  List<QueryDocumentSnapshot> get todasLasCategorias => _todasLasCategorias;
  
  List<QueryDocumentSnapshot> get categoriasAhorro => 
      _todasLasCategorias.where((doc) => doc['tipo'] == 'ahorro').toList();
      
  List<QueryDocumentSnapshot> get categoriasGasto => 
      _todasLasCategorias.where((doc) => doc['tipo'] == 'gasto').toList();

  Map<String, double> get balance => _balance;

  final AuthService authService = AuthService();
  final FirestoreService firestoreService = FirestoreService();

  AppProvider() {
    _loadPrefs();
    _escucharCambiosDeUsuario();
  }

  // Sincroniza los streams de Firebase automáticamente según el estado del usuario
  void _escucharCambiosDeUsuario() {
    _authSubscription = authService.userChanges.listen((user) {
      if (user != null) {
        // El usuario inició sesión: Activar escucha en tiempo real única
        _iniciarEscuchaCategorias();
        verificarMonedaConfigurada();
      } else {
        // El usuario cerró sesión: Limpiar datos en memoria de inmediato
        _cancelarSuscripciones();
        _limpiarDatosUsuario();
      }
    });
  }

  void _iniciarEscuchaCategorias() {
    // Cancelamos cualquier suscripción previa por seguridad
    _categoriasSubscription?.cancel();

    // UN SOLO LISTENER para toda la colección. Firebase usará la caché local automáticamente.
    _categoriasSubscription = firestoreService.getTodasLasCategorias().listen((snapshot) {
      _todasLasCategorias = snapshot.docs;
      
      // OPTIMIZACIÓN MASIVA: Calculamos el balance localmente en el hilo principal
      // sin pedirle cálculos recurrentes ni lecturas extra a Firestore.
      _calcularBalanceLocal();
      
      notifyListeners(); // Notifica a toda la UI de una sola vez
    }, onError: (error) {
      debugPrint("Error en stream de categorías: $error");
    });
  }

  void _calcularBalanceLocal() {
    double totalIngresado = 0;
    double totalDestinadoGastos = 0;
    double totalAhorros = 0;

    for (final doc in _todasLasCategorias) {
      final data = doc.data() as Map<String, dynamic>;
      final disponible = (data['disponible'] as num? ?? 0.0).toDouble();
      final tipo = data['tipo'] as String? ?? '';

      if (tipo == 'ingreso') totalIngresado += disponible;
      if (tipo == 'gasto') totalDestinadoGastos += disponible;
      if (tipo == 'ahorro') totalAhorros += disponible;
    }

    final balanceGeneral = totalIngresado + totalDestinadoGastos + totalAhorros;
    final balanceDisponible = totalIngresado + totalDestinadoGastos;

    final progresoGeneral = balanceGeneral > 0
        ? (balanceDisponible / balanceGeneral).clamp(0.0, 1.0)
        : 0.0;

    final progresoDisponible = balanceDisponible > 0
        ? (totalDestinadoGastos / balanceDisponible).clamp(0.0, 1.0)
        : 0.0;

    _balance = {
      'balanceGeneral': balanceGeneral,
      'balanceDisponible': balanceDisponible,
      'progresoGeneral': progresoGeneral,
      'progresoDisponible': progresoDisponible,
    };
  }

  void _limpiarDatosUsuario() {
    _todasLasCategorias = [];
    _balance = {
      'balanceGeneral': 0.0,
      'balanceDisponible': 0.0,
      'progresoGeneral': 0.0,
      'progresoDisponible': 0.0,
    };
    _monedaConfigurada = null;
    _esNuevoUsuario = false;
    notifyListeners();
  }

  void _cancelarSuscripciones() {
    _categoriasSubscription?.cancel();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _categoriasSubscription?.cancel();
    super.dispose();
  }

  // ─── MÉTODOS DE CONFIGURACIÓN ORIGINALES ──────────────────────────────────
  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final theme = prefs.getString('themeMode') ?? 'system';
    final lang = prefs.getString('locale') ?? 'es';
    final cur = prefs.getString('currency') ?? 'USD';

    _themeMode = theme == 'light'
        ? ThemeMode.light
        : theme == 'dark'
            ? ThemeMode.dark
            : ThemeMode.system;
    _locale = Locale(lang);
    _currency = cur;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeMode', mode.name);
    notifyListeners();
  }

  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('locale', locale.languageCode);
    notifyListeners();
  }

  Future<void> setCurrency(String code) async {
    _currency = code;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currency', code);
    notifyListeners();
  }

  Future<void> verificarMonedaConfigurada() async {
    final resultado = await firestoreService.monedaConfigurada();
    _monedaConfigurada = resultado;
    notifyListeners();
  }

  Future<void> confirmarMonedaConfigurada(String currencyCode) async {
    await setCurrency(currencyCode);
    await firestoreService.guardarMonedaUsuario(currencyCode);
    _monedaConfigurada = true;
    notifyListeners();
  }

  void resetMonedaConfigurada() {
    _monedaConfigurada = null;
    _esNuevoUsuario = false;
    notifyListeners();
  }

  void marcarNuevoUsuario() {
    _esNuevoUsuario = true;
    _monedaConfigurada = false;
    notifyListeners();
  }
}
