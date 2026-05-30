import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/app_provider.dart';
import '../utils/app_translator.dart';
import '../utils/currency_formatter.dart';
import 'package:lottie/lottie.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.read<AppProvider>();

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: theme.brightness == Brightness.dark
          ? SystemUiOverlayStyle.light.copyWith(
              statusBarColor: Colors.transparent,
              systemNavigationBarColor: Colors.transparent,
            )
          : SystemUiOverlayStyle.dark.copyWith(
              statusBarColor: Colors.transparent,
              systemNavigationBarColor: Colors.transparent,
            ),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        extendBody: true,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          titleSpacing: 20,
          title: StreamBuilder(
            stream: Stream.value(null),
            builder: (context, _) {
              final user = context.read<AppProvider>().authService.currentUser;
              final nombre = user?.displayName?.split(' ').first ?? 'Usuario';
              return Text(
                'Hola, $nombre',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              );
            },
          ),
          centerTitle: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.tune_rounded),
              onPressed: () => Navigator.pushNamed(context, '/settings'),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'HIVE',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    TextSpan(
                      text: '-FI',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        body: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _BalanceCarousel(provider: provider),
                const SizedBox(height: 32),
                _HexGrid(),
                const SizedBox(height: 32),
                _SeccionAhorros(provider: provider),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Carousel de balance ─────────────────────────────────────────────────────

class _BalanceCarousel extends StatefulWidget {
  final AppProvider provider;
  const _BalanceCarousel({required this.provider});

  @override
  State<_BalanceCarousel> createState() => _BalanceCarouselState();
}

class _BalanceCarouselState extends State<_BalanceCarousel> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, double>>(
      stream: widget.provider.firestoreService.getBalance(),
      builder: (context, snapshot) {
        final data = snapshot.data;
        final balanceGeneral = data?['balanceGeneral'] ?? 0;
        final balanceDisponible = data?['balanceDisponible'] ?? 0;
        final progresoGeneral = data?['progresoGeneral'] ?? 0;
        final progresoDisponible = data?['progresoDisponible'] ?? 0;
        final currency = widget.provider.currency;

        return Column(
          children: [
            SizedBox(
              height: 160,
              child: PageView(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: [
                  _BalanceCard(
                    titulo: 'Balance general',
                    monto: balanceGeneral,
                    subtitulo: 'Saldo disponible',
                    progreso: progresoGeneral,
                    currency: currency,
                  ),
                  _BalanceCard(
                    titulo: 'Balance disponible',
                    monto: balanceDisponible,
                    subtitulo: 'Dinero asignado a gastos',
                    progreso: progresoDisponible,
                    currency: currency,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(2, (i) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: _currentPage == i ? 20 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _currentPage == i
                        ? const Color(0xFFF59E0B)
                        : Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ],
        );
      },
    );
  }
}

// ─── Card de balance ─────────────────────────────────────────────────────────

class _BalanceCard extends StatelessWidget {
  final String titulo;
  final double monto;
  final String subtitulo;
  final double progreso;
  final String currency;

  static const Color _cardBg = Color(0xFF0F3A30);
  static const Color _labelColor = Color(0xFF8FB5A8);
  static const Color _trackColor = Color(0xFF1D5244);
  static const Color _progressColor = Color(0xFFD1923D);

  const _BalanceCard({
    required this.titulo,
    required this.monto,
    required this.subtitulo,
    required this.progreso,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final porcentaje = (progreso * 100).toInt();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // <-- Esto evita que la tarjeta se estire
          children: [
            Text(
              titulo.toUpperCase(),
              style: const TextStyle(
                color: _labelColor,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              CurrencyFormatter.format(monto, currency),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 24), // <-- Reemplazamos el Spacer() por un espacio fijo
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  subtitulo,
                  style: const TextStyle(
                    color: Color(0xFFB0C9C2),
                    fontSize: 13,
                  ),
                ),
                Text(
                  '$porcentaje%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progreso,
                minHeight: 6,
                backgroundColor: _trackColor,
                valueColor: const AlwaysStoppedAnimation<Color>(_progressColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// ─── Grid Hexagonal ──────────────────────────────────────────────────────────

class _HexGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final items = [
      _HexItem(icon: Icons.arrow_downward_rounded, label: context.tr('income'), route: '/ingreso'),
      _HexItem(icon: Icons.arrow_upward_rounded, label: context.tr('expense'), route: '/gasto'),
      _HexItem(icon: Icons.pie_chart_rounded, label: context.tr('destinar'), route: '/destinar'),
      _HexItem(icon: Icons.grid_view_rounded, label: context.tr('categories'), route: '/categorias'),
      _HexItem(icon: Icons.compare_arrows_rounded, label: context.tr('reparto'), route: '/reparto'),
      _HexItem(icon: Icons.history_rounded, label: context.tr('history'), route: '/historial'),
    ];

    return Stack(
      children: [
        // Capa de fondo: La animación limitada exactamente al área de los hexágonos
        Positioned.fill(
          child: Transform.scale(
            scale: 0.5,
            child: Lottie.asset(
              'assets/images/movimiento.json',
              fit: BoxFit.cover,
            ),
          ),
        ),

        // Capa de arriba: La cuadrícula de botones interactivos
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.95,
          ),
          itemCount: items.length,
          itemBuilder: (context, i) => _HexButton(item: items[i]),
        ),
      ],
    );
  }
}

class _HexItem {
  final IconData icon;
  final String label;
  final String route;
  const _HexItem({required this.icon, required this.label, required this.route});
}

class _HexButton extends StatelessWidget {
  final _HexItem item;
  const _HexButton({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final honey = theme.colorScheme.primary;
    final onPrimary = theme.colorScheme.onPrimary;

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, item.route),
      child: ClipPath(
        clipper: _HexClipper(),
        child: Container(
          // withOpacity(0.90) hace que el fondo se intuya por detrás de forma elegante
          color: honey.withOpacity(0.90),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(item.icon, color: onPrimary, size: 26),
              const SizedBox(height: 6),
              Text(
                item.label,
                style: TextStyle(
                  color: onPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                  letterSpacing: 0.3,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HexClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    return Path()
      ..moveTo(w * 0.5, 0)
      ..lineTo(w, h * 0.25)
      ..lineTo(w, h * 0.75)
      ..lineTo(w * 0.5, h)
      ..lineTo(0, h * 0.75)
      ..lineTo(0, h * 0.25)
      ..close();
  }

  @override
  bool shouldReclip(_HexClipper old) => false;
}

// ─── Sección ahorros ─────────────────────────────────────────────────────────

class _SeccionAhorros extends StatelessWidget {
  final AppProvider provider;
  const _SeccionAhorros({required this.provider});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final honey = theme.colorScheme.primary;

    return StreamBuilder<QuerySnapshot>(
      stream: provider.firestoreService.getCategoriasPorTipo('ahorro'),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox();
        }

        final docs = snapshot.data!.docs;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr('savings'),
              style: theme.textTheme.titleMedium?.copyWith(
                color: honey,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            ...docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final id = doc.id;
              final nombre = data['nombre'] as String;
              final disponible = (data['disponible'] as num).toDouble();
              final meta = (data['meta'] as num?)?.toDouble() ?? 0;
              final tieneMeta = meta > 0;
              final progreso = tieneMeta
                  ? (disponible / meta).clamp(0.0, 1.0)
                  : 0.0;
              final porcentaje = (progreso * 100).toInt();
              final metaAlcanzada = tieneMeta && disponible >= meta;

              return GestureDetector(
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/reparto',
                    arguments: {
                      'origenId': id,
                      'origenNombre': nombre,
                      'origenDisponible': disponible,
                      'origenTipo': 'ahorro',
                    },
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F3A30),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            nombre.toUpperCase(),
                            style: const TextStyle(
                              color: Color(0xFF8FB5A8),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.5,
                            ),
                          ),
                          if (metaAlcanzada)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Meta alcanzada',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        CurrencyFormatter.format(disponible, provider.currency),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                      ),
                      if (tieneMeta) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Meta: ${CurrencyFormatter.format(meta, provider.currency)}',
                          style: const TextStyle(
                            color: Color(0xFFB0C9C2),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '$porcentaje%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: progreso.toDouble(),
                                minHeight: 6,
                                backgroundColor: const Color(0xFF1D5244),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  metaAlcanzada
                                      ? Colors.green
                                      : const Color(0xFFD1923D),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),
                      const Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'Tocar para usar →',
                          style: TextStyle(
                            color: Color(0xFF8FB5A8),
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }
}