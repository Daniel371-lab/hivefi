import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/app_provider.dart';
import '../utils/currency_formatter.dart';

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
        appBar: AppBar(
          title: const Text('Ingresos'),
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          onPressed: () => _mostrarFormulario(context, provider),
          child: const Icon(Icons.add),
        ),
        body: SafeArea(
          child: StreamBuilder<QuerySnapshot>(
            stream: provider.firestoreService.getCategoriasPorTipo('ingreso'),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inbox_outlined,
                        size: 48,
                        color: theme.colorScheme.onSurface.withOpacity(0.3),
                      ),
                      const SizedBox(height: 12),
                      Text('Sin categorías de ingreso.', style: theme.textTheme.bodySmall),
                      const SizedBox(height: 4),
                      Text('Creá una en Categorías primero.', style: theme.textTheme.bodySmall),
                    ],
                  ),
                );
              }

              final docs = snapshot.data!.docs;

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
                itemCount: docs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final data = docs[i].data() as Map<String, dynamic>;
                  final id = docs[i].id;
                  final nombre = data['nombre'] as String;
                  final disponible = (data['disponible'] as num).toDouble();

                  // Convertimos el disponible numérico a texto formateado para que rellene el input de edición
                  final disponibleString = CurrencyFormatter.format(disponible, provider.currency)
                      .replaceAll(RegExp(r'[^0-9.]'), '');

                  return _TarjetaIngreso(
                    id: id,
                    nombre: nombre,
                    disponible: disponible,
                    currency: provider.currency,
                    onAgregar: () => _mostrarFormularioConCategoria(
                      context, provider, id, nombre, disponible,
                    ),
                    onEditar: () => _mostrarEditar(
                      context, provider, id, disponibleString,
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

  void _mostrarFormulario(BuildContext context, AppProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FormularioIngreso(provider: provider),
    );
  }

  void _mostrarFormularioConCategoria(
    BuildContext context,
    AppProvider provider,
    String id,
    String nombre,
    double disponible,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FormularioIngreso(
        provider: provider,
        categoriaId: id,
        categoriaNombre: nombre,
        disponible: disponible,
      ),
    );
  }

  void _mostrarEditar(
    BuildContext context,
    AppProvider provider,
    String id,
    String nombreActual,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FormularioEditarCategoria(
        provider: provider,
        categoriaId: id,
        nombreActual: nombreActual,
      ),
    );
  }
}

// ─── Tarjeta de ingreso ──────────────────────────────────────────────────────
class _TarjetaIngreso extends StatefulWidget {
  final String id;
  final String nombre;
  final double disponible;
  final String currency;
  final VoidCallback onAgregar;
  final VoidCallback onEditar;

  const _TarjetaIngreso({
    required this.id,
    required this.nombre,
    required this.disponible,
    required this.currency,
    required this.onAgregar,
    required this.onEditar,
  });

  @override
  State<_TarjetaIngreso> createState() => _TarjetaIngresoState();
}

class _TarjetaIngresoState extends State<_TarjetaIngreso> {
  bool _tieneMovimientos = false;
  bool _chequeado = false;

  @override
  void initState() {
    super.initState();
    _verificarMovimientos();
  }

  Future<void> _verificarMovimientos() async {
    final provider = context.read<AppProvider>();
    final tiene = await provider.firestoreService
        .categoriaIngresaTieneMovimientos(widget.id);
    if (mounted) setState(() {
      _tieneMovimientos = tiene;
      _chequeado = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final honey = theme.colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.nombre,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        CurrencyFormatter.format(widget.disponible, widget.currency),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: honey,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_chequeado)
                  IconButton(
                    icon: Icon(
                      _tieneMovimientos
                          ? Icons.edit_off_outlined
                          : Icons.edit_outlined,
                      size: 18,
                    ),
                    color: _tieneMovimientos
                        ? theme.colorScheme.onSurface.withOpacity(0.25)
                        : theme.colorScheme.onSurface.withOpacity(0.5),
                    onPressed: _tieneMovimientos
                        ? () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text(
                                  'No se puede editar: esta cuenta ya tiene movimientos registrados.',
                                ),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            );
                          }
                        : widget.onEditar,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    splashRadius: 20,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 36,
              child: ElevatedButton.icon(
                onPressed: widget.onAgregar,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Agregar ingreso', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  elevation: 0,
                  backgroundColor: honey.withOpacity(0.08),
                  foregroundColor: honey,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Formulario agregar ingreso ──────────────────────────────────────────────

class _FormularioIngreso extends StatefulWidget {
  final AppProvider provider;
  final String? categoriaId;
  final String? categoriaNombre;
  final double? disponible;

  const _FormularioIngreso({
    required this.provider,
    this.categoriaId,
    this.categoriaNombre,
    this.disponible,
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
          'disponible': (data['disponible'] as num).toDouble(),
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

    final monto = double.tryParse(
      _montoController.text.replaceAll('.', '').replaceAll(',', '.'),
    );

    if (monto == null || monto <= 0) {
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
            Text(
              'Registrar ingreso',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 20),

            Text('¿A qué cuenta entra el dinero?',
                style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _categorias.isEmpty
                ? const Text('Cargando categorías...')
                : DropdownButtonFormField<String>(
                    value: _categoriaSeleccionada,
                    hint: const Text('Seleccioná una categoría'),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: theme.colorScheme.surfaceContainerHighest),
                      ),
                    ),
                    items: _categorias.map((c) => DropdownMenuItem(
                      value: c['id'] as String,
                      child: Text(c['nombre'] as String),
                    )).toList(),
                    onChanged: (val) {
                      setState(() {
                        _categoriaSeleccionada = val;
                        _categoriaNombreSeleccionada = _categorias
                            .firstWhere((c) => c['id'] == val)['nombre'] as String;
                      });
                    },
                  ),

            const SizedBox(height: 20),

            Text('Monto del ingreso',
                style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
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
                hintText: CurrencyFormatter.format(0, widget.provider.currency),
              ),
              onChanged: (val) {
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
                onPressed: _isLoading ? null : _confirmar,
                child: _isLoading
                    ? const SizedBox(width: 22, height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                    : const Text('Confirmar ingreso'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Formulario editar categoría ─────────────────────────────────────────────

class _FormularioEditarCategoria extends StatefulWidget {
  final AppProvider provider;
  final String categoriaId;
  final String nombreActual;

  const _FormularioEditarCategoria({
    required this.provider,
    required this.categoriaId,
    required this.nombreActual,
  });

  @override
  State<_FormularioEditarCategoria> createState() => _FormularioEditarCategoriaState();
}

class _FormularioEditarCategoriaState extends State<_FormularioEditarCategoria> {
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
      setState(() => _errorMessage = 'El monto no puede estar vacío.');
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
            Text('Monto de ingreso',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),
            Text('Monto disponible', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _nombreController,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              inputFormatters: [
                ThousandsFormatter(currencyCode: widget.provider.currency),
              ],
              onSubmitted: (_) => _guardar(),
              onChanged: (val) {
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
                    ? const SizedBox(width: 22, height: 22,
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
