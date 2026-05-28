import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/app_provider.dart';
import '../utils/currency_formatter.dart';
import '../utils/thousands_formatter.dart'; // Tu formateador oficial de miles

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

              final ingresosConDinero = snapshotIngresos.data?.docs
                      .where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return (data['disponible'] as num).toDouble() > 0;
                      })
                      .toList() ??
                  [];

              if (ingresosConDinero.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.account_balance_wallet_outlined,
                          size: 48,
                          color: theme.colorScheme.onSurface.withOpacity(0.3),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Sin dinero disponible',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
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
  crossAxisAlignment: CrossAxisAlignment.start, // <─── Con el parámetro bien nombrado
  children: [
                    Text(
                      'Distribuí tu dinero',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Asigná tu dinero a sobres de gasto o ahorro.',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),

                    // Resumen de ingresos disponibles
                    ...ingresosConDinero.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final nombre = data['nombre'] as String;
                      final disponible =
                          (data['disponible'] as num).toDouble();
                      return _ChipIngreso(
                        nombre: nombre,
                        disponible: disponible,
                        currency: provider.currency,
                      );
                    }),

                    const SizedBox(height: 24),

                    // Sección gastos
                    _SeccionDestino(
                      titulo: 'Sobres de gasto',
                      subtitulo: 'Asigná dinero para tus gastos del día a día.',
                      tipo: 'gasto',
                      provider: provider,
                      ingresosDisponibles: ingresosConDinero,
                    ),

                    const SizedBox(height: 24),

                    // Sección ahorros
                    _SeccionDestino(
                      titulo: 'Sobres de ahorro',
                      subtitulo: 'Asigná dinero a tus metas de ahorro.',
                      tipo: 'ahorro',
                      provider: provider,
                      ingresosDisponibles: ingresosConDinero,
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

// ─── Chip resumen ingreso ────────────────────────────────────────────────────

class _ChipIngreso extends StatelessWidget {
  final String nombre;
  final double disponible;
  final String currency;

  const _ChipIngreso({
    required this.nombre,
    required this.disponible,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final honey = theme.colorScheme.primary;

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: honey.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: honey.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            nombre,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            CurrencyFormatter.format(disponible, currency),
            style: TextStyle(
              color: honey,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Sección destino ─────────────────────────────────────────────────────────

class _SeccionDestino extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final String tipo;
  final AppProvider provider;
  final List<QueryDocumentSnapshot> ingresosDisponibles;

  const _SeccionDestino({
    required this.titulo,
    required this.subtitulo,
    required this.tipo,
    required this.provider,
    required this.ingresosDisponibles,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final honey = theme.colorScheme.primary;

    return StreamBuilder<QuerySnapshot>(
      stream: provider.firestoreService.getCategoriasPorTipo(tipo),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox();
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) return const SizedBox();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titulo,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(subtitulo, style: theme.textTheme.bodySmall),
            const SizedBox(height: 12),
            ...docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final nombre = data['nombre'] as String;
              final disponible = (data['disponible'] as num).toDouble();
              final meta = (data['meta'] as num?)?.toDouble() ?? 0;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant.withOpacity(0.4),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nombre,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (tipo == 'ahorro' && meta > 0) ...[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Meta: ${CurrencyFormatter.format(meta, provider.currency)}',
                                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                                  ),
                                  Text(
                                    '${((disponible / meta) * 100).toStringAsFixed(0)}%',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: honey,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: (disponible / meta).clamp(0.0, 1.0),
                                  minHeight: 4,
                                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                                  valueColor: AlwaysStoppedAnimation<Color>(honey),
                                ),
                              ),
                            ] else ...[
                              Text(
                                'Fondo acumulado',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        CurrencyFormatter.format(disponible, provider.currency),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: honey,
                        ),
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
}

// ─── Formulario destinar ─────────────────────────────────────────────────────

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
    // Corregido: Cambio de 'ingresos' a 'ingreso' para coincidir con tu BD
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
          return {
            'id': doc.id,
            'nombre': data['nombre'],
            'tipo': 'gasto',
          };
        }),
        ...snapshotAhorros.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'id': doc.id,
            'nombre': data['nombre'],
            'tipo': 'ahorro',
          };
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

    final monto = double.tryParse(
      _montoController.text.replaceAll('.', '').replaceAll(',', '.'),
    );

    if (monto == null || monto <= 0) {
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
            Text(
              'Destinar dinero',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 20),

            // Origen
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
                            color:
                                theme.colorScheme.surfaceContainerHighest),
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

            // Destino
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
                            color:
                                theme.colorScheme.surfaceContainerHighest),
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
                                      borderRadius:
                                          BorderRadius.circular(6),
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

            // Monto
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
                FilteringTextInputFormatter.digitsOnly,
                ThousandsFormatter(currencyCode: provider.currency), // Formateador en tiempo real incorporado
              ],
              decoration: InputDecoration(
                hintText:
                    CurrencyFormatter.format(0, widget.provider.currency),
              ),
              onChanged: (_) {
                if (_errorMessage != null) {
                  setState(() => _errorMessage = null);
                }
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
