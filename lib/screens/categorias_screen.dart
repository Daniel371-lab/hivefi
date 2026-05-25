import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/app_translator.dart';

class CategoriasScreen extends StatefulWidget {
  const CategoriasScreen({super.key});

  @override
  State<CategoriasScreen> createState() => _CategoriasScreenState();
}

class _CategoriasScreenState extends State<CategoriasScreen> {
  final _nombreController = TextEditingController();
  String _tipoSeleccionado = 'gasto';
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nombreController.dispose();
    super.dispose();
  }

  Future<void> _crearCategoria() async {
    if (_nombreController.text.trim().isEmpty) {
      setState(() => _errorMessage = context.tr('categoryEmptyError'));
      return;
    }
    setState(() { _isLoading = true; _errorMessage = null; });
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() => _isLoading = false);
    _nombreController.clear();
    setState(() => _tipoSeleccionado = 'gasto');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(context.tr('categoryCreated')),
      backgroundColor: Theme.of(context).colorScheme.primary,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final honey = theme.colorScheme.primary;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: theme.brightness == Brightness.dark
          ? SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent, systemNavigationBarColor: Colors.transparent)
          : SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent, systemNavigationBarColor: Colors.transparent),
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          if (_nombreController.text.trim().isNotEmpty) {
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: Text(context.tr('exitWithoutSaving')),
                content: Text(context.tr('unsavedChanges')),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context), child: Text(context.tr('cancel'))),
                  TextButton(onPressed: () { Navigator.pop(context); Navigator.pop(context); }, child: Text(context.tr('confirm'))),
                ],
              ),
            );
          } else {
            Navigator.pop(context);
          }
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
                  Text(context.tr('newCategory'), style: theme.textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w700, height: 1.1)),
                  const SizedBox(height: 32),
                  Text(context.tr('categoryType'), style: theme.textTheme.bodySmall?.copyWith(color: honey, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
                  const SizedBox(height: 12),
                  _TipoOption(label: context.tr('categoryIngreso'), descripcion: context.tr('categoryIngresoDesc'), valor: 'ingreso', seleccionado: _tipoSeleccionado, onTap: () => setState(() => _tipoSeleccionado = 'ingreso')),
                  const SizedBox(height: 8),
                  _TipoOption(label: context.tr('categoryGasto'), descripcion: context.tr('categoryGastoDesc'), valor: 'gasto', seleccionado: _tipoSeleccionado, onTap: () => setState(() => _tipoSeleccionado = 'gasto')),
                  const SizedBox(height: 8),
                  _TipoOption(label: context.tr('categoryAhorro'), descripcion: context.tr('categoryAhorroDesc'), valor: 'ahorro', seleccionado: _tipoSeleccionado, onTap: () => setState(() => _tipoSeleccionado = 'ahorro')),
                  const SizedBox(height: 32),
                  Text(context.tr('categoryName'), style: theme.textTheme.bodySmall?.copyWith(color: honey, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nombreController,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _crearCategoria(),
                    decoration: InputDecoration(hintText: context.tr('categoryNameHint')),
                    onChanged: (_) { if (_errorMessage != null) setState(() => _errorMessage = null); },
                  ),
                  if (_errorMessage != null) ...[const SizedBox(height: 8), Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 13))],
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _crearCategoria,
                      child: _isLoading
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                          : Text(context.tr('createCategory'), style: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1)),
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

class _TipoOption extends StatelessWidget {
  final String label;
  final String descripcion;
  final String valor;
  final String seleccionado;
  final VoidCallback onTap;

  const _TipoOption({required this.label, required this.descripcion, required this.valor, required this.seleccionado, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final honey = theme.colorScheme.primary;
    final isSelected = valor == seleccionado;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? honey.withOpacity(0.12) : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? honey : Colors.transparent, width: 2),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 20, height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: isSelected ? honey : theme.colorScheme.onSurface.withOpacity(0.4), width: 2),
                color: isSelected ? honey : Colors.transparent,
              ),
              child: isSelected ? Icon(Icons.check, size: 12, color: theme.colorScheme.onPrimary) : null,
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: isSelected ? honey : theme.colorScheme.onSurface)),
                Text(descripcion, style: theme.textTheme.bodySmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}