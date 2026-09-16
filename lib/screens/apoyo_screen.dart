import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/premium_service.dart';
import '../utils/app_translator.dart';

// Paleta especial de Hivefi (definida en el prompt)
const Color _kPremiumDark = Color(0xFF0F3A30);
const Color _kPremiumTrack = Color(0xFF1D5244);
const Color _kPremiumLabel = Color(0xFF8FB5A8);

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
    final premium = context.watch<PremiumService>();

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Material(
          color: theme.colorScheme.surface,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _HeaderApoyo(onClose: () => Navigator.pop(context)),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _FilaApoyo(
                        icono: Icons.coffee_rounded,
                        titulo: context.tr('apoyoCafe'),
                        subtitulo: context.tr('apoyoCafeDesc'),
                        precio: premium.precioCafe,
                        cargando: _comprando == PremiumService.productIdCafe,
                        onTap: () => _donar(PremiumService.productIdCafe),
                      ),
                      const SizedBox(height: 12),
                      _FilaApoyo(
                        icono: Icons.restaurant_rounded,
                        titulo: context.tr('apoyoComida'),
                        subtitulo: context.tr('apoyoComidaDesc'),
                        precio: premium.precioComida,
                        cargando: _comprando == PremiumService.productIdComida,
                        onTap: () => _donar(PremiumService.productIdComida),
                      ),
                      const SizedBox(height: 12),
                      _FilaApoyo(
                        icono: Icons.workspace_premium_rounded,
                        titulo: context.tr('apoyoBanquete'),
                        subtitulo: context.tr('apoyoBanqueteDesc'),
                        precio: premium.precioBanquete,
                        cargando:
                            _comprando == PremiumService.productIdBanquete,
                        onTap: () => _donar(PremiumService.productIdBanquete),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        context.tr('apoyoNota'),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      const _MicrocopyConfianza(),
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

// ─── Header ───────────────────────────────────────────────────────────────────

class _HeaderApoyo extends StatelessWidget {
  final VoidCallback onClose;

  const _HeaderApoyo({required this.onClose});

  @override
  Widget build(BuildContext context) {
    final honey = Theme.of(context).colorScheme.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_kPremiumDark, _kPremiumTrack],
        ),
      ),
      child: Column(
        children: [
          Align(
            alignment: Alignment.topRight,
            child: GestureDetector(
              onTap: onClose,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
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
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: honey.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.favorite_rounded,
              color: honey,
              size: 36,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'Hivefi',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                context.tr('apoyoTitulo'),
                style: TextStyle(
                  color: honey,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            context.tr('apoyoSubtitulo'),
            style: const TextStyle(
              color: _kPremiumLabel,
              fontSize: 13,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── Fila de apoyo ────────────────────────────────────────────────────────────

class _FilaApoyo extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String subtitulo;
  final String precio;
  final bool cargando;
  final VoidCallback onTap;

  const _FilaApoyo({
    required this.icono,
    required this.titulo,
    required this.subtitulo,
    required this.precio,
    required this.cargando,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final honey = theme.colorScheme.primary;

    return GestureDetector(
      onTap: cargando ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: honey.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: honey.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: honey.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icono, color: honey, size: 22),
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
                      height: 1.3,
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
                        strokeWidth: 2, color: honey),
                  )
                : Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: honey,
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

// ─── Microcopy de confianza ───────────────────────────────────────────────────

class _MicrocopyConfianza extends StatelessWidget {
  const _MicrocopyConfianza();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.lock_outline_rounded,
          size: 14,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            context.tr('premiumCompraSegura'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}