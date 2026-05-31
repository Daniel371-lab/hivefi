import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'theme/app_theme.dart';
import 'providers/app_provider.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/categorias_screen.dart';
import 'screens/ingreso_screen.dart';
import 'screens/gasto_screen.dart';
import 'screens/destinar_screen.dart';
import 'screens/reparto_screen.dart';
import 'screens/historial_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/currency_setup_screen.dart';
import 'services/ad_service.dart';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    try {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: 'AIzaSyBGN6x4bwMqGDSaWyutU5QCY3cuZyWYgp4',
          appId: '1:836237128631:android:13c18bbf1a90f69e8c6e32',
          messagingSenderId: '836237128631',
          projectId: 'hivefi-39b81',
          storageBucket: 'hivefi-39b81.firebasestorage.app',
        ),
      );

      await MobileAds.instance.initialize();
      await AdService.instance.precargar();

      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarDividerColor: Colors.transparent,
      ));

      runApp(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AppProvider()),
          ],
          child: const HivefiApp(),
        ),
      );
    } catch (e, stackTrace) {
      runApp(PantallaDeError(error: e.toString(), stack: stackTrace.toString()));
    }
  }, (error, stackTrace) {
    runApp(PantallaDeError(error: error.toString(), stack: stackTrace.toString()));
  });
}

class HivefiApp extends StatelessWidget {
  const HivefiApp({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return MaterialApp(
      title: 'Hivefi',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: provider.themeMode,
      locale: provider.locale,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es'),
        Locale('en'),
      ],
      home: const SplashScreen(),
      routes: {
        '/auth': (_) => const AuthWrapper(),
        '/onboarding': (_) => const OnboardingScreen(),
        '/': (_) => const HomeScreen(),
        '/settings': (_) => const SettingsScreen(),
        '/login': (_) => const LoginScreen(),
        '/register': (_) => const RegisterScreen(),
        '/categorias': (_) => const CategoriasScreen(),
        '/ingreso': (_) => const IngresoScreen(),
        '/gasto': (_) => const GastoScreen(),
        '/destinar': (_) => const DestinarScreen(),
        '/reparto': (_) => const RepartoScreen(),
        '/historial': (_) => const HistorialScreen(),
        '/currency-setup': (_) => const CurrencySetupScreen(),
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  late final Future<_AuthDecision> _decisionFuture;

  @override
  void initState() {
    super.initState();
    _decisionFuture = _resolver();
  }

  Future<_AuthDecision> _resolver() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return _AuthDecision.login;

    final provider = context.read<AppProvider>();

    if (provider.esNuevoUsuario) return _AuthDecision.currencySetup;

    // Login normal: sincronizar moneda desde Firestore si SharedPreferences está vacío
    final monedaRemota = await provider.firestoreService.leerMonedaUsuario();
    if (monedaRemota != null) {
      await provider.setCurrency(monedaRemota);
    }

    return _AuthDecision.home;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_AuthDecision>(
      future: _decisionFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        switch (snapshot.data!) {
          case _AuthDecision.login:
            return const LoginScreen();
          case _AuthDecision.currencySetup:
            return const CurrencySetupScreen();
          case _AuthDecision.home:
            return const HomeScreen();
        }
      },
    );
  }
}

enum _AuthDecision { login, currencySetup, home }

class PantallaDeError extends StatelessWidget {
  final String error;
  final String stack;

  const PantallaDeError({super.key, required this.error, required this.stack});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Error de inicio',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(error, style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 16),
                Text(stack, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}