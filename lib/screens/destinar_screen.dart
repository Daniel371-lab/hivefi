import 'package:flutter/material.dart';
import '../widgets/banner_ad_widget.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/app_provider.dart';
import '../utils/currency_formatter.dart';
import '../utils/thousands_formatter.dart';

class DestinarScreen extends StatelessWidget {
  const DestinarScreen({super.key});

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
        appBar: AppBar(title: const Text('Destinar dinero')),
        floatingActionButton: FloatingActionButton(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          onPressed: () => _mostrarFormulario(context, provider),
          child: const Icon(Icons.add),
        ),
        body: SafeArea(
          child: StreamBuilder<QuerySnapshot>(
            stream: provider.firestoreService.getCategoriasPorTipo('ingreso'),
            builder: (context, snapshotIngresos) {
              if (snapshotIngresos.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final todosIngresos = snapshotIngresos.data?.docs ?? [];
              final ingresosConDinero = todosIngresos
                  .where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return (data['disponible'] as num).toDouble() > 0;
                  })
                  .toList();

              if (todosIngresos.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.account_balance_wallet_outlined,
                            size: 48,
                            color: theme.colorScheme.onSurface.withOpacity(0.3)),
                        const SizedBox(height: 12),
                        Text('Sin dinero disponible',
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text(
                          'Primero registrá un ingreso para poder destinar dinero.',
                          style: theme.textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Distribuí tu dinero',
                        style: theme.textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text('Asigná tu dinero a sobres de gasto o ahorro.',
                        style: theme.textTheme.bodySmall),
                    const SizedBox(height: 12),

                    // Ingresos desplegables
                    ...todosIngresos.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return _TarjetaIngreso(
                        id: doc.id,
                        nombre: data['nombre'] as String,
                        disponible: (data['disponible'] as num).toDouble(),
                        currency: provider.currency,
                        provider: provider,
                      );
                    }),

                    const SizedBox(height: 24),

                    _SeccionDestino(
                      titulo: 'Sobres de gasto',
                      tipo: 'gasto',
                      provider: provider,
                    ),

                    const SizedBox(height: 24),

                    _SeccionDestino(
                      titulo: 'Sobres de ahorro',
                      tipo: 'ahorro',
                      provider: provider,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _mostrarFormulario(BuildContext context, AppProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FormularioDestinar(provider: provider),
    );
  }
}

// ─── Tarjeta ingreso desplegable ──────────────────────────────────────────────

class _TarjetaIngreso extends StatefulWidget {
  final String id;
  final String nombre;
  final double disponible;
  final String currency;
  final AppProvider provider;

  const _TarjetaIngreso({
    required this.id,
    required this.nombre,
    required this.disponible,
    required this.currency,
    required this.provider,
  });

  @override
  State<_TarjetaIngreso> createState() => _TarjetaIngresoState();
}

class _TarjetaIngresoState extends State<_TarjetaIngreso> {
  bool _expandido = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final honey = theme.colorScheme.primary;

    return GestureDetector(
      onTap: () => setState(() => _expandido = !_expandido),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: honey.withOpacity(0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: honey.withOpacity(0.3)),
        ),
        child: Column(
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
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        CurrencyFormatter.format(widget.disponible, widget.currency),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: honey,
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
            if (_expandido) ...[
              const SizedBox(height: 8),
              Divider(height: 1, color: honey.withOpacity(0.2)),
              const SizedBox(height: 8),
              _HistorialDestinar(
                categoriaId: widget.id,
                disponibleOrigen: widget.disponible,
                currency: widget.currency,
                provider: widget.provider,
                esOrigen: true,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Sección destino desplegable ──────────────────────────────────────────────

class _SeccionDestino extends StatelessWidget {
  final String titulo;
  final String tipo;
  final AppProvider provider;

  const _SeccionDestino({
    required this.titulo,
    required this.tipo,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return StreamBuilder<QuerySnapshot>(
      stream: provider.firestoreService.getCategoriasPorTipo(tipo),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox();
        }

        final docs = snapshot.data!.docs;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo,
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            ...docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final nombre = data['nombre'] as String;
              final disponible = (data['disponible'] as num).toDouble();
              final meta = (data['meta'] as num?)?.toDouble() ?? 0;

              return _TarjetaDestino(
                id: doc.id,
                nombre: nombre,
                disponible: disponible,
                meta: meta,
                tipo: tipo,
                currency: provider.currency,
                provider: provider,
              );
            }),
          ],
        );
      },
    );
  }
}

// ─── Tarjeta destino desplegable ──────────────────────────────────────────────

class _TarjetaDestino extends StatefulWidget {
  final String id;
  final String nombre;
  final double disponible;
  final double meta;
  final String tipo;
  final String currency;
  final AppProvider provider;

  const _TarjetaDestino({
    required this.id,
    required this.nombre,
    required this.disponible,
    required this.meta,
    required this.tipo,
    required this.currency,
    required this.provider,
  });

  @override
  State<_TarjetaDestino> createState() => _TarjetaDestinoState();
}

class _TarjetaDestinoState extends State<_TarjetaDestino> {
  bool _expandido = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final honey = theme.colorScheme.primary;
    final tieneMeta = widget.tipo == 'ahorro' && widget.meta > 0;
    final progreso = tieneMeta
        ? (widget.disponible / widget.meta).clamp(0.0, 1.0)
        : 0.0;

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
                      const SizedBox(width: 8),
                      Text(
                        CurrencyFormatter.format(widget.disponible, widget.currency),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: honey,
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
                        color: honey,
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
                ),
              ),
            ],
            if (_expandido) ...[
              const SizedBox(height: 8),
              Divider(
                  height: 1,
                  color: theme.colorScheme.outlineVariant.withOpacity(0.4)),
              const SizedBox(height: 8),
              _HistorialDestinar(
                categoriaId: widget.id,
                disponibleOrigen: 0,
                currency: widget.currency,
                provider: widget.provider,
                esOrigen: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Historial de destinar ────────────────────────────────────────────────────

class _HistorialDestinar extends StatelessWidget {
  final String categoriaId;
  final double disponibleOrigen;
  final String currency;
  final AppProvider provider;
  final bool esOrigen;

  const _HistorialDestinar({
    required this.categoriaId,
    required this.disponibleOrigen,
    required this.currency,
    required this.provider,
    required this.esOrigen,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final stream = esOrigen
        ? provider.firestoreService
            .getMovimientosDestinarPorOrigen(categoriaId)
        : provider.firestoreService
            .getMovimientosDestinarPorDestino(categoriaId);

    return StreamBuilder<QuerySnapshot>(
      stream: stream,
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

        final docs = snapshot.data!.docs;

        return Column(
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final monto = (data['monto'] as num).toDouble().abs();
            final fecha = data['fecha'] != null
                ? (data['fecha'] as Timestamp).toDate()
                : DateTime.now();
            final dia =
                '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
            final origenId = data['categoriaOrigenId'] as String;
            final destinoId = data['categoriaDestinoId'] as String? ?? '';
            final destinoNombre =
                data['categoriaDestinoNombre'] as String? ?? '';
            final origenNombre =
                data['categoriaOrigenNombre'] as String? ?? '';

            return _FilaDestinar(
              movimientoId: doc.id,
              origenId: origenId,
              destinoId: destinoId,
              monto: monto,
              fecha: dia,
              disponibleOrigen: disponibleOrigen,
              currency: currency,
              provider: provider,
              esOrigen: esOrigen,
              origenNombre: origenNombre,
              destinoNombre: destinoNombre,
            );
          }).toList(),
        );
      },
    );
  }
}

// ─── Fila de destinar ─────────────────────────────────────────────────────────

class _FilaDestinar extends StatelessWidget {
  final String movimientoId;
  final String origenId;
  final String destinoId;
  final double monto;
  final String fecha;
  final double disponibleOrigen;
  final String currency;
  final AppProvider provider;
  final bool esOrigen;
  final String origenNombre;
  final String destinoNombre;

  const _FilaDestinar({
    required this.movimientoId,
    required this.origenId,
    required this.destinoId,
    required this.monto,
    required this.fecha,
    required this.disponibleOrigen,
    required this.currency,
    required this.provider,
    required this.esOrigen,
    required this.origenNombre,
    required this.destinoNombre,
  });

  void _editar(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FormularioEditarDestinar(
        provider: provider,
        movimientoId: movimientoId,
        origenId: origenId,
        destinoId: destinoId,
        montoActual: monto,
        disponibleOrigen: disponibleOrigen,
        origenNombre: origenNombre,
        destinoNombre: destinoNombre,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final honey = theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            fecha,
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
              color: honey,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          if (esOrigen) ...[
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () => _editar(context),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(Icons.edit_outlined,
                    size: 14,
                    color: theme.colorScheme.onSurface.withOpacity(0.4)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Formulario editar destinar ───────────────────────────────────────────────

class _FormularioEditarDestinar extends StatefulWidget {
  final AppProvider provider;
  final String movimientoId;
  final String origenId;
  final String destinoId;
  final double montoActual;
  final double disponibleOrigen;
  final String origenNombre;
  final String destinoNombre;

  const _FormularioEditarDestinar({
    required this.provider,
    required this.movimientoId,
    required this.origenId,
    required this.destinoId,
    required this.montoActual,
    required this.disponibleOrigen,
    required this.origenNombre,
    required this.destinoNombre,
  });

  @override
  State<_FormularioEditarDestinar> createState() =>
      _FormularioEditarDestinarState();
}

class _FormularioEditarDestinarState extends State<_FormularioEditarDestinar> {
  late TextEditingController _montoController;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _montoController = TextEditingController(
      text: CurrencyFormatter.format(
              widget.montoActual, widget.provider.currency)
          .replaceAll(RegExp(r'[^\d.,]'), ''),
    );
  }

  @override
  void dispose() {
    _montoController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (_montoController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Ingresá un monto.');
      return;
    }

    final nuevoMonto = CurrencyFormatter.parseAmount(
        _montoController.text, widget.provider.currency);

    if (nuevoMonto <= 0) {
      setState(() => _errorMessage = 'El monto no es válido.');
      return;
    }

    final diferencia = nuevoMonto - widget.montoActual;
    if (diferencia > 0 && diferencia > widget.disponibleOrigen) {
      setState(() => _errorMessage =
          'No tenés suficiente en el ingreso. Disponible: ${CurrencyFormatter.format(widget.disponibleOrigen, widget.provider.currency)}');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await widget.provider.firestoreService.editarMontoDestinar(
        movimientoId: widget.movimientoId,
        origenId: widget.origenId,
        destinoId: widget.destinoId,
        montoAnterior: widget.montoActual,
        montoNuevo: nuevoMonto,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _errorMessage = 'Error al editar el destino.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
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
            Text('Editar destino',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(
              '${widget.origenNombre} → ${widget.destinoNombre}',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 20),
            Text('Nuevo monto',
                style: theme.textTheme.bodySmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _montoController,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _guardar(),
              inputFormatters: [
                ThousandsFormatter(currencyCode: widget.provider.currency),
              ],
              onChanged: (_) {
                if (_errorMessage != null)
                  setState(() => _errorMessage = null);
              },
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(_errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 13)),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _guardar,
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white))
                    : const Text('Guardar cambios'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Formulario destinar ──────────────────────────────────────────────────────

class _FormularioDestinar extends StatefulWidget {
  final AppProvider provider;

  const _FormularioDestinar({required this.provider});

  @override
  State<_FormularioDestinar> createState() => _FormularioDestinarState();
}

class _FormularioDestinarState extends State<_FormularioDestinar> {
  final _montoController = TextEditingController();
  String? _origenId;
  String? _origenNombre;
  double? _origenDisponible;
  String? _destinoId;
  String? _destinoNombre;
  List<Map<String, dynamic>> _ingresos = [];
  List<Map<String, dynamic>> _destinos = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final snapshotIngresos = await widget.provider.firestoreService
        .getCategoriasPorTipo('ingreso')
        .first;
    final snapshotGastos = await widget.provider.firestoreService
        .getCategoriasPorTipo('gasto')
        .first;
    final snapshotAhorros = await widget.provider.firestoreService
        .getCategoriasPorTipo('ahorro')
        .first;

    if (!mounted) return;

    setState(() {
      _ingresos = snapshotIngresos.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return {
              'id': doc.id,
              'nombre': data['nombre'],
              'disponible': (data['disponible'] as num).toDouble(),
            };
          })
          .where((c) => (c['disponible'] as double) > 0)
          .toList();

      _destinos = [
        ...snapshotGastos.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {'id': doc.id, 'nombre': data['nombre'], 'tipo': 'gasto'};
        }),
        ...snapshotAhorros.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {'id': doc.id, 'nombre': data['nombre'], 'tipo': 'ahorro'};
        }),
      ];
    });
  }

  @override
  void dispose() {
    _montoController.dispose();
    super.dispose();
  }

  Future<void> _confirmar() async {
    if (_origenId == null) {
      setState(() => _errorMessage = 'Seleccioná de dónde sale el dinero.');
      return;
    }
    if (_destinoId == null) {
      setState(() => _errorMessage = 'Seleccioná a dónde va el dinero.');
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
          'No tenés suficiente dinero. Disponible: ${CurrencyFormatter.format(_origenDisponible!, widget.provider.currency)}');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await widget.provider.firestoreService.destinarDinero(
        origenId: _origenId!,
        origenNombre: _origenNombre!,
        destinoId: _destinoId!,
        destinoNombre: _destinoNombre!,
        monto: monto,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _errorMessage = 'Error al destinar el dinero.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

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
            Text('Destinar dinero',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            Text('¿De dónde sale el dinero?',
                style: theme.textTheme.bodySmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _ingresos.isEmpty
                ? Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'No tenés ingresos con dinero disponible.',
                      style: TextStyle(color: Colors.orange, fontSize: 13),
                    ),
                  )
                : DropdownButtonFormField<String>(
                    value: _origenId,
                    hint: const Text('Seleccioná el ingreso'),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                            color: theme.colorScheme.surfaceContainerHighest),
                      ),
                    ),
                    items: _ingresos
                        .map((c) => DropdownMenuItem(
                              value: c['id'] as String,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(c['nombre'] as String),
                                  Text(
                                    CurrencyFormatter.format(
                                        c['disponible'] as double,
                                        widget.provider.currency),
                                    style: TextStyle(
                                        color: honey,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ))
                        .toList(),
                    onChanged: (val) {
                      setState(() {
                        _origenId = val;
                        final cat =
                            _ingresos.firstWhere((c) => c['id'] == val);
                        _origenNombre = cat['nombre'] as String;
                        _origenDisponible = cat['disponible'] as double;
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
            Text('¿A qué sobre lo asignás?',
                style: theme.textTheme.bodySmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _destinos.isEmpty
                ? Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'No tenés sobres de gasto ni ahorro creados.',
                      style: TextStyle(color: Colors.orange, fontSize: 13),
                    ),
                  )
                : DropdownButtonFormField<String>(
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
                    items: _destinos
                        .map((c) => DropdownMenuItem(
                              value: c['id'] as String,
                              child: Row(
                                children: [
                                  Text(c['nombre'] as String),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: honey.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      c['tipo'] == 'ahorro'
                                          ? 'Ahorro'
                                          : 'Gasto',
                                      style: TextStyle(
                                          color: honey,
                                          fontSize: 10,
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
                        _destinoNombre = _destinos
                            .firstWhere((c) => c['id'] == val)['nombre']
                            as String;
                      });
                    },
                  ),
            const SizedBox(height: 20),
            Text('Monto a destinar',
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
                onPressed: _ingresos.isEmpty || _isLoading ? null : _confirmar,
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white))
                    : const Text('Confirmar destino'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}