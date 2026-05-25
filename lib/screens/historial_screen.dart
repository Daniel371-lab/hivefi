import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/app_translator.dart';
import '../utils/currency_formatter.dart';

class HistorialScreen extends StatefulWidget {
  const HistorialScreen({super.key});

  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _mesSeleccionado = 'TODOS';
  String _anioSeleccionado = '2026';

  final List<String> _meses = ['TODOS', 'ENERO', 'FEBRERO', 'MARZO', 'ABRIL', 'MAYO', 'JUNIO', 'JULIO', 'AGOSTO', 'SEPTIEMBRE', 'OCTUBRE', 'NOVIEMBRE', 'DICIEMBRE'];
  final List<String> _anios = ['2024', '2025', '2026'];

  final List<Map<String, dynamic>> _movimientos = [
    {'descripcion': 'Gasto en COMIDA', 'monto': -30000.0, 'fecha': '27/02/2026', 'tipo': 'gasto'},
    {'descripcion': 'Gasto en COMIDA', 'monto': -10000.0, 'fecha': '13/02/2026', 'tipo': 'gasto'},
    {'descripcion': 'Traspaso: SUELDO → TRANSPORTE', 'monto': -150000.0, 'fecha': '13/02/2026', 'tipo': 'traspaso'},
    {'descripcion': 'Traspaso: SUELDO → COMIDA', 'monto': -250000.0, 'fecha': '13/02/2026', 'tipo': 'traspaso'},
    {'descripcion': 'Carga a SUELDO', 'monto': 1300000.0, 'fecha': '13/02/2026', 'tipo': 'ingreso'},
  ];

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

  List<Map<String, dynamic>> get _filtrados => _movimientos;
  List<Map<String, dynamic>> get _soloIngresos => _filtrados.where((m) => m['tipo'] == 'ingreso').toList();
  List<Map<String, dynamic>> get _soloGastos => _filtrados.where((m) => m['tipo'] != 'ingreso').toList();
  double get _saldoTotal => _filtrados.fold(0, (sum, m) => sum + (m['monto'] as double));

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final theme = Theme.of(context);
    final honey = theme.colorScheme.primary;
    final currency = provider.currency;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: theme.brightness == Brightness.dark
          ? SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent, systemNavigationBarColor: Colors.transparent)
          : SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent, systemNavigationBarColor: Colors.transparent),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.tr('historialTitle'), style: theme.textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w700, height: 1.1)),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(context.tr('filterByMonth'), style: theme.textTheme.bodySmall?.copyWith(color: honey, fontWeight: FontWeight.w700, letterSpacing: 1, fontSize: 10)),
                              const SizedBox(height: 4),
                              _DropdownFiltro(valor: _mesSeleccionado, opciones: _meses, onChanged: (val) => setState(() => _mesSeleccionado = val!)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(context.tr('year'), style: theme.textTheme.bodySmall?.copyWith(color: honey, fontWeight: FontWeight.w700, letterSpacing: 1, fontSize: 10)),
                              const SizedBox(height: 4),
                              _DropdownFiltro(valor: _anioSeleccionado, opciones: _anios, onChanged: (val) => setState(() => _anioSeleccionado = val!)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TabBar(
                      controller: _tabController,
                      labelColor: honey,
                      unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.5),
                      indicatorColor: honey,
                      labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: 1),
                      tabs: [
                        Tab(text: context.tr('tabSummary')),
                        Tab(text: context.tr('tabIncome')),
                        Tab(text: context.tr('tabExpenses')),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(12)),
                      child: Text('${context.tr('balance')}: ${CurrencyFormatter.format(_saldoTotal, currency)}', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(height: 8),
                    Text(context.tr('longPressHint'), style: theme.textTheme.bodySmall?.copyWith(fontSize: 11)),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _ListaMovimientos(movimientos: _filtrados, currency: currency),
                    _ListaMovimientos(movimientos: _soloIngresos, currency: currency),
                    _ListaMovimientos(movimientos: _soloGastos, currency: currency),
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

class _DropdownFiltro extends StatelessWidget {
  final String valor;
  final List<String> opciones;
  final ValueChanged<String?> onChanged;

  const _DropdownFiltro({required this.valor, required this.opciones, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: theme.inputDecorationTheme.fillColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.brightness == Brightness.dark ? const Color(0xFF424242) : const Color(0xFFD7CCC8)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: valor,
          isExpanded: true,
          isDense: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
          items: opciones.map((o) => DropdownMenuItem(value: o, child: Text(o, style: theme.textTheme.bodySmall))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _ListaMovimientos extends StatelessWidget {
  final List<Map<String, dynamic>> movimientos;
  final String currency;

  const _ListaMovimientos({required this.movimientos, required this.currency});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (movimientos.isEmpty) {
      return Center(child: Text(context.tr('noMovements'), style: theme.textTheme.bodySmall));
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      itemCount: movimientos.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final m = movimientos[i];
        final monto = m['monto'] as double;
        final esPositivo = monto >= 0;

        return GestureDetector(
          onLongPress: () => _mostrarOpciones(context, m),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${esPositivo ? '+' : ''}${CurrencyFormatter.format(monto, currency)}', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: esPositivo ? Colors.green : Colors.red)),
                        const SizedBox(height: 2),
                        Text(m['descripcion'] as String, style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                  Text(m['fecha'] as String, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _mostrarOpciones(BuildContext context, Map<String, dynamic> movimiento) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.4), borderRadius: BorderRadius.circular(2))),
            ListTile(leading: const Icon(Icons.edit_outlined), title: Text(context.tr('editMovement')), onTap: () => Navigator.pop(context)),
            ListTile(leading: const Icon(Icons.delete_outline, color: Colors.red), title: Text(context.tr('cancelMovement'), style: const TextStyle(color: Colors.red)), onTap: () => Navigator.pop(context)),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}