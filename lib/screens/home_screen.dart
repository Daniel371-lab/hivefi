import 'package:flutter/material.dart';
import '../widgets/banner_ad_widget.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/app_provider.dart';
import '../utils/app_translator.dart';
import '../utils/currency_formatter.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
        bottomNavigationBar: const BannerAdWidget(),
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
                const SizedBox(height: 16),
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
      _HexItem(
        icon: Icons.arrow_downward_rounded,
        label: context.tr('income'),
        route: '/ingreso',
        tooltipKey: 'tooltip_seen_ingreso',
        tooltipMsg: context.tr('tooltip_ingreso'),
      ),
      _HexItem(
        icon: Icons.arrow_upward_rounded,
        label: context.tr('expense'),
        route: '/gasto',
        tooltipKey: 'tooltip_seen_gasto',
        tooltipMsg: context.tr('tooltip_gasto'),
      ),
      _HexItem(
        icon: Icons.pie_chart_rounded,
        label: context.tr('destinar'),
        route: '/destinar',
        tooltipKey: 'tooltip_seen_destinar',
        tooltipMsg: context.tr('tooltip_destinar'),
      ),
      _HexItem(
        icon: Icons.grid_view_rounded,
        label: context.tr('categories'),
        route: '/categorias',
        tooltipKey: 'tooltip_seen_categorias',
        tooltipMsg: context.tr('tooltip_categorias'),
      ),
      _HexItem(
        icon: Icons.compare_arrows_rounded,
        label: context.tr('reparto'),
        route: '/reparto',
        tooltipKey: 'tooltip_seen_reparto',
        tooltipMsg: context.tr('tooltip_reparto'),
      ),
      _HexItem(
        icon: Icons.history_rounded,
        label: context.tr('history'),
        route: '/historial',
        tooltipKey: 'tooltip_seen_historial',
        tooltipMsg: context.tr('tooltip_historial'),
      ),
    ];

    return Stack(
      children: [
        Positioned.fill(
          child: Transform.scale(
            scale: 0.5,
            child: Lottie.asset(
              'assets/images/movimiento.json',
              fit: BoxFit.cover,
            ),
          ),
        ),
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
  final String tooltipKey;
  final String tooltipMsg;
  const _HexItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.tooltipKey,
    required this.tooltipMsg,
  });
}

class _HexButton extends StatefulWidget {
  final _HexItem item;
  const _HexButton({required this.item, super.key});

  @override
  State<_HexButton> createState() => _HexButtonState();
}

class _HexButtonState extends State<_HexButton>
    with SingleTickerProviderStateMixin {
  bool _showingTooltip = false;
  bool _tooltipVisto = true;
  OverlayEntry? _overlayEntry;
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  final _key = GlobalKey();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _checkTooltip();
  }

  Future<void> _checkTooltip() async {
    final prefs = await SharedPreferences.getInstance();
    final visto = prefs.getBool(widget.item.tooltipKey) ?? false;
    if (mounted) setState(() => _tooltipVisto = visto);
  }

  void _showOverlay() {
    final renderBox = _key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    final theme = Theme.of(context);

    _overlayEntry = OverlayEntry(
      builder: (_) => Positioned(
        left: offset.dx - 8,
        top: offset.dy - 90,
        width: size.width + 16,
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              onTap: _dismissAndNavigate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.18),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                  border: Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.item.tooltipMsg,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontSize: 10,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Toca para continuar',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    _controller.forward();
  }

  Future<void> _dismissAndNavigate() async {
    await _controller.reverse();
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted) {
      setState(() => _showingTooltip = false);
      Navigator.pushNamed(context, widget.item.route);
    }
  }

  Future<void> _handleTap() async {
    if (!_tooltipVisto && !_showingTooltip) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(widget.item.tooltipKey, true);
      if (mounted) {
        setState(() {
          _showingTooltip = true;
          _tooltipVisto = true;
        });
        _showOverlay();
      }
      return;
    }

    if (_showingTooltip) {
      await _dismissAndNavigate();
      return;
    }

    Navigator.pushNamed(context, widget.item.route);
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final honey = theme.colorScheme.primary;
    final onPrimary = theme.colorScheme.onPrimary;

    return GestureDetector(
      key: _key,
      onTap: _handleTap,
      child: ClipPath(
        clipper: _HexClipper(),
        child: Container(
          color: honey.withOpacity(0.90),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.item.icon, color: onPrimary, size: 26),
              const SizedBox(height: 6),
              Text(
                widget.item.label,
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

          // Tooltip overlay
          if (_showingTooltip)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _fadeAnim,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.18),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.item.tooltipMsg,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface,
                          fontSize: 10,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Toca para continuar',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
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

class _SeccionAhorros extends StatefulWidget {
  final AppProvider provider;
  const _SeccionAhorros({required this.provider});

  @override
  State<_SeccionAhorros> createState() => _SeccionAhorrosState();
}

class _SeccionAhorrosState extends State<_SeccionAhorros> {
  final _pageController = PageController(viewportFraction: 0.92);
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final honey = theme.colorScheme.primary;

    return StreamBuilder<QuerySnapshot>(
      stream: widget.provider.firestoreService.getCategoriasPorTipo('ahorro'),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox();
        }

        final docs = snapshot.data!.docs;
        final multiple = docs.length > 1;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    context.tr('savings'),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: honey,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  if (multiple)
                    Text(
                      '${_currentPage + 1} / ${docs.length}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (multiple)
              SizedBox(
                height: 140,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: docs.length,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  itemBuilder: (context, i) => Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: _AhorroCard(
                      doc: docs[i],
                      provider: widget.provider,
                    ),
                  ),
                ),
              )
            else
              _AhorroCard(doc: docs[0], provider: widget.provider),
          ],
        );
      },
    );
  }
}

class _AhorroCard extends StatelessWidget {
  final QueryDocumentSnapshot doc;
  final AppProvider provider;

  const _AhorroCard({required this.doc, required this.provider});

  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    final id = doc.id;
    final nombre = data['nombre'] as String;
    final disponible = (data['disponible'] as num).toDouble();
    final meta = (data['meta'] as num?)?.toDouble() ?? 0;
    final tieneMeta = meta > 0;
    final progreso = tieneMeta ? (disponible / meta).clamp(0.0, 1.0) : 0.0;
    final porcentaje = (progreso * 100).toInt();
    final metaAlcanzada = tieneMeta && disponible >= meta;

    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        '/reparto',
        arguments: {
          'origenId': id,
          'origenNombre': nombre,
          'origenDisponible': disponible,
          'origenTipo': 'ahorro',
        },
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
        decoration: BoxDecoration(
          color: const Color(0xFF0F3A30),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fila 1: nombre + badge meta alcanzada
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  nombre.toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFF8FB5A8),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                  ),
                ),
                if (metaAlcanzada)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Meta alcanzada',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            // Fila 2: monto a la izquierda, meta y % a la derecha
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  CurrencyFormatter.format(disponible, provider.currency),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                if (tieneMeta) ...[
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '/ ${CurrencyFormatter.format(meta, provider.currency)}',
                      style: const TextStyle(
                        color: Color(0xFF8FB5A8),
                        fontSize: 10,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '$porcentaje%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
            // Barra de progreso (siempre visible si tiene meta)
            if (tieneMeta) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progreso,
                  minHeight: 5,
                  backgroundColor: const Color(0xFF1D5244),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    metaAlcanzada ? Colors.green : const Color(0xFFD1923D),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 6),
            const Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Tocar para usar →',
                style: TextStyle(color: Color(0xFF8FB5A8), fontSize: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}