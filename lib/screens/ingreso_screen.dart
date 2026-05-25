import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/app_translator.dart';
import '../utils/currency_formatter.dart';

class IngresoScreen extends StatefulWidget {
  const IngresoScreen({super.key});

  @override
  State<IngresoScreen> createState() => _IngresoScreenState();
}

class _IngresoScreenState extends State<IngresoScreen> {
  final _montoController = TextEditingController();
  String? _categoriaSeleccionada;
  bool _isLoading = false;
  String? _errorMessage;

  final List<Map<String, dynamic>> _categorias = [
    {'id': '1', 'nombre': 'SUELDO'},
    {'id': '2', 'nombre': 'FREELANCE'},
    {'id': '3', 'nombre': 'OTROS'},
  ];

  final List<Map<String, dynamic>> _historialReciente = [
    {'descripcion': 'Carga a SUELDO', 'monto': 1300000.0},
    {'descripcion': 'Carga a FREELANCE', 'monto': 500000.0},
  ];

  @override
  void initState() {
    super.initState();
    if (_categorias.isNotEmpty) _categoriaSeleccionada = _categorias.first['id'];
  }

  @override
  void dispose() {
    _montoController.dispose();
    super.dispose();
  }

  double get _disponible => 900000;

  Future<void> _confirmarIngreso() async {
    if (_montoController.text.trim().isEmpty) { setState(() => _errorMessage = context.tr('emptyAmount')); return; }
    final monto = double.tryParse(_montoController.text.replaceAll('.', '').replaceAll(',', '.'));
    if (monto == null || monto <= 0) { setState(() => _errorMessage = context.tr('invalidAmount')); return; }
    setState(() { _isLoading = true; _errorMessage = null; });
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() => _isLoading = false);
    _montoController.clear();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr('incomeRegistered')), backgroundColor: Theme.of(context).colorScheme.primary, behavior: SnackBarBehavior.floating));
  }

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
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          if (_montoController.text.trim().isNotEmpty) {
            showDialog(context: context, builder: (_) => AlertDialog(
              title: Text(context.tr('exitWithoutSaving')),
              content: Text(context.tr('unsavedAmount')),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: Text(context.tr('cancel'))),
                TextButton(onPressed: () { Navigator.pop(context); Navigator.pop(context); }, child: Text(context.tr('confirm'))),
              ],
            ));
          } else { Navigator.pop(context); }
        },
        child: Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.tr('registerIncome'), style: theme.textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w700, height: 1.1)),
                  const SizedBox(height: 32),
                  Text(context.tr('whereMoneyEnters'), style: theme.textTheme.bodySmall?.copyWith(color: honey, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
                  const SizedBox(height: 8),
                  _DropdownCategorias(categorias: _categorias, seleccionada: _categoriaSeleccionada, onChanged: (val) => setState(() => _categoriaSeleccionada = val)),
                  const SizedBox(height: 6),
                  Align(alignment: Alignment.centerRight, child: Text('${context.tr('available')}: ${CurrencyFormatter.format(_disponible, currency)}', style: TextStyle(color: honey, fontWeight: FontWeight.w600, fontSize: 13))),
                  const SizedBox(height: 24),
                  Text(context.tr('incomeAmount'), style: theme.textTheme.bodySmall?.copyWith(color: honey, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _montoController,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _confirmarIngreso(),
                    decoration: InputDecoration(hintText: CurrencyFormatter.format(0, currency)),
                    onChanged: (_) { if (_errorMessage != null) setState(() => _errorMessage = null); },
                  ),
                  if (_errorMessage != null) ...[const SizedBox(height: 8), Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 13))],
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity, height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _confirmarIngreso,
                      child: _isLoading
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                          : Text(context.tr('confirmIncome'), style: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1)),
                    ),
                  ),
                  const SizedBox(height: 32),
                  _HistorialReciente(historial: _historialReciente, currency: currency),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DropdownCategorias extends StatelessWidget {
  final List<Map<String, dynamic>> categorias;
  final String? seleccionada;
  final ValueChanged<String?> onChanged;

  const _DropdownCategorias({required this.categorias, required this.seleccionada, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: theme.inputDecorationTheme.fillColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.brightness == Brightness.dark ? const Color(0xFF424242) : const Color(0xFFD7CCC8)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: seleccionada,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          items: categorias.map((c) => DropdownMenuItem(value: c['id'] as String, child: Text(c['nombre'] as String, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _HistorialReciente extends StatelessWidget {
  final List<Map<String, dynamic>> historial;
  final String currency;

  const _HistorialReciente({required this.historial, required this.currency});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final honey = theme.colorScheme.primary;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.tr('recentHistory'), style: theme.textTheme.bodySmall?.copyWith(color: honey, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
          const SizedBox(height: 12),
          ...historial.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text('${item['descripcion']} (+${CurrencyFormatter.format(item['monto'] as double, currency)})', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
          )),
        ],
      ),
    );
  }
}