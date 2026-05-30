import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/app_provider.dart';
import '../utils/currency_formatter.dart';
import '../utils/thousands_formatter.dart';
import '../services/ad_service.dart';

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
        appBar: AppBar(title: const Text('Gastos')),
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
                    Text('Sobres de gasto',
                        style: theme.textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text('Solo podés gastar dinero que fue destinado.',
                        style: theme.textTheme.bodySmall),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: provider.firestoreService
                      .getCategoriasPorTipo('gasto'),
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
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.3)),
                            const SizedBox(height: 12),
                            Text('Sin sobres de gasto.',
                                style: theme.textTheme.bodySmall),
                            const SizedBox(height: 4),
                            Text('Creá uno en Categorías primero.',
                                style: theme.textTheme.bodySmall),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
                      itemCount: snapshot.data!.docs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final data = snapshot.data!.docs[i].data()
                            as Map<String, dynamic>;
                        final id = snapshot.data!.docs[i].id;
                        final nombre = data['nombre'] as String;
                        final disponible =
                            (data['disponible'] as num).toDouble();

                        return _TarjetaGasto(
                          id: id,
                          nombre: nombre,
                          disponible: disponible,
                          currency: provider.currency,
                          provider: provider,
                        );
                      },
                    );
                  },
                ),
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
    final sinFondos = widget.disponible <= 0;

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
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                            fontSize: 11,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (sinFondos)
                        Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Sin fondos',
                            style: TextStyle(
                                color: Colors.red,
                                fontSize: 10,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      Text(
                        CurrencyFormatter.format(
                            widget.disponible, widget.currency),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: sinFondos
                              ? theme.colorScheme.onSurface.withOpacity(0.3)
                              : honey,
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
              _HistorialGastos(
                categoriaId: widget.id,
                categoriaNombre: widget.nombre,
                disponibleSobre: widget.disponible,
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

// ─── Historial de gastos ──────────────────────────────────────────────────────

class _HistorialGastos extends StatelessWidget {
  final String categoriaId;
  final String categoriaNombre;
  final double disponibleSobre;
  final String currency;
  final AppProvider provider;

  const _HistorialGastos({
    required this.categoriaId,
    required this.categoriaNombre,
    required this.disponibleSobre,
    required this.currency,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return StreamBuilder<QuerySnapshot>(
      stream: provider.firestoreService.getMovimientosPorCategoria(
        categoriaId: categoriaId,
        tipo: 'gasto',
      ),
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

            return _FilaGasto(
              movimientoId: doc.id,
              categoriaId: categoriaId,
              categoriaNombre: categoriaNombre,
              monto: monto,
              fecha: dia,
              disponibleSobre: disponibleSobre,
              currency: currency,
              provider: provider,
            );
          }).toList(),
        );
      },
    );
  }
}

// ─── Fila de gasto ────────────────────────────────────────────────────────────

class _FilaGasto extends StatelessWidget {
  final String movimientoId;
  final String categoriaId;
  final String categoriaNombre;
  final double monto;
  final String fecha;
  final double disponibleSobre;
  final String currency;
  final AppProvider provider;

  const _FilaGasto({
    required this.movimientoId,
    required this.categoriaId,
    required this.categoriaNombre,
    required this.monto,
    required this.fecha,
    required this.disponibleSobre,
    required this.currency,
    required this.provider,
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
        disponibleSobre: disponibleSobre,
      ),
    );
  }

  void _confirmarEliminar(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar gasto'),
        content: Text(
          'Se eliminará el gasto y se devolverán ${CurrencyFormatter.format(monto, currency)} al sobre.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              await provider.firestoreService.eliminarGasto(
                movimientoId: movimientoId,
                categoriaId: categoriaId,
                monto: monto,
              );
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
          Text(
            '-${CurrencyFormatter.format(monto, currency)}',
            style: const TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          Row(
            children: [
              GestureDetector(
                onTap: () => _editar(context),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(Icons.edit_outlined,
                      size: 14,
                      color: theme.colorScheme.onSurface.withOpacity(0.4)),
                ),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () => _confirmarEliminar(context),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(Icons.delete_outline,
                      size: 14, color: Colors.red.withOpacity(0.5)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Formulario registrar gasto ───────────────────────────────────────────────

class _FormularioGasto extends StatefulWidget {
  final AppProvider provider;

  const _FormularioGasto({required this.provider});

  @override
  State<_FormularioGasto> createState() => _FormularioGastoState();
}

class _FormularioGastoState extends State<_FormularioGasto> {
  final _montoController = TextEditingController();
  String? _categoriaSeleccionada;
  String? _categoriaNombreSeleccionada;
  double? _disponibleSeleccionado;
  List<Map<String, dynamic>> _categorias = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _cargarCategorias();
  }

  Future<void> _cargarCategorias() async {
    final snapshot = await widget.provider.firestoreService
        .getCategoriasPorTipo('gasto')
        .first;
    setState(() {
      _categorias = snapshot.docs
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
    });
  }

  @override
  void dispose() {
    _montoController.dispose();
    super.dispose();
  }

  Future<void> _confirmar() async {
    if (_categoriaSeleccionada == null) {
      setState(() => _errorMessage = 'Seleccioná un sobre.');
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

    if (_disponibleSeleccionado != null && monto > _disponibleSeleccionado!) {
      setState(() => _errorMessage =
          'No tenés suficiente dinero. Disponible: ${CurrencyFormatter.format(_disponibleSeleccionado!, widget.provider.currency)}');
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
      if (mounted) Navigator.pop(context);
      await AdService.instance.mostrarInterstitialSiCorresponde();
    } catch (e) {
      setState(() => _errorMessage = 'Error al registrar el gasto.');
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
            Text('Registrar gasto',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            Text('¿De qué sobre sale el dinero?',
                style: theme.textTheme.bodySmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _categorias.isEmpty
                ? Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'No tenés sobres con dinero disponible. Primero destiná dinero.',
                      style: TextStyle(color: Colors.orange, fontSize: 13),
                    ),
                  )
                : DropdownButtonFormField<String>(
                    value: _categoriaSeleccionada,
                    hint: const Text('Seleccioná un sobre'),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                            color: theme.colorScheme.surfaceContainerHighest),
                      ),
                    ),
                    items: _categorias
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
                        _categoriaSeleccionada = val;
                        final cat =
                            _categorias.firstWhere((c) => c['id'] == val);
                        _categoriaNombreSeleccionada = cat['nombre'] as String;
                        _disponibleSeleccionado = cat['disponible'] as double;
                      });
                    },
                  ),
            if (_disponibleSeleccionado != null) ...[
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'Disponible: ${CurrencyFormatter.format(_disponibleSeleccionado!, widget.provider.currency)}',
                  style: TextStyle(
                      color: honey,
                      fontWeight: FontWeight.w600,
                      fontSize: 13),
                ),
              ),
            ],
            const SizedBox(height: 20),
            Text('Monto a gastar',
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
                hintText:
                    CurrencyFormatter.format(0, widget.provider.currency),
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
                onPressed: _categorias.isEmpty || _isLoading ? null : _confirmar,
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white))
                    : const Text('Confirmar gasto'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Formulario editar gasto ──────────────────────────────────────────────────

class _FormularioEditarGasto extends StatefulWidget {
  final AppProvider provider;
  final String movimientoId;
  final String categoriaId;
  final String categoriaNombre;
  final double montoActual;
  final double disponibleSobre;

  const _FormularioEditarGasto({
    required this.provider,
    required this.movimientoId,
    required this.categoriaId,
    required this.categoriaNombre,
    required this.montoActual,
    required this.disponibleSobre,
  });

  @override
  State<_FormularioEditarGasto> createState() => _FormularioEditarGastoState();
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
      setState(() => _errorMessage = 'Ingresá un monto.');
      return;
    }

    final nuevoMonto = CurrencyFormatter.parseAmount(
        _montoController.text, widget.provider.currency);

    if (nuevoMonto <= 0) {
      setState(() => _errorMessage = 'El monto no es válido.');
      return;
    }

    // El máximo permitido es disponible actual + monto anterior
    final maxPermitido = widget.disponibleSobre + widget.montoActual;
    if (nuevoMonto > maxPermitido) {
      setState(() => _errorMessage =
          'El monto supera el límite del sobre. Máximo: ${CurrencyFormatter.format(maxPermitido, widget.provider.currency)}');
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
        montoAnterior: widget.montoActual,
        montoNuevo: nuevoMonto,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _errorMessage = 'Error al editar el gasto.');
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
            Text('Editar gasto',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('Sobre: ${widget.categoriaNombre}',
                style: theme.textTheme.bodySmall),
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