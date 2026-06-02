import 'package:flutter/material.dart';
import '../widgets/banner_ad_widget.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/app_provider.dart';
import '../utils/currency_formatter.dart';
import '../utils/thousands_formatter.dart';
import '../utils/app_translator.dart';

class IngresoScreen extends StatelessWidget {
  const IngresoScreen({super.key});

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
        appBar: AppBar(title: const Text('Ingresos')),
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
                    Text('Sobres de ingreso',
                        style: theme.textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text('Dinero disponible para distribuir.',
                        style: theme.textTheme.bodySmall),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              Expanded(
                child: _ListaIngresosConBuscador(provider: provider),
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
      builder: (_) => _FormularioIngreso(provider: provider),
    );
  }
}

// ─── Lista ingresos con buscador ─────────────────────────────────────────────

class _ListaIngresosConBuscador extends StatefulWidget {
  final AppProvider provider;
  const _ListaIngresosConBuscador({required this.provider});

  @override
  State<_ListaIngresosConBuscador> createState() =>
      _ListaIngresosConBuscadorState();
}

class _ListaIngresosConBuscadorState
    extends State<_ListaIngresosConBuscador> {
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

    return StreamBuilder<QuerySnapshot>(
      stream: widget.provider.firestoreService
          .getCategoriasPorTipo('ingreso'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_outlined,
                    size: 48,
                    color: theme.colorScheme.onSurface.withOpacity(0.3)),
                const SizedBox(height: 12),
                Text(context.tr('noIncomeCategories'),
                    style: theme.textTheme.bodySmall),
                const SizedBox(height: 4),
                Text(context.tr('createInCategoriesFirst'),
                    style: theme.textTheme.bodySmall),
              ],
            ),
          );
        }

        final docs = snapshot.data!.docs;
        final tieneMuchas = docs.length > 10;

        final visibles = _query.isNotEmpty
            ? docs.where((doc) {
                final nombre =
                    (doc.data() as Map<String, dynamic>)['nombre'] as String;
                return nombre.toLowerCase().contains(_query.toLowerCase());
              }).toList()
            : docs.take(10).toList();

        return Column(
          children: [
            if (tieneMuchas)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 4),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _query = val),
                  style: theme.textTheme.bodySmall,
                  decoration: InputDecoration(
                    hintText: 'Buscar categoría...',
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
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.4)),
                          )
                        : null,
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
              child: visibles.isEmpty
                  ? Center(
                      child: Text(context.tr('noResults'),
                          style: theme.textTheme.bodySmall))
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
                      itemCount: visibles.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final data =
                            visibles[i].data() as Map<String, dynamic>;
                        final id = visibles[i].id;
                        final nombre = data['nombre'] as String;
                        final disponible =
                            (data['disponible'] as num).toDouble();
                        return _TarjetaIngreso(
                          id: id,
                          nombre: nombre,
                          disponible: disponible,
                          currency: widget.provider.currency,
                          provider: widget.provider,
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

// ─── Tarjeta de ingreso ───────────────────────────────────────────────────────

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
              _HistorialIngreso(
                categoriaId: widget.id,
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

// ─── Historial de ingresos por categoría ─────────────────────────────────────

class _HistorialIngreso extends StatelessWidget {
  final String categoriaId;
  final AppProvider provider;
  final String currency;

  const _HistorialIngreso({
    required this.categoriaId,
    required this.provider,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return StreamBuilder<QuerySnapshot>(
      stream: provider.firestoreService
          .getMovimientosIngresoPorCategoria(categoriaId),
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
            'Sin movimientos aún.',
            style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
          );
        }

        final docs = snapshot.data!.docs;

        return Column(
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final monto = (data['monto'] as num).toDouble();
            final fecha = data['fecha'] != null
                ? (data['fecha'] as Timestamp).toDate()
                : DateTime.now();
            final dia =
                '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';

            return _FilaMovimientoIngreso(
              movimientoId: doc.id,
              categoriaId: categoriaId,
              monto: monto,
              fecha: dia,
              provider: provider,
              currency: currency,
            );
          }).toList(),
        );
      },
    );
  }
}

// ─── Fila de movimiento de ingreso ───────────────────────────────────────────

class _FilaMovimientoIngreso extends StatefulWidget {
  final String movimientoId;
  final String categoriaId;
  final double monto;
  final String fecha;
  final AppProvider provider;
  final String currency;

  const _FilaMovimientoIngreso({
    required this.movimientoId,
    required this.categoriaId,
    required this.monto,
    required this.fecha,
    required this.provider,
    required this.currency,
  });

  @override
  State<_FilaMovimientoIngreso> createState() => _FilaMovimientoIngresoState();
}

class _FilaMovimientoIngresoState extends State<_FilaMovimientoIngreso> {
  bool _fueDestinado = false;
  bool _chequeado = false;

  @override
  void initState() {
    super.initState();
    _verificar();
  }

  Future<void> _verificar() async {
    final fue = await widget.provider.firestoreService
        .movimientoIngresoFueDestinado(widget.movimientoId, widget.categoriaId);
    if (mounted) {
      setState(() {
        _fueDestinado = fue;
        _chequeado = true;
      });
    }
  }

  void _editar(BuildContext context) {
    if (_fueDestinado) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
              'No se puede editar: este ingreso ya fue destinado.'),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FormularioEditarIngreso(
        provider: widget.provider,
        movimientoId: widget.movimientoId,
        categoriaId: widget.categoriaId,
        montoActual: widget.monto,
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
            widget.fecha,
            style: theme.textTheme.bodySmall
                ?.copyWith(fontSize: 11, color: theme.colorScheme.onSurface.withOpacity(0.5)),
          ),
          Text(
            CurrencyFormatter.format(widget.monto, widget.currency),
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: honey,
            ),
          ),
          if (_chequeado)
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
            )
          else
            const SizedBox(width: 22),
        ],
      ),
    );
  }
}

// ─── Formulario agregar ingreso ───────────────────────────────────────────────

class _FormularioIngreso extends StatefulWidget {
  final AppProvider provider;
  final String? categoriaId;
  final String? categoriaNombre;

  const _FormularioIngreso({
    required this.provider,
    this.categoriaId,
    this.categoriaNombre,
  });

  @override
  State<_FormularioIngreso> createState() => _FormularioIngresoState();
}

class _FormularioIngresoState extends State<_FormularioIngreso> {
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
    _cargarCategorias();
  }

  Future<void> _cargarCategorias() async {
    final snapshot = await widget.provider.firestoreService
        .getCategoriasPorTipo('ingreso')
        .first;
    setState(() {
      _categorias = snapshot.docs.map((doc) {
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
      setState(() => _errorMessage = 'Seleccioná una categoría.');
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

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await widget.provider.firestoreService.registrarIngreso(
        categoriaId: _categoriaSeleccionada!,
        categoriaNombre: _categoriaNombreSeleccionada!,
        monto: monto,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _errorMessage = 'Error al registrar el ingreso.');
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
            Text('Registrar ingreso',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            Text('¿A qué cuenta entra el dinero?',
                style: theme.textTheme.bodySmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _categorias.isEmpty
                ? const Text('Cargando categorías...')
                : DropdownButtonFormField<String>(
                    value: _categoriaSeleccionada,
                    hint: const Text('Seleccioná una categoría'),
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
            Text('Monto del ingreso',
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
                    : const Text('Confirmar ingreso'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Formulario editar monto de ingreso ──────────────────────────────────────

class _FormularioEditarIngreso extends StatefulWidget {
  final AppProvider provider;
  final String movimientoId;
  final String categoriaId;
  final double montoActual;

  const _FormularioEditarIngreso({
    required this.provider,
    required this.movimientoId,
    required this.categoriaId,
    required this.montoActual,
  });

  @override
  State<_FormularioEditarIngreso> createState() =>
      _FormularioEditarIngresoState();
}

class _FormularioEditarIngresoState extends State<_FormularioEditarIngreso> {
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
      setState(() => _errorMessage = 'Ingresá un monto.');
      return;
    }

    final nuevoMonto = CurrencyFormatter.parseAmount(
        _montoController.text, widget.provider.currency);

    if (nuevoMonto <= 0) {
      setState(() => _errorMessage = 'El monto no es válido.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await widget.provider.firestoreService.editarMontoIngreso(
        movimientoId: widget.movimientoId,
        categoriaId: widget.categoriaId,
        montoAnterior: widget.montoActual,
        montoNuevo: nuevoMonto,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _errorMessage = 'Error al editar el ingreso.');
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
            Text('Editar ingreso',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            Text('Nuevo monto',
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
                    : const Text('Guardar cambios'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}