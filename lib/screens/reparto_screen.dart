import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/app_translator.dart';
import '../utils/currency_formatter.dart';

class RepartoScreen extends StatefulWidget {
  const RepartoScreen({super.key});

  @override
  State<RepartoScreen> createState() => _RepartoScreenState();
}

class _RepartoScreenState extends State<RepartoScreen> {
  final _montoController = TextEditingController();
  String? _cuentaOrigenId;
  String? _cuentaDestinoId;
  bool _isLoading = false;
  String? _errorMessage;

  final List<Map<String, dynamic>> _sobres = [
    {'id': '1', 'nombre': 'COMIDA', 'disponible': 210000.0},
    {'id': '2', 'nombre': 'OCIO', 'disponible': 100000.0},
    {'id': '3', 'nombre': 'TRANSPORTE', 'disponible': 150000.0},
    {'id': '4', 'nombre': 'VIAJE', 'disponible': 50000.0},
  ];

  @override
  void initState() {
    super.initState();
    _cuentaOrigenId = _sobres.first['id'];
    _cuentaDestinoId = _sobres[1]['id'];
  }

  @override
  void dispose() {
    _montoController.dispose();
    super.dispose();
  }

  double get _disponibleOrigen {
    final sobre = _sobres.firstWhere((s) => s['id'] == _cuentaOrigenId, orElse: () => _sobres.first);
    return sobre['disponible'] as double;
  }

  Future<void> _confirmarReparto() async {
    if (_cuentaOrigenId == _cuentaDestinoId) { setState(() => _errorMessage = context.tr('sameAccountError')); return; }
    if (_montoController.text.trim().isEmpty) { setState(() => _errorMessage = context.tr('emptyAmount')); return; }
    final monto = double.tryParse(_montoController.text.replaceAll('.', '').replaceAll(',', '.'));
    if (monto == null || monto <= 0) { setState(() => _errorMessage = context.tr('invalidAmount')); return; }
    if (monto > _disponibleOrigen) { setState(() => _errorMessage = context.tr('notEnoughInEnvelope')); return; }
    setState(() { _isLoading = true; _errorMessage = null; });
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() => _isLoading = false);
    _montoController.clear();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr('splitRegistered')), backgroundColor: Theme.of(context).colorScheme.primary, behavior: SnackBarBehavior.floating));
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
                  Text(context.tr('splitTitle'), style: theme.textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w700, height: 1.1)),
                  const SizedBox(height: 6),
                  Text(context.tr('splitSubtitle'), style: theme.textTheme.bodySmall),
                  const SizedBox(height: 32),
                  _StepLabel(numero: '1', texto: context.tr('splitFrom')),
                  const SizedBox(height: 8),
                  _DropdownSobres(sobres: _sobres, seleccionada: _cuentaOrigenId, onChanged: (val) => setState(() => _cuentaOrigenId = val)),
                  const SizedBox(height: 6),
                  Align(alignment: Alignment.centerRight, child: Text('${context.tr('available')}: ${CurrencyFormatter.format(_disponibleOrigen, currency)}', style: TextStyle(color: honey, fontWeight: FontWeight.w600, fontSize: 13))),
                  const SizedBox(height: 24),
                  _StepLabel(numero: '2', texto: context.tr('splitTo')),
                  const SizedBox(height: 8),
                  _DropdownSobres(sobres: _sobres, seleccionada: _cuentaDestinoId, onChanged: (val) => setState(() => _cuentaDestinoId = val)),
                  const SizedBox(height: 24),
                  _StepLabel(numero: '3', texto: context.tr('amountToSplit')),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _montoController,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _confirmarReparto(),
                    decoration: InputDecoration(hintText: CurrencyFormatter.format(0, currency)),
                    onChanged: (_) { if (_errorMessage != null) setState(() => _errorMessage = null); },
                  ),
                  if (_errorMessage != null) ...[const SizedBox(height: 8), Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 13))],
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity, height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _confirmarReparto,
                      child: _isLoading
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                          : Text(context.tr('confirmSplit'), style: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1)),
                    ),
                  ),
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

class _StepLabel extends StatelessWidget {
  final String numero;
  final String texto;
  const _StepLabel({required this.numero, required this.texto});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final honey = theme.colorScheme.primary;
    return Row(
      children: [
        Container(
          width: 22, height: 22,
          decoration: BoxDecoration(color: honey, shape: BoxShape.circle),
          child: Center(child: Text(numero, style: TextStyle(color: theme.colorScheme.onPrimary, fontWeight: FontWeight.w700, fontSize: 12))),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(texto, style: theme.textTheme.bodySmall?.copyWith(color: honey, fontWeight: FontWeight.w700, letterSpacing: 1.2))),
      ],
    );
  }
}

class _DropdownSobres extends StatelessWidget {
  final List<Map<String, dynamic>> sobres;
  final String? seleccionada;
  final ValueChanged<String?> onChanged;

  const _DropdownSobres({required this.sobres, required this.seleccionada, required this.onChanged});

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
          items: sobres.map((s) => DropdownMenuItem(value: s['id'] as String, child: Text(s['nombre'] as String, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}