import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
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

void main() async {
  // 1. Captura errores inesperados antes de que la app dibuje los widgets
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Si algo falla al renderizar, mostramos el error en una pantalla roja en el cel
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '❌ LA APP NO CRASHEÓ, ESTE ES EL ERROR:',
                    style: TextStyle(color: Colors.red, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    details.exception.toString(),
                    style: const TextStyle(color: Colors.white, fontSize: 14, fontFamily: 'monospace'),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    '🔍 DETALLES DEL ORIGEN:',
                    style: TextStyle(color: Colors.yellow, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    details.stack?.toString() ?? 'No stack trace disponible',
                    style: const TextStyle(color: Colors.grey, fontSize: 12, fontFamily: 'monospace'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  };

  // 3. Intentamos arrancar Firebase dentro de un try/catch para que no tire abajo el proceso nativo
  try {
    await Firebase.initializeApp();
  } catch (e, stackTrace) {
    // Si Firebase falla, forzamos a Flutter a renderizar la pantalla de error con los datos reales
    runApp(MaterialApp(
      home: Scaffold(
        body: Container(
          color: Colors.red[900],
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              children: [
                const Text("🚨 FALLÓ LA INICIALIZACIÓN DE FIREBASE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
                const SizedBox(height: 20),
                Text(e.toString(), style: const TextStyle(color: Colors.yellow, fontFamily: 'monospace')),
                const SizedBox(height: 20),
                Text(stackTrace.toString(), style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
        ),
      ),
    ));
    return;
  }

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
      initialRoute: '/login', 
      routes: {
        '/': (_) => const HomeScreen(),
        '/settings': (_) => const SettingsScreen(),
        '/login': (_) => LoginScreen(), 
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
