import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'dart:async'; // Necesario para atrapar errores globales

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

void main() {
  // Envolvemos toda la app en una zona segura para atrapar cualquier crash
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    try {
      // Inicialización de Firebase
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: 'AIzaSyBGN6x4bwMqGDSaWyutU5QCY3cuZyWYgp4',
          appId: '1:836237128631:android:13c18bbf1a90f69e8c6e32',
          messagingSenderId: '836237128631',
          projectId: 'hivefi-39b81',
          storageBucket: 'hivefi-39b81.firebasestorage.app',
        ),
      );

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
      // Si explota en la inicialización, mostramos la pantalla de error
      runApp(PantallaDeError(error: e.toString(), stack: stackTrace.toString()));
    }
  }, (error, stackTrace) {
    // Si explota en cualquier parte asíncrona de Dart, atrapamos el crash acá
    runApp(PantallaDeError(error: error.toString(), stack: stackTrace.toString()));
  });
}

// ----------------------------------------------------------------------
// PANTALLA DE EMERGENCIA: Reemplaza al crash silencioso
// ----------------------------------------------------------------------
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
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '🚨 CRASH DETECTADO',
                  style: TextStyle(color: Colors.red, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text(
                  error,
                  style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text(
                  stack,
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------------
// TU APP ORIGINAL
// ----------------------------------------------------------------------
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
      initialRoute: '/login',
      routes: {
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
      },
    );
  }
}
