import 'package:flutter/material.dart';
import '../widgets/banner_ad_widget.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/app_provider.dart';
import '../utils/app_translator.dart';
import '../utils/currency_formatter.dart';
import '../utils/thousands_formatter.dart';
import '../screens/premium_screen.dart';
import 'package:provider/provider.dart';
import '../services/premium_service.dart';

class CategoriasScreen extends StatefulWidget {
  const CategoriasScreen({super.key});

  @override
  State<CategoriasScreen> createState() => _CategoriasScreenState();
}

class _CategoriasScreenState extends State<CategoriasScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _mostrarFormulario(BuildContext context, String tipoInicial) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FormularioCategoria(tipoInicial: tipoInicial),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final honey = theme.colorScheme.primary;
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
        appBar: AppBar(title: const Text('Categorías')),
        floatingActionButton: FloatingActionButton(
          backgroundColor: honey,
          foregroundColor: theme.colorScheme.onPrimary,
          onPressed: () => _mostrarFormulario(
            context,
            ['ingreso', 'gasto', 'ahorro'][_tabController.index],
          ),
          child: const Icon(Icons.add),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tus sobres',
                      style: theme.textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text('Organizá tu dinero en categorías.',
                        style: theme.textTheme.bodySmall),
                    const SizedBox(height: 16),
                    TabBar(
                      controller: _tabController,
                      labelColor: honey,
                      unselectedLabelColor:
                          theme.colorScheme.onSurface.withOpacity(0.5),
                      indicatorColor: honey,
                      labelStyle: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13),
                      tabs: const [
                        Tab(text: 'Ingresos'),
                        Tab(text: 'Gastos'),
                        Tab(text: 'Ahorros'),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _ListaCategorias(tipo: 'ingreso', currency: provider.currency),
                    _ListaCategorias(tipo: 'gasto', currency: provider.currency),
                    _ListaCategorias(tipo: 'ahorro', currency: provider.currency),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
// ─── Lista de categorías ─────────────────────────────────────────────────────

class _ListaCategorias extends StatefulWidget {
  final String tipo;
  final String currency;

  const _ListaCategorias({required this.tipo, required this.currency});

  @override
  State<_ListaCategorias> createState() => _ListaCategoriasState();
}

class _ListaCategoriasState extends State<_ListaCategorias> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<AppProvider>();
    final theme = Theme.of(context);

    return StreamBuilder<QuerySnapshot>(
      stream: provider.firestoreService.getCategoriasPorTipo(widget.tipo),
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
                Text('Sin categorías aún.', style: theme.textTheme.bodySmall),
                const SizedBox(height: 4),
                Text('Toca + para crear una.', style: theme.textTheme.bodySmall),
              ],
            ),
          );
        }

        final docs = snapshot.data!.docs;
        final tieneMuchas = docs.length > 10;

        // Si hay búsqueda activa, filtrar todos; si no, mostrar últimos 10
        final List<QueryDocumentSnapshot> visibles = _query.isNotEmpty
            ? docs.where((doc) {
                final nombre = (doc.data() as Map<String, dynamic>)['nombre']
                    as String;
                return nombre
                    .toLowerCase()
                    .contains(_query.toLowerCase());
              }).toList()
            : docs.take(10).toList();

        return Column(
          children: [
            // Buscador: solo aparece si hay más de 10
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
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      size: 18,
                      color: theme.colorScheme.onSurface.withOpacity(0.4),
                    ),
                    suffixIcon: _query.isNotEmpty
                        ? GestureDetector(
                            onTap: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                            child: Icon(
                              Icons.close_rounded,
                              size: 16,
                              color: theme.colorScheme.onSurface.withOpacity(0.4),
                            ),
                          )
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),

            // Lista
            Expanded(
              child: visibles.isEmpty
                  ? Center(
                      child: Text(
                        'Sin resultados.',
                        style: theme.textTheme.bodySmall,
                      ),
                    )
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
                        final meta =
                            (data['meta'] as num?)?.toDouble() ?? 0;
                        final esAhorro = widget.tipo == 'ahorro';

                        return _TarjetaCategoria(
                          id: id,
                          nombre: nombre,
                          disponible: disponible,
                          meta: meta,
                          esAhorro: esAhorro,
                          currency: widget.currency,
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

// ─── Tarjeta de categoría ────────────────────────────────────────────────────

class _TarjetaCategoria extends StatelessWidget {
  final String id;
  final String nombre;
  final double disponible;
  final double meta;
  final bool esAhorro;
  final String currency;

  const _TarjetaCategoria({
    required this.id,
    required this.nombre,
    required this.disponible,
    required this.meta,
    required this.esAhorro,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final honey = theme.colorScheme.primary;
    final provider = context.read<AppProvider>();
    final tieneMeta = esAhorro && meta > 0;
    final progreso = tieneMeta ? (disponible / meta).clamp(0.0, 1.0) : 0.0;
    final tieneDinero = disponible != 0;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: theme.colorScheme.outlineVariant.withOpacity(0.4)),
      ),
      child: Padding(
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
                          nombre,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                            fontSize: 11,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        CurrencyFormatter.format(disponible, currency),
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
                GestureDetector(
                  onTap: () => _editarNombre(context, provider, id, nombre),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(
                      Icons.edit_outlined,
                      size: 16,
                      color: theme.colorScheme.onSurface.withOpacity(0.4),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => tieneDinero
                      ? ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text(
                              'No se puede eliminar: la categoría tiene dinero asignado.',
                            ),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        )
                      : _confirmarEliminar(context, provider, id),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(
                      Icons.delete_outline,
                      size: 16,
                      color: Colors.red.withOpacity(0.6),
                    ),
                  ),
                ),
              ],
            ),
            if (tieneMeta) ...[
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Meta: ${CurrencyFormatter.format(meta, currency)}',
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
              if (progreso >= 1.0) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 30,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: honey, width: 1),
                      foregroundColor: honey,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6)),
                      padding: EdgeInsets.zero,
                    ),
                    onPressed: () =>
                        _usarAhorro(context, provider, id, nombre, disponible),
                    child: const Text('Usar ahorro',
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  void _confirmarEliminar(BuildContext context, AppProvider provider, String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar categoría'),
        content: const Text('¿Seguro que querés eliminar esta categoría?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              await provider.firestoreService.eliminarCategoria(id, 0);
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _editarNombre(BuildContext context, AppProvider provider, String id,
      String nombreActual) {
    final controller = TextEditingController(text: nombreActual);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar nombre'),
        content: TextField(
          controller: controller,
          textCapitalization: TextCapitalization.words,
          maxLength: 15,
          decoration: const InputDecoration(hintText: 'Nuevo nombre'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                Navigator.pop(context);
                await provider.firestoreService.editarCategoria(
                  categoriaId: id,
                  nuevoNombre: controller.text.trim(),
                );
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _usarAhorro(BuildContext context, AppProvider provider, String id,
      String nombre, double disponible) {
    showDialog(
      context: context,
      builder: (_) => _DialogoUsarAhorro(
        categoriaId: id,
        categoriaNombre: nombre,
        disponible: disponible,
      ),
    );
  }
}

// ─── Diálogo usar ahorro ─────────────────────────────────────────────────────

class _DialogoUsarAhorro extends StatefulWidget {
  final String categoriaId;
  final String categoriaNombre;
  final double disponible;

  const _DialogoUsarAhorro({
    required this.categoriaId,
    required this.categoriaNombre,
    required this.disponible,
  });

  @override
  State<_DialogoUsarAhorro> createState() => _DialogoUsarAhorroState();
}

class _DialogoUsarAhorroState extends State<_DialogoUsarAhorro> {
  String? _destinoId;
  List<Map<String, dynamic>> _gastosDisponibles = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _cargarGastos();
  }

  Future<void> _cargarGastos() async {
    final provider = context.read<AppProvider>();
    final snapshot = await provider.firestoreService
        .getCategoriasPorTipo('gasto')
        .first;
    setState(() {
      _gastosDisponibles = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {'id': doc.id, 'nombre': data['nombre']};
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.read<AppProvider>();

    return AlertDialog(
      title: const Text('Usar ahorro'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('¿A qué sobre de gasto querés enviar el dinero?',
              style: theme.textTheme.bodySmall),
          const SizedBox(height: 12),
          if (_gastosDisponibles.isEmpty)
            const Text('No tenés categorías de gasto creadas.')
          else
            DropdownButton<String>(
              value: _destinoId,
              isExpanded: true,
              hint: const Text('Seleccioná un sobre'),
              items: _gastosDisponibles
                  .map((g) => DropdownMenuItem(
                        value: g['id'] as String,
                        child: Text(g['nombre'] as String),
                      ))
                  .toList(),
              onChanged: (val) => setState(() => _destinoId = val),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: _destinoId == null || _isLoading
              ? null
              : () async {
                  setState(() => _isLoading = true);
                  final destino = _gastosDisponibles
                      .firstWhere((g) => g['id'] == _destinoId);
                  await provider.firestoreService.repartirDinero(
                    origenId: widget.categoriaId,
                    origenNombre: widget.categoriaNombre,
                    destinoId: _destinoId!,
                    destinoNombre: destino['nombre'] as String,
                    monto: widget.disponible,
                  );
                  if (mounted) Navigator.pop(context);
                },
          child: const Text('Confirmar'),
        ),
      ],
    );
  }
}

// ─── Formulario crear categoría ──────────────────────────────────────────────

class _FormularioCategoria extends StatefulWidget {
  final String tipoInicial;
  const _FormularioCategoria({required this.tipoInicial});

  @override
  State<_FormularioCategoria> createState() => _FormularioCategoriaState();
}

class _FormularioCategoriaState extends State<_FormularioCategoria> {
  final _nombreController = TextEditingController();
  final _metaController = TextEditingController();
  late String _tipo;
  late String _currency;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tipo = widget.tipoInicial;
    _currency = context.read<AppProvider>().currency;
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _metaController.dispose();
    super.dispose();
  }

  Future<void> _crear() async {
    if (_nombreController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'El nombre no puede estar vacío.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final provider = context.read<AppProvider>();
      final premium = context.read<PremiumService>();

      // Verificar límite free
      if (!premium.isPremium) {
        final limites = {'ingreso': 3, 'gasto': 8, 'ahorro': 2};
        final snap = await provider.firestoreService
            .getCategoriasPorTipo(_tipo)
            .first;
        if (snap.docs.length >= limites[_tipo]!) {
          if (mounted) {
            Navigator.pop(context);
            showDialog(
              context: context,
              builder: (_) => const PremiumScreen(),
            );
          }
          return;
        }
      }

      // Validar nombre duplicado
      final existe = await provider.firestoreService
          .getCategoriasPorTipo(_tipo)
          .first
          .then((snap) => snap.docs.any((doc) =>
              (doc.data() as Map<String, dynamic>)['nombre']
                  .toString()
                  .trim()
                  .toLowerCase() ==
              _nombreController.text.trim().toLowerCase()));

      if (existe) {
        setState(() {
          _errorMessage = 'Ya existe una categoría con este nombre.';
          _isLoading = false;
        });
        return;
      }

      final meta = double.tryParse(
            _metaController.text.replaceAll('.', '').replaceAll(',', '.'),
          ) ??
          0;

      await provider.firestoreService.crearCategoria(
        nombre: _nombreController.text,
        tipo: _tipo,
        meta: meta,
      );

      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _errorMessage = 'Error al crear la categoría.');
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
            Text('Nueva categoría',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),

            // Tipo
            Text('Tipo',
                style: theme.textTheme.bodySmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: [
                _ChipTipo(
                    label: 'Ingreso',
                    valor: 'ingreso',
                    seleccionado: _tipo,
                    onTap: () => setState(() => _tipo = 'ingreso')),
                const SizedBox(width: 8),
                _ChipTipo(
                    label: 'Gasto',
                    valor: 'gasto',
                    seleccionado: _tipo,
                    onTap: () => setState(() => _tipo = 'gasto')),
                const SizedBox(width: 8),
                _ChipTipo(
                    label: 'Ahorro',
                    valor: 'ahorro',
                    seleccionado: _tipo,
                    onTap: () => setState(() => _tipo = 'ahorro')),
              ],
            ),

            const SizedBox(height: 20),

            // Nombre
            Text('Nombre',
                style: theme.textTheme.bodySmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _nombreController,
              textCapitalization: TextCapitalization.words,
              textInputAction: _tipo == 'ahorro'
                  ? TextInputAction.next
                  : TextInputAction.done,
              maxLength: 15,
              decoration:
                  const InputDecoration(hintText: 'Ej: Sueldo, Comida, Viaje...'),
              onChanged: (_) {
                if (_errorMessage != null)
                  setState(() => _errorMessage = null);
              },
              onSubmitted: (_) {
                if (_tipo != 'ahorro') _crear();
              },
            ),

            // Meta solo para ahorro
            if (_tipo == 'ahorro') ...[
              const SizedBox(height: 20),
              Text('Meta de ahorro (opcional)',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
                TextField(
                controller: _metaController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  ThousandsFormatter(currencyCode: _currency), // <-- Aquí agregamos tu formateador de miles
                ],
                decoration: const InputDecoration(hintText: 'Ej: 1.000.000'), // Actualicé el hintText para que se vea con el separador
                onSubmitted: (_) => _crear(),
              ),
            ],

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
                onPressed: _isLoading ? null : _crear,
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white))
                    : const Text('Crear categoría'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChipTipo extends StatelessWidget {
  final String label;
  final String valor;
  final String seleccionado;
  final VoidCallback onTap;

  const _ChipTipo({
    required this.label,
    required this.valor,
    required this.seleccionado,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final honey = theme.colorScheme.primary;
    final isSelected = valor == seleccionado;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? honey
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurface.withOpacity(0.7),
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}