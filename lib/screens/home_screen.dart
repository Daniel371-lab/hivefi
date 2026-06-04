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
            stream: context.read<AppProvider>().authService.userChanges(),
            builder: (context, snapshot) {
              final nombre = snapshot.data?.displayName?.split(' ').first ?? context.tr('default_user');
              return Text(
                '${context.tr('hello')}, $nombre',
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
            preferredSize: const Size.fromHeight(88),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 48,
                    width: 48,
                    child: Lottie.asset(
                      'assets/images/movimiento.json',
                      fit: BoxFit.contain,
                    ),
                  ),
                  RichText(
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
                ],
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
                    titulo: context.tr('general_balance'),
                    monto: balanceGeneral,
                    subtitulo: context.tr('available_balance_subtitle'),
                    progreso: progresoGeneral,
                    currency: currency,
                    provider: widget.provider,
                    esGeneral: true,
                  ),
                  _BalanceCard(
                    titulo: context.tr('available_balance_title'),
                    monto: balanceDisponible,
                    subtitulo: context.tr('money_assigned_to_expenses'),
                    progreso: progresoDisponible,
                    currency: currency,
                    provider: widget.provider,
                    esGeneral: false,
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
  final AppProvider provider;
  final bool esGeneral;

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
    required this.provider,
    required this.esGeneral,
  });

  @override
  Widget build(BuildContext context) {
    final porcentaje = (progreso * 100).toInt();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GestureDetector(
        onTap: () => esGeneral
            ? _mostrarInformeGeneral(context)
            : _mostrarInformeDisponible(context),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: _labelColor,
                    size: 16,
                  ),
                ],
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
              const SizedBox(height: 24),
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
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(_progressColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarInformeGeneral(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _InformeGeneral(
        provider: provider,
        currency: currency,
        totalGeneral: monto,
      ),
    );
  }

  void _mostrarInformeDisponible(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _InformeDisponible(
        provider: provider,
        currency: currency,
        totalDisponible: monto,
      ),
    );
  }
}

// ─── Informe balance general ──────────────────────────────────────────────────

class _InformeGeneral extends StatelessWidget {
  final AppProvider provider;
  final String currency;
  final double totalGeneral;

  const _InformeGeneral({
    required this.provider,
    required this.currency,
    required this.totalGeneral,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final honey = theme.colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: StreamBuilder<QuerySnapshot>(
        stream: provider.firestoreService.getTodasLasCategorias(),
        builder: (context, snapshot) {
          double totalIngresos = 0;
          double totalGastos = 0;
          double totalAhorros = 0;

          if (snapshot.hasData) {
            for (final doc in snapshot.data!.docs) {
              final data = doc.data() as Map<String, dynamic>;
              final tipo = data['tipo'] as String;
              final disponible = (data['disponible'] as num).toDouble();
              if (tipo == 'ingreso') totalIngresos += disponible;
              if (tipo == 'gasto') totalGastos += disponible;
              if (tipo == 'ahorro') totalAhorros += disponible;
            }
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('general_balance_upper'),
                      style: const TextStyle(
                        color: Color(0xFF8FB5A8),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      CurrencyFormatter.format(totalGeneral, currency),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _FilaInforme(
                      label: context.tr('available_income'),
                      monto: totalIngresos,
                      currency: currency,
                      color: honey,
                      total: totalGeneral,
                    ),
                    const SizedBox(height: 12),
                    _FilaInforme(
                      label: context.tr('assigned_to_expenses'),
                      monto: totalGastos,
                      currency: currency,
                      color: Colors.blue,
                      total: totalGeneral,
                    ),
                    const SizedBox(height: 12),
                    _FilaInforme(
                      label: context.tr('in_savings'),
                      monto: totalAhorros,
                      currency: currency,
                      color: Colors.green,
                      total: totalGeneral,
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─── Informe balance disponible ───────────────────────────────────────────────

class _InformeDisponible extends StatelessWidget {
  final AppProvider provider;
  final String currency;
  final double totalDisponible;

  const _InformeDisponible({
    required this.provider,
    required this.currency,
    required this.totalDisponible,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: StreamBuilder<QuerySnapshot>(
        stream: provider.firestoreService.getCategoriasPorTipo('gasto'),
        builder: (context, snapshot) {
          final docs = snapshot.data?.docs ?? [];

          final ordenados = [...docs]..sort((a, b) {
              final dA =
                  ((a.data() as Map<String, dynamic>)['disponible'] as num)
                      .toDouble();
              final dB =
                  ((b.data() as Map<String, dynamic>)['disponible'] as num)
                      .toDouble();
              return dB.compareTo(dA);
            });

          final top5 = ordenados.take(5).toList();
          final totalSobres = ordenados.length;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('available_balance_upper'),
                      style: const TextStyle(
                        color: Color(0xFF8FB5A8),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      CurrencyFormatter.format(totalDisponible, currency),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      context.tr('top_envelopes'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (top5.isEmpty)
                      Text(context.tr('no_expense_envelopes'),
                          style: theme.textTheme.bodySmall)
                    else
                      ...top5.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final nombre = data['nombre'] as String;
                        final disponible =
                            (data['disponible'] as num).toDouble();
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _FilaInforme(
                            label: nombre,
                            monto: disponible,
                            currency: currency,
                            color: theme.colorScheme.primary,
                            total: totalDisponible,
                          ),
                        );
                      }),
                    if (totalSobres > 5) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${context.tr('and_word')} ${totalSobres - 5} ${context.tr('more_envelopes')}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─── Fila de informe ──────────────────────────────────────────────────────────

class _FilaInforme extends StatelessWidget {
  final String label;
  final double monto;
  final String currency;
  final Color color;
  final double total;

  const _FilaInforme({
    required this.label,
    required this.monto,
    required this.currency,
    required this.color,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final porcentaje = total > 0 ? (monto / total).clamp(0.0, 1.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              CurrencyFormatter.format(monto, currency),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: porcentaje,
            minHeight: 5,
            backgroundColor:
                theme.colorScheme.onSurface.withOpacity(0.08),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
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

    return GridView.builder(
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
                      context.tr('tap_to_continue'),
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
                    child: Text(
                      context.tr('goal_reached'),
                      style: const TextStyle(
                        color: Colors.green,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
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
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                context.tr('tap_to_use'),
                style: const TextStyle(color: Color(0xFF8FB5A8), fontSize: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
