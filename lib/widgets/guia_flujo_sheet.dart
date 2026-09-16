import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_translator.dart';

class GuiaFlujoSheet {
  static const String _keyVisto = 'guia_flujo_vista';

  // Muestra el bottom sheet
  static Future<void> mostrar(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _GuiaFlujoContenido(),
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyVisto, true);
  }

  // Devuelve true si el usuario nunca vio la guía
  static Future<bool> esPrimeraVez() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_keyVisto) ?? false);
  }
}

class _GuiaFlujoContenido extends StatelessWidget {
  const _GuiaFlujoContenido();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final honey = theme.colorScheme.primary;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              // Drag handle
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Título
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 4),
                child: Row(
                  children: [
                    Icon(Icons.help_outline_rounded, color: honey, size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        context.tr('guiaTitulo'),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                      iconSize: 22,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  context.tr('guiaSubtitulo'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Contenido scrolleable
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                  children: [
                    _FlujoVisual(honey: honey, theme: theme),
                    const SizedBox(height: 28),
                    _ItemGuia(
                      icono: Icons.arrow_downward_rounded,
                      color: honey,
                      titulo: context.tr('guiaIngreso'),
                      descripcion: context.tr('guiaIngresoDesc'),
                    ),
                    const SizedBox(height: 12),
                    _ItemGuia(
                      icono: Icons.pie_chart_rounded,
                      color: honey,
                      titulo: context.tr('guiaDestinar'),
                      descripcion: context.tr('guiaDestinarDesc'),
                    ),
                    const SizedBox(height: 12),
                    _ItemGuia(
                      icono: Icons.arrow_upward_rounded,
                      color: honey,
                      titulo: context.tr('guiaGasto'),
                      descripcion: context.tr('guiaGastoDesc'),
                    ),
                    const SizedBox(height: 12),
                    _ItemGuia(
                      icono: Icons.compare_arrows_rounded,
                      color: honey,
                      titulo: context.tr('guiaReparto'),
                      descripcion: context.tr('guiaRepartoDesc'),
                    ),
                    const SizedBox(height: 12),
                    _ItemGuia(
                      icono: Icons.grid_view_rounded,
                      color: honey,
                      titulo: context.tr('guiaCategorias'),
                      descripcion: context.tr('guiaCategoriasDesc'),
                    ),
                    const SizedBox(height: 12),
                    _ItemGuia(
                      icono: Icons.history_rounded,
                      color: honey,
                      titulo: context.tr('guiaHistorial'),
                      descripcion: context.tr('guiaHistorialDesc'),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 50,
                      child: FilledButton(
                        onPressed: () => Navigator.pop(context),
                        style: FilledButton.styleFrom(
                          backgroundColor: honey,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          context.tr('guiaEntendido'),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Flujo visual (Ingreso → Destinar → Gasto) ───────────────────────────────

class _FlujoVisual extends StatelessWidget {
  final Color honey;
  final ThemeData theme;

  const _FlujoVisual({required this.honey, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: honey.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: honey.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('guiaFlujoEtiqueta'),
            style: theme.textTheme.labelSmall?.copyWith(
              color: honey,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _PasoFlujo(
                  numero: '1',
                  etiqueta: context.tr('income'),
                  honey: honey,
                  theme: theme,
                ),
              ),
              Icon(Icons.arrow_forward_rounded,
                  size: 16, color: honey.withValues(alpha: 0.5)),
              Expanded(
                child: _PasoFlujo(
                  numero: '2',
                  etiqueta: context.tr('destinar'),
                  honey: honey,
                  theme: theme,
                ),
              ),
              Icon(Icons.arrow_forward_rounded,
                  size: 16, color: honey.withValues(alpha: 0.5)),
              Expanded(
                child: _PasoFlujo(
                  numero: '3',
                  etiqueta: context.tr('expensesM'),
                  honey: honey,
                  theme: theme,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PasoFlujo extends StatelessWidget {
  final String numero;
  final String etiqueta;
  final Color honey;
  final ThemeData theme;

  const _PasoFlujo({
    required this.numero,
    required this.etiqueta,
    required this.honey,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: honey,
            shape: BoxShape.circle,
          ),
          child: Text(
            numero,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          etiqueta,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 11,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

// ─── Item de guía ─────────────────────────────────────────────────────────────

class _ItemGuia extends StatelessWidget {
  final IconData icono;
  final Color color;
  final String titulo;
  final String descripcion;

  const _ItemGuia({
    required this.icono,
    required this.color,
    required this.titulo,
    required this.descripcion,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icono, color: color, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                descripcion,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}