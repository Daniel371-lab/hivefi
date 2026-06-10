import '../services/ad_service.dart';
import 'package:flutter/material.dart';
import '../widgets/banner_ad_widget.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/app_provider.dart';
import '../utils/currency_formatter.dart';
import '../utils/thousands_formatter.dart';
import '../utils/app_translator.dart';

class GastoScreen extends StatelessWidget {
  const GastoScreen({super.key});

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
        appBar: AppBar(title: Text(context.tr('title_expenses'))),
        floatingActionButton: FloatingActionButton(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          onPressed: () => _mostrarFormulario(context, provider),
          child: const Icon(Icons.add),
        ),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.tr('expense_envelopes_title'),
                        style: theme.textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(context.tr('expense_envelopes_desc'),
                        style: theme.textTheme.bodySmall),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              Expanded(
                child: _ListaGastosConBuscador(provider: provider),
              ),
            ],
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
      builder: (_) => _FormularioGasto(provider: provider),
    );
  }
}

// ─── Lista gastos con buscador ─────────────────────────────────────────────

class _ListaGastosConBuscador extends StatefulWidget {
  final AppProvider provider;

  const _ListaGastosConBuscador({required this.provider});

  @override
  State<_ListaGastosConBuscador> createState() => 
      _ListaGastosConBuscadorState();
}

class _ListaGastosConBuscadorState extends State<_ListaGastosConBuscador> {
  final _searchController = TextEditingController();
  final _queryNotifier = ValueNotifier<String>('');
  List<QueryDocumentSnapshot> _docs = [];

  @override
  void dispose() {
    _searchController.dispose();
    _queryNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Optimización: Carga directa desde la memoria RAM del teléfono (0 costo)
    final providerLocal = context.watch<AppProvider>();
    _docs = providerLocal.todasLasCategorias.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return data['tipo'] == 'gasto';
    }).toList();

    if (_docs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined,
                size: 48,
                color: theme.colorScheme.onSurface.withOpacity(0.3)),
            const SizedBox(height: 12),
            Text(context.tr('noExpenseCategories'),
                style: theme.textTheme.bodySmall),
            const SizedBox(height: 4),
            Text(context.tr('createExCategoriesFirst'),
                style: theme.textTheme.bodySmall),
          ],
        ),
      );
    }

    // Ordenar de mayor a menor disponible para mejor experiencia
    _docs.sort((a, b) {
      final dispA = ((a.data() as Map<String, dynamic>)['disponible'] as num).toDouble();
      final dispB = ((b.data() as Map<String, dynamic>)['disponible'] as num).toDouble();
      return dispB.compareTo(dispA);
    });

    final tieneMuchas = _docs.length > 10;

    return Column(
      children: [
        if (tieneMuchas)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 4),
            child: TextField(
              key: const Key('search_field'),
              controller: _searchController,
              onChanged: (val) => _queryNotifier.value = val,
              style: theme.textTheme.bodySmall,
              decoration: InputDecoration(
                hintText: context.tr('search_category_hint'),
                hintStyle: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.4),
                ),
                prefixIcon: Icon(Icons.search_rounded,
                    size: 18,
                    color: theme.colorScheme.onSurface.withOpacity(0.4)),
                suffixIcon: ValueListenableBuilder<String>(
                  valueListenable: _queryNotifier,
                  builder: (context, query, _) => query.isNotEmpty
                      ? GestureDetector(
                          onTap: () {
                            _searchController.clear();
                            _queryNotifier.value = '';
                          },
                          child: Icon(Icons.close_rounded,
                              size: 16,
                              color: theme.colorScheme.onSurface
                                  .withOpacity(0.4)),
                        )
                      : const SizedBox.shrink(),
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        Expanded(
          child: ValueListenableBuilder<String>(
            valueListenable: _queryNotifier,
            builder: (context, query, _) {
              final visibles = query.isNotEmpty
                  ? _docs.where((doc) {
                      final nombre = (doc.data()
                          as Map<String, dynamic>)['nombre'] as String;
                      return nombre
                          .toLowerCase()
                          .contains(query.toLowerCase());
                    }).toList()
                  : _docs.take(10).toList();

              return visibles.isEmpty
                  ? Center(
                      child: Text(context.tr('noResults'),
                          style: theme.textTheme.bodySmall))
                  : ListView.separated(
                      padding:
                          const EdgeInsets.fromLTRB(24, 8, 24, 100),
                      itemCount: visibles.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final data =
                            visibles[i].data() as Map<String, dynamic>;
                        final id = visibles[i].id;
                        final nombre = data['nombre'] as String;
                        final disponible =
                            (data['disponible'] as num).toDouble();
                        return _TarjetaGasto(
                          id: id,
                          nombre: nombre,
                          disponible: disponible,
                          currency: widget.provider.currency,
                          provider: widget.provider,
                        );
                      },
                    );
            },
          ),
        ),
      ],
    );
  }
}

// ─── Tarjeta de gasto ─────────────────────────────────────────────────────────

class _TarjetaGasto extends StatefulWidget {
  final String id;
  final String nombre;
  final double disponible;
  final String currency;
  final AppProvider provider;

  const _TarjetaGasto({
    required this.id,
    required this.nombre,
    required this.disponible,
    required this.currency,
    required this.provider,
  });

  @override
  State<_TarjetaGasto> createState() => _TarjetaGastoState();
}

class _TarjetaGastoState extends State<_TarjetaGasto> {
  bool _expandido = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final honey = theme.colorScheme.primary;

    return GestureDetector(
      onTap: () => setState(() => _expandido = !_expandido),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: theme.colorScheme.outlineVariant.withOpacity(0.4)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          widget.nombre,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color:
                                theme.colorScheme.onSurface.withOpacity(0.6),
                            fontSize: 11,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        CurrencyFormatter.format(
                            widget.disponible, widget.currency),
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
              Divider(
                  height: 1,
                  color: theme.colorScheme.outlineVariant.withOpacity(0.4)),
              const SizedBox(height: 8),
              _HistorialGasto(
                categoriaId: widget.id,
                categoriaNombre: widget.nombre,
                provider: widget.provider,
                currency: widget.currency,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Historial de gastos por categoría ───────────────────────────────────────

// CRÍTICO: Mantenido como StatefulWidget para aislar la conexión a Firestore y evitar cobros extra por re-render al animar el scroll o expandir la tarjeta.
class _HistorialGasto extends StatefulWidget {
  final String categoriaId;
  final String categoriaNombre;
  final AppProvider provider;
  final String currency;

  const _HistorialGasto({
    required this.categoriaId,
    required this.categoriaNombre,
    required this.provider,
    required this.currency,
  });

  @override
  State<_HistorialGasto> createState() => _HistorialGastoState();
}

class _HistorialGastoState extends State<_HistorialGasto> {
  late final Stream<QuerySnapshot> _movimientosStream;

  @override
  void initState() {
    super.initState();
    // Guardamos la suscripción UNA sola vez
    _movimientosStream = widget.provider.firestoreService
        .getMovimientosPorCategoria(
            categoriaId: widget.categoriaId, tipo: 'gasto');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return StreamBuilder<QuerySnapshot>(
      stream: _movimientosStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2)));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Text(
            context.tr('no_movements_yet'),
            style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
          );
        }

        final docs = snapshot.data!.docs;

        return Column(
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final monto = (data['monto'] as num).toDouble().abs(); // Convertir a positivo para la UI
            final fecha = data['fecha'] != null
                ? (data['fecha'] as Timestamp).toDate()
                : DateTime.now();
            final dia =
                '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';

            return _FilaMovimientoGasto(
              movimientoId: doc.id,
              categoriaId: widget.categoriaId,
              categoriaNombre: widget.categoriaNombre,
              monto: monto,
              fecha: dia,
              provider: widget.provider,
              currency: widget.currency,
            );
          }).toList(),
        );
      },
    );
  }
}

// ─── Fila de movimiento de gasto ─────────────────────────────────────────────

class _FilaMovimientoGasto extends StatelessWidget {
  final String movimientoId;
  final String categoriaId;
  final String categoriaNombre;
  final double monto;
  final String fecha;
  final AppProvider provider;
  final String currency;

  const _FilaMovimientoGasto({
    required this.movimientoId,
    required this.categoriaId,
    required this.categoriaNombre,
    required this.monto,
    required this.fecha,
    required this.provider,
    required this.currency,
  });

  void _editar(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FormularioEditarGasto(
        provider: provider,
        movimientoId: movimientoId,
        categoriaId: categoriaId,
        categoriaNombre: categoriaNombre,
        montoActual: monto,
      ),
    );
  }

  Future<void> _eliminar(BuildContext context) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.tr('delete_expense_title')),
        content: Text(context.tr('delete_expense_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.tr('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              context.tr('delete'),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
    if (confirmar != true) return;
    await provider.firestoreService.eliminarGasto(
      movimientoId: movimientoId,
      categoriaId: categoriaId,
      monto: monto,
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
            style: theme.textTheme.bodySmall
                ?.copyWith(fontSize: 11, color: theme.colorScheme.onSurface.withOpacity(0.5)),
          ),
          Text(
            CurrencyFormatter.format(monto, currency),
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: honey,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () => _editar(context),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.edit_outlined,
                    size: 14,
                    color: theme.colorScheme.onSurface.withOpacity(0.4),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => _eliminar(context),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.delete_outline_rounded,
                    size: 14,
                    color: theme.colorScheme.error.withOpacity(0.6),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Formulario agregar gasto ────────────────────────────────────────────────

class _FormularioGasto extends StatefulWidget {
  final AppProvider provider;
  final String? categoriaId;
  final String? categoriaNombre;

  const _FormularioGasto({
    required this.provider,
    this.categoriaId,
    this.categoriaNombre,
  });

  @override
  State<_FormularioGasto> createState() => _FormularioGastoState();
}

class _FormularioGastoState extends State<_FormularioGasto> {
  final _montoController = TextEditingController();
  String? _categoriaSeleccionada;
  String? _categoriaNombreSeleccionada;
  List<Map<String, dynamic>> _categorias = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _categoriaSeleccionada = widget.categoriaId;
    _categoriaNombreSeleccionada = widget.categoriaNombre;
    _cargarCategoriasLocales();
  }

  void _cargarCategoriasLocales() {
    // Optimización: Carga sincrónica en 0 ms desde la memoria del Provider
    final docsLocales = widget.provider.todasLasCategorias.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return data['tipo'] == 'gasto';
    }).toList();

    setState(() {
      _categorias = docsLocales.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'nombre': data['nombre'],
        };
      }).toList();
    });
  }

  @override
  void dispose() {
    _montoController.dispose();
    super.dispose();
  }

  Future<void> _confirmar() async {
    if (_categoriaSeleccionada == null) {
      setState(() => _errorMessage = context.tr('error_select_category'));
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

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await widget.provider.firestoreService.registrarGasto(
        categoriaId: _categoriaSeleccionada!,
        categoriaNombre: _categoriaNombreSeleccionada!,
        monto: monto,
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('expenseRegistered')),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
        AdService.instance.mostrarInterstitialSiCorresponde();
      }
    } catch (e) {
      setState(() => _errorMessage = context.tr('error_registering_expense'));
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
            Text(context.tr('register_expense_title'),
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            Text(context.tr('which_account_money_exits'),
                style: theme.textTheme.bodySmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _categorias.isEmpty
                ? Text(context.tr('loading_categories'))
                : DropdownButtonFormField<String>(
                    value: _categoriaSeleccionada,
                    hint: Text(context.tr('select_category_hint')),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                            color:
                                theme.colorScheme.surfaceContainerHighest),
                      ),
                    ),
                    items: _categorias
                        .map((c) => DropdownMenuItem(
                              value: c['id'] as String,
                              child: Text(c['nombre'] as String),
                            ))
                        .toList(),
                    onChanged: (val) {
                      setState(() {
                        _categoriaSeleccionada = val;
                        _categoriaNombreSeleccionada = _categorias
                            .firstWhere((c) => c['id'] == val)['nombre']
                            as String;
                      });
                    },
                  ),
            const SizedBox(height: 20),
            Text(context.tr('expense_amount_label'),
                style: theme.textTheme.bodySmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _montoController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                ThousandsFormatter(currencyCode: widget.provider.currency),
              ],
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _confirmar(),
              decoration: InputDecoration(
                hintText: CurrencyFormatter.format(
                    0, widget.provider.currency),
              ),
              onChanged: (val) {
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
                    style:
                        const TextStyle(color: Colors.red, fontSize: 13)),
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
                    : Text(context.tr('confirm_expense')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Formulario editar monto de gasto ────────────────────────────────────────

class _FormularioEditarGasto extends StatefulWidget {
  final AppProvider provider;
  final String movimientoId;
  final String categoriaId;
  final String categoriaNombre;
  final double montoActual;

  const _FormularioEditarGasto({
    required this.provider,
    required this.movimientoId,
    required this.categoriaId,
    required this.categoriaNombre,
    required this.montoActual,
  });

  @override
  State<_FormularioEditarGasto> createState() =>
      _FormularioEditarGastoState();
}

class _FormularioEditarGastoState extends State<_FormularioEditarGasto> {
  late TextEditingController _montoController;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _montoController = TextEditingController(
      text: CurrencyFormatter.format(widget.montoActual, widget.provider.currency)
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
      setState(() => _errorMessage = context.tr('error_enter_amount'));
      return;
    }

    final nuevoMonto = CurrencyFormatter.parseAmount(
        _montoController.text, widget.provider.currency);

    if (nuevoMonto <= 0) {
      setState(() => _errorMessage = context.tr('error_invalid_amount'));
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await widget.provider.firestoreService.editarGasto(
        movimientoId: widget.movimientoId,
        categoriaId: widget.categoriaId,
        categoriaNombre: widget.categoriaNombre,
        montoAnterior: widget.montoActual,
        montoNuevo: nuevoMonto,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _errorMessage = context.tr('error_editing_expense'));
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
            Text(context.tr('edit_expense_title'),
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            Text(context.tr('new_amount_label'),
                style: theme.textTheme.bodySmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _montoController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                ThousandsFormatter(currencyCode: widget.provider.currency),
              ],
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _guardar(),
              onChanged: (val) {
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
