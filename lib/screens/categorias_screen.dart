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
        appBar: AppBar(title: Text(context.tr('categories_title'))),
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
                      context.tr('your_envelopes'),
                      style: theme.textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(context.tr('organize_your_money'),
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
                      tabs: [
                        Tab(text: context.tr('incomes')),
                        Tab(text: context.tr('expenses')),
                        Tab(text: context.tr('savingsM')),
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
    final provider = context.watch<AppProvider>();
    final theme = Theme.of(context);

    // Filtramos localmente desde el array sincronizado en el Provider (Cero lecturas a Firebase)
    final docs = provider.todasLasCategorias.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return data['tipo'] == widget.tipo;
    }).toList();

    if (docs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined,
                size: 48,
                color: theme.colorScheme.onSurface.withOpacity(0.3)),
            const SizedBox(height: 12),
            Text(context.tr('no_categories_yet'), style: theme.textTheme.bodySmall),
            const SizedBox(height: 4),
            Text(context.tr('tap_plus_to_create'), style: theme.textTheme.bodySmall),
          ],
        ),
      );
    }

    final tieneMuchas = docs.length > 10;

    // RESPETADO AL 100%: Lógica exacta solicitada para el comportamiento de tu App
    final List<QueryDocumentSnapshot> visibles = _query.isNotEmpty
        ? docs.where((doc) {
            final nombre = (doc.data() as Map<String, dynamic>)['nombre'] as String;
            return nombre.toLowerCase().contains(_query.toLowerCase());
          }).toList()
        : docs.take(10).toList();

    return Column(
      children: [
        // Buscador: solo aparece si hay más de 10 en total
        if (tieneMuchas)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 4),
            child: TextField(
              key: const Key('search_field'),
              controller: _searchController,
              onChanged: (val) => setState(() => _query = val),
              style: theme.textTheme.bodySmall,
              decoration: InputDecoration(
                hintText: context.tr('search_category'),
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
                    context.tr('no_results'),
                    style: theme.textTheme.bodySmall,
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
                  itemCount: visibles.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final data = visibles[i].data() as Map<String, dynamic>;
                    final id = visibles[i].id;
                    final nombre = data['nombre'] as String;
                    final disponible = (data['disponible'] as num).toDouble();
                    final meta = (data['meta'] as num?)?.toDouble() ?? 0;
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
                            content: Text(
                              context.tr('cannot_delete_category_with_money'),
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
                    '${context.tr('goal')}: ${CurrencyFormatter.format(meta, currency)}',
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
                    child: Text(context.tr('use_savings'),
                        style: const TextStyle(
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
        title: Text(context.tr('delete_category')),
        content: Text(context.tr('confirm_delete_category')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr('cancel')),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              await provider.firestoreService.eliminarCategoria(id, 0);
            },
            child: Text(context.tr('delete')),
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
        title: Text(context.tr('edit_name')),
        content: TextField(
          controller: controller,
          textCapitalization: TextCapitalization.words,
          maxLength: 15,
          decoration: InputDecoration(hintText: context.tr('new_name')),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr('cancel')),
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
            child: Text(context.tr('save')),
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

  void _cargarGastos() {
    final provider = context.read<AppProvider>();
    // Optimización: Carga directa sincrónica de memoria de los gastos locales
    final gastos = provider.todasLasCategorias.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return data['tipo'] == 'gasto';
    }).toList();

    setState(() {
      _gastosDisponibles = gastos.map((doc) {
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
      title: Text(context.tr('use_savings')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.tr('where_to_send_savings'),
              style: theme.textTheme.bodySmall),
          const SizedBox(height: 12),
          if (_gastosDisponibles.isEmpty)
            Text(context.tr('no_expense_categories'))
          else
            DropdownButton<String>(
              value: _destinoId,
              isExpanded: true,
              hint: Text(context.tr('select_envelope')),
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
          child: Text(context.tr('cancel')),
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
          child: Text(context.tr('confirm')),
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
      setState(() => _errorMessage = context.tr('name_cannot_be_empty'));
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final provider = context.read<AppProvider>();
      final premium = context.read<PremiumService>();

      // Filtramos localmente de la memoria para validar límites y duplicados (Cero lecturas extra)
      final categoriasLocales = provider.todasLasCategorias.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return data['tipo'] == _tipo;
      }).toList();

      // Verificar límite free localmente
      if (!premium.isPremium) {
        final limites = {'ingreso': 3, 'gasto': 8, 'ahorro': 2};
        if (categoriasLocales.length >= limites[_tipo]!) {
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

      // Validar nombre duplicado localmente
      final existe = categoriasLocales.any((doc) =>
          (doc.data() as Map<String, dynamic>)['nombre']
              .toString()
              .trim()
              .toLowerCase() ==
          _nombreController.text.trim().toLowerCase());

      if (existe) {
        setState(() {
          _errorMessage = context.tr('category_already_exists');
          _isLoading = false;
        });
        return;
      }

      final meta = CurrencyFormatter.parseAmount(
            _metaController.text, _currency,
          ) ??
          0;

      await provider.firestoreService.crearCategoria(
        nombre: _nombreController.text,
        tipo: _tipo,
        meta: meta,
      );

      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _errorMessage = context.tr('error_creating_category'));
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
            Text(context.tr('new_category'),
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 20),

            // Tipo
            Text(context.tr('type'),
                style: theme.textTheme.bodySmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: [
                _ChipTipo(
                    label: context.tr('income'),
                    valor: 'ingreso',
                    seleccionado: _tipo,
                    onTap: () => setState(() => _tipo = 'ingreso')),
                const SizedBox(width: 8),
                _ChipTipo(
                    label: context.tr('expense'),
                    valor: 'gasto',
                    seleccionado: _tipo,
                    onTap: () => setState(() => _tipo = 'gasto')),
                const SizedBox(width: 8),
                _ChipTipo(
                    label: context.tr('saving'),
                    valor: 'ahorro',
                    seleccionado: _tipo,
                    onTap: () => setState(() => _tipo = 'ahorro')),
              ],
            ),

            const SizedBox(height: 20),

            // Nombre
            Text(context.tr('name'),
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
                  InputDecoration(hintText: context.tr('example_category_name')),
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
              Text(context.tr('savings_goal_optional'),
                  style: theme.textTheme.bodySmall
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                controller: _metaController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  ThousandsFormatter(currencyCode: _currency),
                ],
                decoration: InputDecoration(hintText: context.tr('example_amount')),
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
                    : Text(context.tr('create_category')),
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
