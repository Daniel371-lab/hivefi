import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/premium_service.dart';
import '../utils/app_translator.dart';

class ApoyoScreen extends StatefulWidget {
  const ApoyoScreen({super.key});

  @override
  State<ApoyoScreen> createState() => _ApoyoScreenState();
}

class _ApoyoScreenState extends State<ApoyoScreen> {
  String? _comprando;

  Future<void> _donar(String productId) async {
    setState(() => _comprando = productId);
    try {
      final exito = await PremiumService.instance.donar(productId);
      if (!exito && mounted) _mostrarError(context.tr('apoyoError'));
    } catch (_) {
      if (mounted) _mostrarError(context.tr('apoyoError'));
    } finally {
      if (mounted) setState(() => _comprando = null);
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Theme.of(context).colorScheme.error,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
                decoration: const BoxDecoration(color: Color(0xFF0F3A30)),
                child: Column(
                  children: [
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
                          child: const Icon(Icons.close_rounded,
                              color: Colors.white, size: 18),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: honey.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.favorite_rounded, color: honey, size: 40),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'HIVE-FI',
                      style: TextStyle(
                        color: honey,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.tr('apoyoTitulo'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.tr('apoyoSubtitulo'),
                      style: const TextStyle(
                        color: Color(0xFF8FB5A8),
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                  child: Column(
                    children: [
                      _FilaApoyo(
                        icono: Icons.coffee_rounded,
                        titulo: context.tr('apoyoCafe'),
                        subtitulo: context.tr('apoyoCafeDesc'),
                        precio: premium.precioCafe,
                        cargando: _comprando == PremiumService.productIdCafe,
                        onTap: () => _donar(PremiumService.productIdCafe),
                        color: const Color(0xFF92400E),
                      ),
                      const SizedBox(height: 12),
                      _FilaApoyo(
                        icono: Icons.restaurant_rounded,
                        titulo: context.tr('apoyoComida'),
                        subtitulo: context.tr('apoyoComidaDesc'),
                        precio: premium.precioComida,
                        cargando: _comprando == PremiumService.productIdComida,
                        onTap: () => _donar(PremiumService.productIdComida),
                        color: const Color(0xFF0F766E),
                      ),
                      const SizedBox(height: 12),
                      _FilaApoyo(
                        icono: Icons.workspace_premium_rounded,
                        titulo: context.tr('apoyoBanquete'),
                        subtitulo: context.tr('apoyoBanqueteDesc'),
                        precio: premium.precioBanquete,
                        cargando: _comprando == PremiumService.productIdBanquete,
                        onTap: () => _donar(PremiumService.productIdBanquete),
                        color: honey,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        context.tr('apoyoNota'),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.4),
                        ),
                        textAlign: TextAlign.center,
                      ),
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

class _FilaApoyo extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String subtitulo;
  final String precio;
  final bool cargando;
  final VoidCallback onTap;
  final Color color;

  const _FilaApoyo({
    required this.icono,
    required this.titulo,
    required this.subtitulo,
    required this.precio,
    required this.cargando,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: cargando ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
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
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
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
            const SizedBox(width: 12),
            cargando
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: color),
                  )
                : Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      precio,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}