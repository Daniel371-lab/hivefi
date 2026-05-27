import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/app_provider.dart';
import '../utils/currency_formatter.dart';
import '../utils/thousands_formatter.dart'; // Asegúrate de que esta ruta sea la correcta para tu formateador

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
                  stream: provider.firestoreService.getCategoriasPorTipo('gasto'),
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
                            Text('Sin sobres de gasto.', style: theme.textTheme.bodySmall),
                            const SizedBox(height: 4),
                            Text('Creá uno en Categorías primero.', style: theme.textTheme.bodySmall),
                          ],
                        ),
                      );
                    }

                    final docs = snapshot.data!.docs;

                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
                      itemCount: docs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final data = docs[i].data() as Map<String, dynamic>;
                        final id = docs[i].id;
                        final nombre = data['nombre'] as String;
                        final disponible = (data['disponible'] as num).toDouble();

                        return _TarjetaGasto(
                          id: id,
                          nombre: nombre,
                          disponible: disponible,
                          currency: provider.currency,
                          onEditar: () => _mostrarEditarCategoria(context, provider, id, nombre),
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

  void _mostrarEditarCategoria(
    BuildContext context,
    AppProvider provider,
    String id,
    String nombre,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FormularioEditarCategoriaGasto(
        provider: provider,
        categoriaId: id,
        nombreActual: nombre,
      ),
    );
  }
}

// ─── Tarjeta de gasto ────────────────────────────────────────────────────────

class _TarjetaGasto extends StatelessWidget {
  final String id;
  final String nombre;
  final double disponible;
  final String currency;
  final VoidCallback onEditar;

  const _TarjetaGasto({
    required this.id,
    required this.nombre,
    required this.disponible,
    required this.currency,
    required this.onEditar,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final honey = theme.colorScheme.primary;
    final sinFondos = disponible <= 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  nombre,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                Row(
                  children: [
                    if (sinFondos) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Sin fondos',
                          style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                      onPressed: onEditar,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              CurrencyFormatter.format(disponible, currency),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: sinFondos ? theme.colorScheme.onSurface.withOpacity(0.4) : honey,
              ),
            ),
            _HistorialGastos(
              categoriaId: id,
              categoriaNombre: nombre,
              currency: currency,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Historial de gastos por categoría ──────────────────────────────────────

class _HistorialGastos extends StatelessWidget {
  final String categoriaId;
  final String categoriaNombre;
  final String currency;

  const _HistorialGastos({
    required this.categoriaId,
    required this.categoriaNombre,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.read<AppProvider>();

    return StreamBuilder<QuerySnapshot>(
      stream: provider.firestoreService.getMovimientosPorCategoria(
        categoriaId: categoriaId,
        tipo: 'gasto',
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox();
        }

        final docs = snapshot.data!.docs;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(height: 24),
            Text(
              'Movimientos recientes',
              style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ...docs.take(3).map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final monto = (data['monto'] as num).toDouble().abs();
              final fecha = data['fecha'] != null ? (data['fecha'] as Timestamp).toDate() : DateTime.now();

              return GestureDetector(
                onLongPress: () => _mostrarOpciones(
                  context,
                  provider,
                  doc.id,
                  categoriaId,
                  categoriaNombre,
                  monto,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '-${CurrencyFormatter.format(monto, currency)}',
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        '${fecha.day}/${fecha.month}/${fecha.year}',
                        style: theme.textTheme.bodySmall,
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

  void _mostrarOpciones(
    BuildContext context,
    AppProvider provider,
    String movimientoId,
    String categoriaId,
    String categoriaNombre,
    double monto,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Editar monto del gasto'),
              onTap: () {
                Navigator.pop(context);
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
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Eliminar gasto', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _confirmarEliminar(context, provider, movimientoId, categoriaId, monto);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _confirmarEliminar(
    BuildContext context,
    AppProvider provider,
    String movimientoId,
    String categoriaId,
    double monto,
  ) {
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
}

// ─── Formulario registrar gasto ──────────────────────────────────────────────

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
    final snapshot = await widget.provider.firestoreService.getCategoriasPorTipo('gasto').first;
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

    final monto = double.tryParse(_montoController.text.replaceAll('.', '').replaceAll(',', '.'));

    if (monto == null || monto <= 0) {
      setState(() => _errorMessage = 'El monto no es válido.');
      return;
    }

    if (_disponibleSeleccionado != null && monto > _disponibleSeleccionado!) {
      setState(() => _errorMessage =
          'No tenés suficiente dinero en este sobre. Disponible: ${CurrencyFormatter.format(_disponibleSeleccionado!, widget.provider.currency)}');
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
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Registrar gasto', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            Text('¿De qué sobre sale el dinero?',
                style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
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
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: theme.colorScheme.surfaceContainerHighest),
                      ),
                    ),
                    items: _categorias
                        .map((c) => DropdownMenuItem(
                              value: c['id'] as String,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(c['nombre'] as String),
                                  Text(
                                    CurrencyFormatter.format(c['disponible'] as double, widget.provider.currency),
                                    style: TextStyle(color: honey, fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ))
                        .toList(),
                    onChanged: (val) {
                      setState(() {
                        _categoriaSeleccionada = val;
                        final cat = _categorias.firstWhere((c) => c['id'] == val);
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
                  style: TextStyle(color: honey, fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
            ],
            const SizedBox(height: 20),
            Text('Monto a gastar', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _montoController,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _confirmar(),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                ThousandsFormatter(),
              ],
              decoration: InputDecoration(
                hintText: CurrencyFormatter.format(0, widget.provider.currency),
              ),
              onChanged: (_) {
                if (_errorMessage != null) setState(() => _errorMessage = null);
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
                child: Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 13)),
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
                        width: 22, height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                    : const Text('Confirmar gasto'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Formulario editar gasto (Monto) ─────────────────────────────────────────

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
  State<_FormularioEditarGasto> createState() => _FormularioEditarGastoState();
}

class _FormularioEditarGastoState extends State<_FormularioEditarGasto> {
  late TextEditingController _montoController;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _montoController = TextEditingController(text: widget.montoActual.toStringAsFixed(0));
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

    final nuevoMonto = double.tryParse(_montoController.text.replaceAll('.', '').replaceAll(',', '.'));

    if (nuevoMonto == null || nuevoMonto <= 0) {
      setState(() => _errorMessage = 'El monto no es válido.');
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
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Editar gasto', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('Sobre: ${widget.categoriaNombre}', style: theme.textTheme.bodySmall),
            const SizedBox(height: 20),
            Text('Nuevo monto', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _montoController,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _guardar(),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                ThousandsFormatter(),
              ],
              onChanged: (_) {
                if (_errorMessage != null) setState(() => _errorMessage = null);
              },
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 13)),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _guardar,
                child: _isLoading
                    ? const SizedBox(
                        width: 22, height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                    : const Text('Guardar cambios'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Formulario editar categoría (Nombre) ────────────────────────────────────

class _FormularioEditarCategoriaGasto extends StatefulWidget {
  final AppProvider provider;
  final String categoriaId;
  final String nombreActual;

  const _FormularioEditarCategoriaGasto({
    required this.provider,
    required this.categoriaId,
    required this.nombreActual,
  });

  @override
  State<_FormularioEditarCategoriaGasto> createState() => _FormularioEditarCategoriaGastoState();
}

class _FormularioEditarCategoriaGastoState extends State<_FormularioEditarCategoriaGasto> {
  late TextEditingController _nombreController;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.nombreActual);
  }

  @override
  void dispose() {
    _nombreController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (_nombreController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'El nombre no puede estar vacío.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await widget.provider.firestoreService.editarCategoria(
        categoriaId: widget.categoriaId,
        nuevoNombre: _nombreController.text.trim(),
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _errorMessage = 'Error al editar la categoría.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Editar sobre', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            Text('Nombre', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _nombreController,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _guardar(),
              onChanged: (_) {
                if (_errorMessage != null) setState(() => _errorMessage = null);
              },
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 13)),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _guardar,
                child: _isLoading
                    ? const SizedBox(
                        width: 22, height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                    : const Text('Guardar cambios'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
