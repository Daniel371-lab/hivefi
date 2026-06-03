import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _paginaActual = 0;

  final _paginas = const [
    _PaginaOnboarding(
      imagen: 'assets/images/onboarding1.webp',
      titulo: 'Tus finanzas en tus manos',
      descripcion:
          'Registra tus ingresos y gastos desde donde estés, en segundos.',
    ),
    _PaginaOnboarding(
      imagen: 'assets/images/onboarding2.webp',
      titulo: 'Organiza tu dinero en sobres',
      descripcion:
          'Asigna cada centavo a un propósito: comida, ahorro, transporte y más.',
    ),
    _PaginaOnboarding(
      imagen: 'assets/images/onboarding3.webp',
      titulo: 'Analiza y toma decisiones',
      descripcion:
          'Visualiza tus movimientos y entiende a dónde va tu dinero cada mes.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _terminar() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completado', true);
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/auth');
    }
  }

  void _siguiente() {
    if (_paginaActual < _paginas.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _terminar();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final honey = theme.colorScheme.primary;
    final esUltima = _paginaActual == _paginas.length - 1;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFFAFAFA),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _paginas.length,
                  onPageChanged: (i) => setState(() => _paginaActual = i),
                  itemBuilder: (_, i) => _paginas[i],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 0, 32, 40),
                child: Column(
                  children: [
                    // Indicadores
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_paginas.length, (i) {
                        final activo = i == _paginaActual;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: activo ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: activo
                                ? honey
                                : honey.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _siguiente,
                        child: Text(esUltima ? 'Comenzar' : 'Siguiente'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaginaOnboarding extends StatelessWidget {
  final String imagen;
  final String titulo;
  final String descripcion;

  const _PaginaOnboarding({
    required this.imagen,
    required this.titulo,
    required this.descripcion,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            imagen,
            height: 280,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 40),
          Text(
            titulo,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1C1917),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            descripcion,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF78716C),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}