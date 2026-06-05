import 'package:flutter/material.dart';
import '../widgets/banner_ad_widget.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/app_provider.dart';
import '../utils/app_translator.dart';
import '../utils/currency_formatter.dart';
import '../utils/thousands_formatter.dart';

class RepartoScreen extends StatefulWidget {
  const RepartoScreen({super.key});

  @override
  State<RepartoScreen> createState() => _RepartoScreenState();
}

class _RepartoScreenState extends State<RepartoScreen> {
  bool _yaSeAbrio = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // 1. Escuchamos el Provider directamente. Cero lecturas a Firebase en esta vista.
    final provider = context.watch<AppProvider>();

    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    _SobreInfo? origenInicial;
    if (args != null) {
      origenInicial = _SobreInfo(
        id: args['origenId'] as String,
        nombre: args['origenNombre'] as String,
        disponible: args['origenDisponible'] as double,
        tipo: args['origenTipo'] as String,
      );
    }

    // 2. Filtramos la lista local ya descargada en memoria
    final todosLosSobres = provider.todasLasCategorias;
    final gastos = todosLosSobres.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return data['tipo'] == 'gasto';
    }).toList();
    final ahorros = todosLosSobres.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return data['tipo'] == 'ahorro';
    }).toList();
    final todos = [...gastos, ...ahorros];

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
        appBar: AppBar(title: Text(context.tr('reparto_title'))),
        floatingActionButton: FloatingActionButton(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          onPressed: () => _mostrarFormulario(context, provider, origenInicial),
          child: const Icon(Icons.compare_arrows_rounded),
        ),
        body: SafeArea(
          child: Builder(
            builder: (context) {
              if (todos.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.compare_arrows_rounded,
                            size: 48,
                            color: theme.colorScheme.onSurface.withOpacity(0.3)),
                        const SizedBox(height: 12),
                        Text(context.tr('no_envelopes_created'),
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text(context.tr('create_categories_first'),
                            style: theme.textTheme.bodySmall,
                            textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                );
              }

              if (origenInicial != null && !_yaSeAbrio) {
                _yaSeAbrio = true;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _mostrarFormulario(context, provider, origenInicial);
                });
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.tr('move_money_between_envelopes'),
                        style: theme.textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(context.tr('reassign_money_desc'),
                        style: theme.textTheme.bodySmall),
                    const SizedBox(height: 16),

                    if (gastos.isNotEmpty) ...[
                      _SeccionSobresReparto(
                        titulo: context.tr('expense_envelopes_title'),
                        docs: gastos,
                        tipo: 'gasto',
                        provider: provider,
                      ),
                      const SizedBox(height: 16),
                    ],

                    if (ahorros.isNotEmpty) ...[
                      _SeccionSobresReparto(
                        titulo: context.tr('savings_envelopes_title'),
                        docs: ahorros,
                        tipo: 'ahorro',
                        provider: provider,
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _mostrarFormulario(
    BuildContext context,
    AppProvider provider,
    _SobreInfo? origen,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FormularioReparto(
        provider: provider,
        origenPreseleccionado: origen,
      ),
    );
  }
}

// ─── Tarjeta sobre desplegable ────────────────────────────────────────────────

class _TarjetaSobre extends StatefulWidget {
  final String id;
  final String nombre;
  final double disponible;
  final double meta;
  final String tipo;
  final String currency;
  final AppProvider provider;

  const _TarjetaSobre({
    required this.id,
    required this.nombre,
    required this.disponible,
    required this.meta,
    required this.tipo,
    required this.currency,
    required this.provider,
  });

  @override
  State<_TarjetaSobre> createState() => _TarjetaSobreState();
}

class _TarjetaSobreState extends State<_TarjetaSobre> {
  bool _expandido = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final honey = theme.colorScheme.primary;
    final tieneMeta = widget.tipo == 'ahorro' && widget.meta > 0;
    final progreso = tieneMeta
        ? (widget.disponible / widget.meta).clamp(0.0, 1.0)
        : 0.0;
    final metaAlcanzada = tieneMeta && widget.disponible >= widget.meta;

    return GestureDetector(
      onTap: () => setState(() => _expandido = !_expandido),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: theme.colorScheme.outlineVariant.withOpacity(0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.nombre,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (widget.tipo == 'ahorro' && tieneMeta) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: metaAlcanzada
                                ? Colors.green.withOpacity(0.15)
                                : honey.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            metaAlcanzada ? context.tr('goal_reached') : context.tr('in_progress'),
                            style: TextStyle(
                              color: metaAlcanzada ? Colors.green : honey,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(width: 8),
                      Text(
                        CurrencyFormatter.format(widget.disponible, widget.currency),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: widget.disponible > 0
                              ? honey
                              : theme.colorScheme.onSurface.withOpacity(0.3),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  _expandido
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: theme.colorScheme.onSurface.withOpacity(0.4),
                ),
              ],
            ),
            if (tieneMeta) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${context.tr('goal')}: ${CurrencyFormatter.format(widget.meta, widget.currency)}',
                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
                  ),
                  Text(
                    '${(progreso * 100).toInt()}%',
                    style: TextStyle(
                        color: metaAlcanzada ? Colors.green : honey,
                        fontWeight: FontWeight.w600,
                        fontSize: 10),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progreso,
                  minHeight: 3,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  color: metaAlcanzada ? Colors.green : honey,
                ),
              ),
            ],
            if (_expandido) ...[
              const SizedBox(height: 8),
              Divider(
                  height: 1,
                  color: theme.colorScheme.outlineVariant.withOpacity(0.4)),
              const SizedBox(height: 8),
              _HistorialReparto(
                categoriaId: widget.id,
                currency: widget.currency,
                provider: widget.provider,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Historial de reparto ─────────────────────────────────────────────────────

// 3. Convertido a StatefulWidget para aislar la conexión y evitar cobros extra por re-render.
class _HistorialReparto extends StatefulWidget {
  final String categoriaId;
  final String currency;
  final AppProvider provider;

  const _HistorialReparto({
    required this.categoriaId,
    required this.currency,
    required this.provider,
  });

  @override
  State<_HistorialReparto> createState() => _HistorialRepartoState();
}

class _HistorialRepartoState extends State<_HistorialReparto> {
  late final Stream<QuerySnapshot> _movimientosStream;

  @override
  void initState() {
    super.initState();
    // Guardamos la suscripción UNA sola vez
    _movimientosStream = widget.provider.firestoreService.getMovimientosPorCategoria(
      categoriaId: widget.categoriaId,
      tipo: 'reparto',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return StreamBuilder<QuerySnapshot>(
      stream: _movimientosStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
              height: 16,
              width: 16,
              child: CircularProgressIndicator(strokeWidth: 2));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Text(context.tr('no_movements_yet'),
              style: theme.textTheme.bodySmall?.copyWith(fontSize: 11));
        }

        final docs = snapshot.data!.docs.take(3).toList();

        return Column(
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final monto = (data['monto'] as num).toDouble().abs();
            final fecha = data['fecha'] != null
                ? (data['fecha'] as Timestamp).toDate()
                : DateTime.now();
            final dia =
                '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
            final origenNombre =
                data['categoriaOrigenNombre'] as String? ?? '';
            final destinoNombre =
                data['categoriaDestinoNombre'] as String? ?? '';
            final esOrigen = data['categoriaOrigenId'] == widget.categoriaId;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    dia,
                    style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        color: theme.colorScheme.onSurface.withOpacity(0.5)),
                  ),
                  Expanded(
                    child: Text(
                      esOrigen ? '→ $destinoNombre' : '← $origenNombre',
                      style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                          color: theme.colorScheme.onSurface.withOpacity(0.5)),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    CurrencyFormatter.format(monto, widget.currency),
                    style: TextStyle(
                      color: esOrigen
                          ? Colors.red.withOpacity(0.8)
                          : Colors.green.withOpacity(0.8),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

// ─── Sección sobres reparto ───────────────────────────────────────────────────

class _SeccionSobresReparto extends StatelessWidget {
  final String titulo;
  final List<QueryDocumentSnapshot> docs;
  final String tipo;
  final AppProvider provider;

  const _SeccionSobresReparto({
    required this.titulo,
    required this.docs,
    required this.tipo,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final ordenados = [...docs]..sort((a, b) {
        final dispA = ((a.data() as Map<String, dynamic>)['disponible'] as num).toDouble();
        final dispB = ((b.data() as Map<String, dynamic>)['disponible'] as num).toDouble();
        return dispB.compareTo(dispA);
      });

    final visibles = ordenados.take(10).toList();
    final tieneMas = ordenados.length > 10;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo,
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        ...visibles.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return _TarjetaSobre(
            id: doc.id,
            nombre: data['nombre'] as String,
            disponible: (data['disponible'] as num).toDouble(),
            meta: (data['meta'] as num?)?.toDouble() ?? 0,
            tipo: tipo,
            currency: provider.currency,
            provider: provider,
          );
        }),
        if (tieneMas)
          TextButton.icon(
            onPressed: () => _verTodos(context, ordenados),
            icon: const Icon(Icons.expand_more_rounded, size: 18),
            label: Text('${context.tr('view_all')} (${ordenados.length})'),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),
          ),
      ],
    );
  }

  void _verTodos(BuildContext context, List<QueryDocumentSnapshot> docs) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BottomSheetTodosSobresReparto(
        docs: docs,
        tipo: tipo,
        titulo: titulo,
        provider: provider,
      ),
    );
  }
}

// ─── Bottom sheet todos los sobres reparto ────────────────────────────────────

class _BottomSheetTodosSobresReparto extends StatefulWidget {
  final List<QueryDocumentSnapshot> docs;
  final String tipo;
  final String titulo;
  final AppProvider provider;

  const _BottomSheetTodosSobresReparto({
    required this.docs,
    required this.tipo,
    required this.titulo,
    required this.provider,
  });

  @override
  State<_BottomSheetTodosSobresReparto> createState() =>
      _BottomSheetTodosSobresRepartoState();
}

class _BottomSheetTodosSobresRepartoState
    extends State<_BottomSheetTodosSobresReparto> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final filtrados = _query.isEmpty
        ? widget.docs
        : widget.docs.where((doc) {
            final nombre =
                (doc.data() as Map<String, dynamic>)['nombre'] as String;
            return nombre.toLowerCase().contains(_query.toLowerCase());
          }).toList();

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
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
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(widget.titulo,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
                Text('${widget.docs.length} ${context.tr('envelopes')}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    )),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _query = val),
              style: theme.textTheme.bodySmall,
              decoration: InputDecoration(
                hintText: context.tr('search_envelope_hint'),
                hintStyle: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.4),
                ),
                prefixIcon: Icon(Icons.search_rounded,
                    size: 18,
                    color: theme.colorScheme.onSurface.withOpacity(0.4)),
                suffixIcon: _query.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                        child: Icon(Icons.close_rounded,
                            size: 16,
                            color:
                                theme.colorScheme.onSurface.withOpacity(0.4)),
                      )
                    : null,
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.5,
            ),
            child: filtrados.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(context.tr('no_results'),
                        style: theme.textTheme.bodySmall),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: filtrados.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final data =
                          filtrados[i].data() as Map<String, dynamic>;
                      return _TarjetaSobre(
                        id: filtrados[i].id,
                        nombre: data['nombre'] as String,
                        disponible: (data['disponible'] as num).toDouble(),
                        meta: (data['meta'] as num?)?.toDouble() ?? 0,
                        tipo: widget.tipo,
                        currency: widget.provider.currency,
                        provider: widget.provider,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── Modelo sobre ─────────────────────────────────────────────────────────────

class _SobreInfo {
  final String id;
  final String nombre;
  final double disponible;
  final String tipo;

  const _SobreInfo({
    required this.id,
    required this.nombre,
    required this.disponible,
    required this.tipo,
  });
}

// ─── Formulario reparto ───────────────────────────────────────────────────────

class _FormularioReparto extends StatefulWidget {
  final AppProvider provider;
  final _SobreInfo? origenPreseleccionado;
  final _SobreInfo? destinoPreseleccionado;

  const _FormularioReparto({
    required this.provider,
    this.origenPreseleccionado,
    this.destinoPreseleccionado,
  });

  @override
  State<_FormularioReparto> createState() => _FormularioRepartoState();
}

class _FormularioRepartoState extends State<_FormularioReparto> {
  final _montoController = TextEditingController();
  String? _origenId;
  String? _origenNombre;
  double? _origenDisponible;
  String? _origenTipo;
  double? _origenMeta;
  String? _destinoId;
  String? _destinoNombre;
  List<Map<String, dynamic>> _sobres = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.origenPreseleccionado != null) {
      _origenId = widget.origenPreseleccionado!.id;
      _origenNombre = widget.origenPreseleccionado!.nombre;
      _origenDisponible = widget.origenPreseleccionado!.disponible;
      _origenTipo = widget.origenPreseleccionado!.tipo;
    }
    if (widget.destinoPreseleccionado != null) {
      _destinoId = widget.destinoPreseleccionado!.id;
      _destinoNombre = widget.destinoPreseleccionado!.nombre;
    }
    _cargarSobresLocales();
  }

  void _cargarSobresLocales() {
    // 4. Eliminados los "await ... .first". Carga sincrónica en 0 ms desde la memoria.
    final todas = widget.provider.todasLasCategorias;
    
    final gastos = todas.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return data['tipo'] == 'gasto';
    });
    final ahorros = todas.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return data['tipo'] == 'ahorro';
    });

    setState(() {
      _sobres = [
        ...gastos.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'id': doc.id,
            'nombre': data['nombre'],
            'disponible': (data['disponible'] as num).toDouble(),
            'tipo': 'gasto',
            'meta': 0.0,
          };
        }),
        ...ahorros.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'id': doc.id,
            'nombre': data['nombre'],
            'disponible': (data['disponible'] as num).toDouble(),
            'tipo': 'ahorro',
            'meta': (data['meta'] as num?)?.toDouble() ?? 0.0,
          };
        }),
      ];

      if (_origenId != null) {
        final origen =
            _sobres.firstWhere((s) => s['id'] == _origenId, orElse: () => {});
        if (origen.isNotEmpty) {
          _origenMeta = origen['meta'] as double;
        }
      }
    });
  }

  @override
  void dispose() {
    _montoController.dispose();
    super.dispose();
  }

  Future<void> _confirmar() async {
    if (_origenId == null) {
      setState(() => _errorMessage = context.tr('error_select_source'));
      return;
    }
    if (_destinoId == null) {
      setState(() => _errorMessage = context.tr('error_select_destination'));
      return;
    }
    if (_origenId == _destinoId) {
      setState(() => _errorMessage = context.tr('error_same_source_destination'));
      return;
    }
    if (_montoController.text.trim().isEmpty) {
      setState(() => _errorMessage = context.tr('error_enter_amount'));
      return;
    }

    final monto = CurrencyFormatter.parseAmount(
        _montoController.text, widget.provider.currency);

    if (monto <= 0) {
      setState(() => _errorMessage = context.tr('error_invalid_amount'));
      return;
    }

    if (_origenDisponible != null && monto > _origenDisponible!) {
      setState(() => _errorMessage =
          '${context.tr('error_insufficient_funds')} ${CurrencyFormatter.format(_origenDisponible!, widget.provider.currency)}');
      return;
    }

    final esAhorroSinMeta = _origenTipo == 'ahorro' &&
        _origenMeta != null &&
        _origenMeta! > 0 &&
        (_origenDisponible ?? 0) < _origenMeta!;

    if (esAhorroSinMeta) {
      final confirmado = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(context.tr('are_you_sure')),
          content: Text(
            '${context.tr('saving_meta_warning_part1')} '
            '${CurrencyFormatter.format(monto, widget.provider.currency)}, '
            '${context.tr('saving_meta_warning_part2')}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(context.tr('cancel')),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(context.tr('continue')),
            ),
          ],
        ),
      );
      if (confirmado != true) return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await widget.provider.firestoreService.repartirDinero(
        origenId: _origenId!,
        origenNombre: _origenNombre!,
        destinoId: _destinoId!,
        destinoNombre: _destinoNombre!,
        monto: monto,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _errorMessage = context.tr('error_performing_split'));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _sobresSinOrigen =>
      _sobres.where((s) => s['id'] != _origenId).toList();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final honey = theme.colorScheme.primary;

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              Text(context.tr('move_money_title'),
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(context.tr('reassign_money_short_desc'),
                  style: theme.textTheme.bodySmall),
              const SizedBox(height: 20),
              Text(context.tr('from_which_envelope_question'),
                  style: theme.textTheme.bodySmall
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _origenId,
                hint: Text(context.tr('select_source_hint')),
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color: theme.colorScheme.surfaceContainerHighest),
                  ),
                ),
                items: _sobres
                    .where((s) => (s['disponible'] as double) > 0)
                    .map((s) => DropdownMenuItem(
                          value: s['id'] as String,
                          child: Row(
                            children: [
                              Expanded(child: Text(s['nombre'] as String)),
                              Text(
                                CurrencyFormatter.format(
                                    s['disponible'] as double,
                                    widget.provider.currency),
                                style: TextStyle(
                                    color: honey,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 5, vertical: 2),
                                decoration: BoxDecoration(
                                  color: honey.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  s['tipo'] == 'ahorro' ? context.tr('saving') : context.tr('expense'),
                                  style: TextStyle(
                                      color: honey,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700),
                                ),
                              ),
                            ],
                          ),
                        ))
                    .toList(),
                onChanged: (val) {
                  setState(() {
                    _origenId = val;
                    final sobre = _sobres.firstWhere((s) => s['id'] == val);
                    _origenNombre = sobre['nombre'] as String;
                    _origenDisponible = sobre['disponible'] as double;
                    _origenTipo = sobre['tipo'] as String;
                    _origenMeta = sobre['meta'] as double;
                    if (_destinoId == _origenId) _destinoId = null;
                  });
                },
              ),
              if (_origenDisponible != null) ...[
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '${context.tr('available')}: ${CurrencyFormatter.format(_origenDisponible!, widget.provider.currency)}',
                    style: TextStyle(
                        color: honey,
                        fontWeight: FontWeight.w600,
                        fontSize: 13),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Text(context.tr('to_which_envelope_question'),
                  style: theme.textTheme.bodySmall
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _destinoId,
                hint: Text(context.tr('select_destination_hint')),
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color: theme.colorScheme.surfaceContainerHighest),
                  ),
                ),
                items: _sobresSinOrigen
                    .map((s) => DropdownMenuItem(
                          value: s['id'] as String,
                          child: Row(
                            children: [
                              Expanded(child: Text(s['nombre'] as String)),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 5, vertical: 2),
                                decoration: BoxDecoration(
                                  color: honey.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  s['tipo'] == 'ahorro' ? context.tr('saving') : context.tr('expense'),
                                  style: TextStyle(
                                      color: honey,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700),
                                ),
                              ),
                            ],
                          ),
                        ))
                    .toList(),
                onChanged: (val) {
                  setState(() {
                    _destinoId = val;
                    _destinoNombre =
                        _sobres.firstWhere((s) => s['id'] == val)['nombre']
                            as String;
                  });
                },
              ),
              const SizedBox(height: 20),
              Text(context.tr('amount_to_move'),
                  style: theme.textTheme.bodySmall
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                controller: _montoController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _confirmar(),
                inputFormatters: [
                  ThousandsFormatter(currencyCode: widget.provider.currency),
                ],
                decoration: InputDecoration(
                  hintText: CurrencyFormatter.format(0, widget.provider.currency),
                ),
                onChanged: (_) {
                  if (_errorMessage != null)
                    setState(() => _errorMessage = null);
                },
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(_errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 13)),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _confirmar,
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: Colors.white))
                      : Text(context.tr('confirm_split_button')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
