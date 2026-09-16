import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/premium_service.dart';
import '../utils/app_translator.dart';

// Paleta especial de Hivefi (definida en el prompt)
const Color _kPremiumDark = Color(0xFF0F3A30);
const Color _kPremiumTrack = Color(0xFF1D5244);
const Color _kPremiumLabel = Color(0xFF8FB5A8);

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
              borderRadius: BorderRadius.circular(10),
            ),
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final premium = context.watch<PremiumService>();
    final esPremium = premium.isPremium;

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
              _HeaderPremium(
                onClose: () => Navigator.pop(context),
                esPremium: esPremium,
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _FilaBeneficio(
                        icono: Icons.dark_mode_outlined,
                        titulo: context.tr('premiumBeneficio1'),
                        subtitulo: context.tr('premiumBeneficio1Desc'),
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(height: 14),
                      _FilaBeneficio(
                        icono: Icons.grid_view_rounded,
                        titulo: context.tr('premiumBeneficio2'),
                        subtitulo: context.tr('premiumBeneficio2Desc'),
                        color: theme.colorScheme.secondary,
                      ),
                      const SizedBox(height: 14),
                      _FilaBeneficio(
                        icono: Icons.block_outlined,
                        titulo: context.tr('premiumBeneficio3'),
                        subtitulo: context.tr('premiumBeneficio3Desc'),
                        color: theme.colorScheme.tertiary,
                      ),
                      const SizedBox(height: 28),
                      if (!esPremium) ...[
                        _PrecioDestacado(precio: premium.precioFormateado),
                        const SizedBox(height: 20),
                        _BotonComprar(
                          onPressed: _comprando ? null : _comprar,
                          comprando: _comprando,
                        ),
                        const SizedBox(height: 12),
                        _BotonRestaurar(
                          onPressed: _restaurando ? null : _restaurar,
                          restaurando: _restaurando,
                        ),
                        const SizedBox(height: 16),
                        const _MicrocopyConfianza(),
                      ] else
                        const _BannerPremiumActivo(),
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

class _HeaderPremium extends StatelessWidget {
  final VoidCallback onClose;
  final bool esPremium;

  const _HeaderPremium({required this.onClose, required this.esPremium});

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
              esPremium
                  ? Icons.verified_rounded
                  : Icons.workspace_premium_rounded,
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
                'Premium',
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
            context.tr('premiumSubtitulo'),
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
                subtitulo,
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

// ─── Precio destacado ─────────────────────────────────────────────────────────

class _PrecioDestacado extends StatelessWidget {
  final String precio;

  const _PrecioDestacado({required this.precio});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final honey = theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: honey.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: honey.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Text(
            precio,
            style: TextStyle(
              color: honey,
              fontSize: 34,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
              height: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            context.tr('premiumPagoUnico'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Botón comprar ────────────────────────────────────────────────────────────

class _BotonComprar extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool comprando;

  const _BotonComprar({required this.onPressed, required this.comprando});

  @override
  Widget build(BuildContext context) {
    final honey = Theme.of(context).colorScheme.primary;

    return SizedBox(
      width: double.infinity,
      height: 54,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: honey,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: comprando
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Text(
                context.tr('premiumActivar'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}

// ─── Botón restaurar ──────────────────────────────────────────────────────────

class _BotonRestaurar extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool restaurando;

  const _BotonRestaurar({required this.onPressed, required this.restaurando});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: double.infinity,
      height: 46,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: theme.colorScheme.outlineVariant,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: restaurando
            ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(
                context.tr('premiumRestaurar'),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
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

// ─── Banner de usuario Premium activo ─────────────────────────────────────────

class _BannerPremiumActivo extends StatelessWidget {
  const _BannerPremiumActivo();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final honey = theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: honey.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: honey.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Icon(Icons.verified_rounded, color: honey, size: 40),
          const SizedBox(height: 12),
          Text(
            context.tr('premiumActivo'),
            style: TextStyle(
              color: honey,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            context.tr('premiumGracias'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}