import 'package:flutter/material.dart';
import '../widgets/banner_ad_widget.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/app_provider.dart';
import '../utils/currency_formatter.dart';
import '../utils/thousands_formatter.dart';
import '../utils/app_translator.dart';

class DestinarScreen extends StatelessWidget {
  const DestinarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // 1. Escuchamos el Provider directamente. Cero lecturas a Firebase.
    final provider = context.watch<AppProvider>();

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
        appBar: AppBar(title: Text(context.tr('allocate_money_title'))),
        floatingActionButton: FloatingActionButton(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          onPressed: () => _mostrarFormulario(context, provider),
          child: const Icon(Icons.add),
        ),
        body: SafeArea(
          child: Builder(
            builder: (context) {
              // 2. Filtramos la lista ya descargada en la memoria RAM del teléfono
              final todosIngresos = provider.todasLasCategorias.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return data['tipo'] == 'ingreso';
              }).toList();

              final ingresosConDinero = todosIngresos.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return (data['disponible'] as num).toDouble() > 0;
              }).toList();

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
                        Text(context.tr('no_available_money'),
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text(
                          context.tr('register_income_first'),
                          style: theme.textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Ordenamiento optimizado
              final ordenados = [...todosIngresos]..sort((a, b) {
                  final dA = ((a.data() as Map<String, dynamic>)['disponible'] as num).toDouble();
                  final dB = ((b.data() as Map<String, dynamic>)['disponible'] as num).toDouble();
                  return dB.compareTo(dA);
                });

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.tr('distribute_your_money'),
                        style: theme.textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(context.tr('assign_money_to_envelopes'),
                        style: theme.textTheme.bodySmall),
                    const SizedBox(height: 12),

                    // Ingresos desplegables — top 10 por disponible
                    ...ordenados.take(10).map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return _TarjetaIngreso(
                        id: doc.id,
                        nombre: data['nombre'] as String,
                        disponible: (data['disponible'] as num).toDouble(),
                        currency: provider.currency,
                        provider: provider,
                      );
                    }),
                    if (todosIngresos.length > 10)
                      TextButton.icon(
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => _BottomSheetTodosSobres(
                              tipo: 'ingreso',
                              titulo: context.tr('all_incomes'),
                              provider: provider,
                            ),
                          );
                        },
                        icon: const Icon(Icons.expand_more_rounded, size: 18),
                        label: Text('${context.tr('view_all')} (${todosIngresos.length})'),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),

                    const SizedBox(height: 24),

                    _SeccionDestino(
                      titulo: context.tr('expense_envelopes'),
                      tipo: 'gasto',
                      provider: provider,
                    ),

                    const SizedBox(height: 24),

                    _SeccionDestino(
                      titulo: context.tr('savings_envelopes'),
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

/// ─── Sección destino desplegable ──────────────────────────────────────────────

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

    // Filtramos localmente desde la RAM
    final todos = provider.todasLasCategorias.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return data['tipo'] == tipo;
    }).toList();

    if (todos.isEmpty) {
      return const SizedBox();
    }

    final ordenados = [...todos]..sort((a, b) {
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
          return _TarjetaDestino(
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
            onPressed: () => _verTodos(context),
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

  void _verTodos(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BottomSheetTodosSobres(
        tipo: tipo,
        titulo: titulo,
        provider: provider,
      ),
    );
  }
}

// ─── Bottom sheet todos los sobres ────────────────────────────────────────────

class _BottomSheetTodosSobres extends StatefulWidget {
  final String tipo;
  final String titulo;
  final AppProvider provider;

  const _BottomSheetTodosSobres({
    required this.tipo,
    required this.titulo,
    required this.provider,
  });

  @override
  State<_BottomSheetTodosSobres> createState() =>
      _BottomSheetTodosSobresState();
}

class _BottomSheetTodosSobresState extends State<_BottomSheetTodosSobres> {
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
    
    // Al mirar al provider local, si se agrega un sobre, esta vista se actualiza sola sin romper Firebase
    final provider = context.watch<AppProvider>();
    final docsLocales = provider.todasLasCategorias.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return data['tipo'] == widget.tipo;
    }).toList();

    final docsOrdenados = [...docsLocales]..sort((a, b) {
      final dispA = ((a.data() as Map<String, dynamic>)['disponible'] as num).toDouble();
      final dispB = ((b.data() as Map<String, dynamic>)['disponible'] as num).toDouble();
      return dispB.compareTo(dispA);
    });

    final filtrados = _query.isEmpty
        ? docsOrdenados
        : docsOrdenados.where((doc) {
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
                Text('${docsOrdenados.length} ${context.tr('envelopes')}',
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
                hintText: context.tr('search_envelope'),
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
                      return _TarjetaDestino(
                        id: filtrados[i].id,
                        nombre: data['nombre'] as String,
                        disponible:
                            (data['disponible'] as num).toDouble(),
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
                    '${context.tr('goal')}: ${CurrencyFormatter.format(widget.meta, widget.currency)}',
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

// CRÍTICO: Transformado a StatefulWidget para no sobrecargar Firebase en cada render
class _HistorialDestinar extends StatefulWidget {
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
  State<_HistorialDestinar> createState() => _HistorialDestinarState();
}

class _HistorialDestinarState extends State<_HistorialDestinar> {
  late final Stream<QuerySnapshot> _movimientosStream;

  @override
  void initState() {
    super.initState();
    // 3. El Stream se crea y guarda UNA SOLA VEZ, evitando bucles de facturación.
    _movimientosStream = widget.esOrigen
        ? widget.provider.firestoreService.getMovimientosDestinarPorOrigen(widget.categoriaId)
        : widget.provider.firestoreService.getMovimientosDestinarPorDestino(widget.categoriaId);
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
              disponibleOrigen: widget.disponibleOrigen,
              currency: widget.currency,
              provider: widget.provider,
              esOrigen: widget.esOrigen,
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
      setState(() => _errorMessage = context.tr('enter_an_amount'));
      return;
    }

    final nuevoMonto = CurrencyFormatter.parseAmount(
        _montoController.text, widget.provider.currency);

    if (nuevoMonto <= 0) {
      setState(() => _errorMessage = context.tr('invalid_amount'));
      return;
    }

    final diferencia = nuevoMonto - widget.montoActual;
    if (diferencia > 0 && diferencia > widget.disponibleOrigen) {
      setState(() => _errorMessage =
          '${context.tr('insufficient_income')} ${CurrencyFormatter.format(widget.disponibleOrigen, widget.provider.currency)}');
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
      setState(() => _errorMessage = context.tr('error_editing_destination'));
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
            Text(context.tr('edit_destination'),
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(
              '${widget.origenNombre} → ${widget.destinoNombre}',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 20),
            Text(context.tr('new_amount'),
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
                    : Text(context.tr('save_changes')),
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
    _cargarDatosLocales();
  }

  void _cargarDatosLocales() {
    // 4. Eliminados los "await ... .first". Carga sincrónica en 0 ms.
    final todas = widget.provider.todasLasCategorias;

    setState(() {
      _ingresos = todas
          .where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['tipo'] == 'ingreso' && (data['disponible'] as num) > 0;
          })
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return {
              'id': doc.id,
              'nombre': data['nombre'],
              'disponible': (data['disponible'] as num).toDouble(),
            };
          })
          .toList();

      _destinos = todas
          .where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['tipo'] == 'gasto' || data['tipo'] == 'ahorro';
          })
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return {
              'id': doc.id,
              'nombre': data['nombre'],
              'tipo': data['tipo'],
            };
          })
          .toList();
    });
  }

  @override
  void dispose() {
    _montoController.dispose();
    super.dispose();
  }

  Future<void> _confirmar() async {
    if (_origenId == null) {
      setState(() => _errorMessage = context.tr('select_source_of_money'));
      return;
    }
    if (_destinoId == null) {
      setState(() => _errorMessage = context.tr('select_destination_of_money'));
      return;
    }
    if (_montoController.text.trim().isEmpty) {
      setState(() => _errorMessage = context.tr('enter_an_amount'));
      return;
    }

    final monto = CurrencyFormatter.parseAmount(
        _montoController.text, widget.provider.currency);

    if (monto <= 0) {
      setState(() => _errorMessage = context.tr('invalid_amount'));
      return;
    }

    if (_origenDisponible != null && monto > _origenDisponible!) {
      setState(() => _errorMessage =
          '${context.tr('insufficient_money')} ${CurrencyFormatter.format(_origenDisponible!, widget.provider.currency)}');
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
      setState(() => _errorMessage = context.tr('error_allocating_money'));
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
            Text(context.tr('allocate_money'),
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            Text(context.tr('where_does_money_come_from'),
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
                    child: Text(
                      context.tr('no_incomes_available'),
                      style: const TextStyle(color: Colors.orange, fontSize: 13),
                    ),
                  )
                : DropdownButtonFormField<String>(
                    value: _origenId,
                    hint: Text(context.tr('select_income')),
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
                  '${context.tr('available')}: ${CurrencyFormatter.format(_origenDisponible!, widget.provider.currency)}',
                  style: TextStyle(
                      color: honey,
                      fontWeight: FontWeight.w600,
                      fontSize: 13),
                ),
              ),
            ],
            const SizedBox(height: 20),
            Text(context.tr('which_envelope_assign'),
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
                    child: Text(
                      context.tr('no_expense_savings_envelopes'),
                      style: const TextStyle(color: Colors.orange, fontSize: 13),
                    ),
                  )
                : DropdownButtonFormField<String>(
                    value: _destinoId,
                    hint: Text(context.tr('select_destination')),
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
                                          ? context.tr('savings')
                                          : context.tr('expense'),
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
            Text(context.tr('amount_to_allocate'),
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
                    : Text(context.tr('confirm_allocation')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
