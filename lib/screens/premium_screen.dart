import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/premium_service.dart';
import '../utils/app_translator.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  bool _comprando = false;
  bool _restaurando = false;

  Future<void> _comprar() async {
    setState(() => _comprando = true);
    try {
      final exito = await PremiumService.instance.comprarPremium();
      if (!exito && mounted) {
        _mostrarError(context.tr('premiumErrorCompra'));
      }
    } catch (_) {
      if (mounted) _mostrarError(context.tr('premiumErrorCompra'));
    } finally {
      if (mounted) setState(() => _comprando = false);
    }
  }

  Future<void> _restaurar() async {
    setState(() => _restaurando = true);
    try {
      await PremiumService.instance.restaurar();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('premiumRestaurado')),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (_) {
      if (mounted) _mostrarError(context.tr('premiumErrorCompra'));
    } finally {
      if (mounted) setState(() => _restaurando = false);
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Theme.of(context).colorScheme.error,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final honey = theme.colorScheme.primary;
    final premium = context.watch<PremiumService>();

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          body: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
                decoration: const BoxDecoration(
                  color: Color(0xFF0F3A30),
                ),
                child: Column(
                  children: [
                    // Botón cerrar
                    Align(
                      alignment: Alignment.topRight,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Icono corona
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: honey.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.workspace_premium_rounded,
                        color: honey,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'HIVEFI',
                      style: TextStyle(
                        color: honey,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Premium',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.tr('premiumSubtitulo'),
                      style: const TextStyle(
                        color: Color(0xFF8FB5A8),
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              // Beneficios
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                  child: Column(
                    children: [
                      _FilaBeneficio(
                        icono: Icons.dark_mode_outlined,
                        titulo: context.tr('premiumBeneficio1'),
                        subtitulo: context.tr('premiumBeneficio1Desc'),
                        color: const Color(0xFF6366F1),
                      ),
                      const SizedBox(height: 16),
                      _FilaBeneficio(
                        icono: Icons.grid_view_rounded,
                        titulo: context.tr('premiumBeneficio2'),
                        subtitulo: context.tr('premiumBeneficio2Desc'),
                        color: const Color(0xFF14B8A6),
                      ),
                      const SizedBox(height: 16),
                      _FilaBeneficio(
                        icono: Icons.block_outlined,
                        titulo: context.tr('premiumBeneficio3'),
                        subtitulo: context.tr('premiumBeneficio3Desc'),
                        color: honey,
                      ),
                      const SizedBox(height: 24),

                      // Pago único
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: honey.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: honey.withOpacity(0.25)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.all_inclusive_rounded,
                                color: honey, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              context.tr('premiumPagoUnico'),
                              style: TextStyle(
                                color: honey,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Botón comprar
                      if (premium.isPremium)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: Colors.green.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_circle_rounded,
                                  color: Colors.green, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                context.tr('premiumActivo'),
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _comprando ? null : _comprar,
                            style: FilledButton.styleFrom(
                              backgroundColor: honey,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: _comprando
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    '${context.tr('premiumActivar')} — ${premium.precioFormateado}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),

                      const SizedBox(height: 12),

                      // Restaurar compra
                      if (!premium.isPremium)
                        TextButton(
                          onPressed: _restaurando ? null : _restaurar,
                          child: _restaurando
                              ? const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2),
                                )
                              : Text(
                                  context.tr('premiumRestaurar'),
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    fontSize: 12,
                                  ),
                                ),
                        ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Fila de beneficio ────────────────────────────────────────────────────────

class _FilaBeneficio extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String subtitulo;
  final Color color;

  const _FilaBeneficio({
    required this.icono,
    required this.titulo,
    required this.subtitulo,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icono, color: color, size: 22),
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
                subtitulo,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Icon(Icons.check_rounded, color: color, size: 18),
      ],
    );
  }
}