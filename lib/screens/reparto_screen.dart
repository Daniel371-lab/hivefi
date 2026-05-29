import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/app_provider.dart';
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
    final provider = context.read<AppProvider>();

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
        appBar: AppBar(title: const Text('Reparto')),
        floatingActionButton: FloatingActionButton(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          onPressed: () => _mostrarFormulario(context, provider, origenInicial),
          child: const Icon(Icons.compare_arrows_rounded),
        ),
        body: SafeArea(
          child: StreamBuilder<QuerySnapshot>(
            stream: provider.firestoreService.getCategoriasPorTipo('gasto'),
            builder: (context, snapshotGastos) {
              return StreamBuilder<QuerySnapshot>(
                stream: provider.firestoreService.getCategoriasPorTipo('ahorro'),
                builder: (context, snapshotAhorros) {
                  if (snapshotGastos.connectionState == ConnectionState.waiting ||
                      snapshotAhorros.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final gastos = snapshotGastos.data?.docs ?? [];
                  final ahorros = snapshotAhorros.data?.docs ?? [];
                  final todos = [...gastos, ...ahorros];

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
                            Text('Sin sobres creados',
                                style: theme.textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Text('Creá categorías de gasto o ahorro primero.',
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
                        Text('Mover dinero entre sobres',
                            style: theme.textTheme.headlineMedium
                                ?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text('Reasigná dinero entre tus sobres de gasto y ahorro.',
                            style: theme.textTheme.bodySmall),
                        const SizedBox(height: 16),

                        if (gastos.isNotEmpty) ...[
                          Text('Sobres de gasto',
                              style: theme.textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 8),
                          ...gastos.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            return _TarjetaSobre(
                              id: doc.id,
                              nombre: data['nombre'] as String,
                              disponible: (data['disponible'] as num).toDouble(),
                              meta: (data['meta'] as num?)?.toDouble() ?? 0,
                              tipo: 'gasto',
                              currency: provider.currency,
                              provider: provider,
                            );
                          }),
                          const SizedBox(height: 16),
                        ],

                        if (ahorros.isNotEmpty) ...[
                          Text('Sobres de ahorro',
                              style: theme.textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 8),
                          ...ahorros.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            return _TarjetaSobre(
                              id: doc.id,
                              nombre: data['nombre'] as String,
                              disponible: (data['disponible'] as num).toDouble(),
                              meta: (data['meta'] as num?)?.toDouble() ?? 0,
                              tipo: 'ahorro',
                              currency: provider.currency,
                              provider: provider,
                            );
                          }),
                        ],
                      ],
                    ),
                  );
                },
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
                            metaAlcanzada ? 'Meta alcanzada' : 'En progreso',
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
                    'Meta: ${CurrencyFormatter.format(widget.meta, widget.currency)}',
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

class _HistorialReparto extends StatelessWidget {
  final String categoriaId;
  final String currency;
  final AppProvider provider;

  const _HistorialReparto({
    required this.categoriaId,
    required this.currency,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return StreamBuilder<QuerySnapshot>(
      stream: provider.firestoreService.getMovimientosPorCategoria(
        categoriaId: categoriaId,
        tipo: 'reparto',
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
              height: 16,
              width: 16,
              child: CircularProgressIndicator(strokeWidth: 2));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Text('Sin movimientos aún.',
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
            final esOrigen = data['categoriaOrigenId'] == categoriaId;

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
                    CurrencyFormatter.format(monto, currency),
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
    _cargarSobres();
  }

  Future<void> _cargarSobres() async {
    final snapshotGastos = await widget.provider.firestoreService
        .getCategoriasPorTipo('gasto')
        .first;
    final snapshotAhorros = await widget.provider.firestoreService
        .getCategoriasPorTipo('ahorro')
        .first;

    setState(() {
      _sobres = [
        ...snapshotGastos.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'id': doc.id,
            'nombre': data['nombre'],
            'disponible': (data['disponible'] as num).toDouble(),
            'tipo': 'gasto',
            'meta': 0.0,
          };
        }),
        ...snapshotAhorros.docs.map((doc) {
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
      setState(() => _errorMessage = 'Seleccioná el sobre de origen.');
      return;
    }
    if (_destinoId == null) {
      setState(() => _errorMessage = 'Seleccioná el sobre de destino.');
      return;
    }
    if (_origenId == _destinoId) {
      setState(() => _errorMessage = 'El origen y destino no pueden ser iguales.');
      return;
    }
    if (_montoController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Ingresá un monto.');
      return;
    }

    final monto = CurrencyFormatter.parseAmount(
        _montoController.text, widget.provider.currency);

    if (monto <= 0) {
      setState(() => _errorMessage = 'El monto no es válido.');
      return;
    }

    if (_origenDisponible != null && monto > _origenDisponible!) {
      setState(() => _errorMessage =
          'No tenés suficiente dinero en ese sobre. Disponible: ${CurrencyFormatter.format(_origenDisponible!, widget.provider.currency)}');
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
          title: const Text('¿Estás seguro?'),
          content: Text(
            'Este sobre de ahorro aún no alcanzó su meta. '
            'Si movés ${CurrencyFormatter.format(monto, widget.provider.currency)}, '
            'reducirás el dinero destinado a ese ahorro. ¿Querés continuar?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Continuar'),
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
      setState(() => _errorMessage = 'Error al realizar el reparto.');
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
              Text('Mover dinero',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text('Reasigná dinero entre tus sobres.',
                  style: theme.textTheme.bodySmall),
              const SizedBox(height: 20),
              Text('¿De qué sobre sacás el dinero?',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _origenId,
                hint: const Text('Seleccioná el origen'),
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
                                  s['tipo'] == 'ahorro' ? 'Ahorro' : 'Gasto',
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
                    'Disponible: ${CurrencyFormatter.format(_origenDisponible!, widget.provider.currency)}',
                    style: TextStyle(
                        color: honey,
                        fontWeight: FontWeight.w600,
                        fontSize: 13),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Text('¿A qué sobre lo enviás?',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _destinoId,
                hint: const Text('Seleccioná el destino'),
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
                                  s['tipo'] == 'ahorro' ? 'Ahorro' : 'Gasto',
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
              Text('Monto a mover',
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
                      : const Text('Confirmar reparto'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}