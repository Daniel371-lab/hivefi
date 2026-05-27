import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/app_provider.dart';
import '../utils/currency_formatter.dart';
import '../utils/thousands_formatter.dart';

class RepartoScreen extends StatelessWidget {
  const RepartoScreen({super.key});

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
          onPressed: () => _mostrarFormulario(context, provider, origenInicial, null),
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
                            Icon(
                              Icons.compare_arrows_rounded,
                              size: 48,
                              color: theme.colorScheme.onSurface.withOpacity(0.3),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Sin sobres creados',
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Creá categorías de gasto o ahorro primero.',
                              style: theme.textTheme.bodySmall,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (origenInicial != null) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _mostrarFormulario(context, provider, origenInicial, null);
                    });
                  }

                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mover dinero entre sobres',
                          style: theme.textTheme.headlineMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Reasigná dinero entre tus sobres de gasto y ahorro.',
                          style: theme.textTheme.bodySmall,
                        ),
                        const SizedBox(height: 24),

                        if (gastos.isNotEmpty) ...[
                          _SeccionSobres(
                            titulo: 'Sobres de gasto',
                            docs: gastos,
                            tipo: 'gasto',
                            currency: provider.currency,
                            onRepartir: (id, nombre, disponible) =>
                                _mostrarFormulario(
                              context,
                              provider,
                              _SobreInfo(
                                id: id,
                                nombre: nombre,
                                disponible: disponible,
                                tipo: 'gasto',
                              ),
                              null,
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],

                        if (ahorros.isNotEmpty)
                          _SeccionSobres(
                            titulo: 'Sobres de ahorro',
                            docs: ahorros,
                            tipo: 'ahorro',
                            currency: provider.currency,
                            onRepartir: (id, nombre, disponible) =>
                                _mostrarFormulario(
                              context,
                              provider,
                              _SobreInfo(
                                id: id,
                                nombre: nombre,
                                disponible: disponible,
                                tipo: 'ahorro',
                              ),
                              null,
                            ),
                          ),
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
    _SobreInfo? destino,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FormularioReparto(
        provider: provider,
        origenPreseleccionado: origen,
        destinoPreseleccionado: destino,
      ),
    );
  }
}

// ─── Sección sobres ──────────────────────────────────────────────────────────

class _SeccionSobres extends StatelessWidget {
  final String titulo;
  final List<QueryDocumentSnapshot> docs;
  final String tipo;
  final String currency;
  final Function(String, String, double) onRepartir;

  const _SeccionSobres({
    required this.titulo,
    required this.docs,
    required this.tipo,
    required this.currency,
    required this.onRepartir,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final honey = theme.colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        ...docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final nombre = data['nombre'] as String;
          final disponible = (data['disponible'] as num).toDouble();
          final meta = (data['meta'] as num?)?.toDouble() ?? 0;
          final metaAlcanzada = meta > 0 && disponible >= meta;

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
                        Row(
                          children: [
                            Text(
                              nombre,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (tipo == 'ahorro') ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: metaAlcanzada
                                      ? Colors.green.withOpacity(0.15)
                                      : honey.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  metaAlcanzada ? 'Meta alcanzada' : 'En progreso',
                                  style: TextStyle(
                                    color: metaAlcanzada ? Colors.green : honey,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          CurrencyFormatter.format(disponible, currency),
                          style: TextStyle(
                            color: disponible > 0
                                ? honey
                                : theme.colorScheme.onSurface.withOpacity(0.4),
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        if (tipo == 'ahorro' && meta > 0) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Meta: ${CurrencyFormatter.format(meta, currency)}',
                            style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: (disponible / meta).clamp(0.0, 1.0),
                              minHeight: 4,
                              backgroundColor:
                                  theme.colorScheme.surfaceContainerHighest,
                              color: metaAlcanzada ? Colors.green : honey,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: disponible > 0
                        ? () => onRepartir(doc.id, nombre, disponible)
                        : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      backgroundColor: disponible > 0
                          ? honey
                          : theme.colorScheme.surfaceContainerHighest,
                      foregroundColor: disponible > 0
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurface.withOpacity(0.4),
                      elevation: 0,
                    ),
                    child: const Text('Mover'),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

// ─── Formulario reparto ──────────────────────────────────────────────────────

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
      setState(
          () => _errorMessage = 'El origen y destino no pueden ser iguales.');
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
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(24)),
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
              Text(
                'Mover dinero',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                'Reasigná dinero entre tus sobres.',
                style: theme.textTheme.bodySmall,
              ),
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
                    final sobre =
                        _sobres.firstWhere((s) => s['id'] == val);
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
                    _destinoNombre = _sobres
                        .firstWhere((s) => s['id'] == val)['nombre']
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
                  FilteringTextInputFormatter.digitsOnly,
                  ThousandsFormatter(),
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