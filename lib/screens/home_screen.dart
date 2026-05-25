import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/app_translator.dart';
import '../utils/currency_formatter.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final theme = Theme.of(context);
    final honey = theme.colorScheme.primary;

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
        extendBody: true,
        appBar: AppBar(
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => Navigator.pushNamed(context, '/settings'),
            ),
          ],
        ),
        body: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _BalanceCard(provider: provider),
                const SizedBox(height: 32),
                _HexGrid(),
                const SizedBox(height: 32),
                Text(
                  context.tr.savings,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: honey,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                _SavingsPlaceholder(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Tarjeta Balance ────────────────────────────────────────────────────────

class _BalanceCard extends StatelessWidget {
  final AppProvider provider;
  const _BalanceCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final honey = theme.colorScheme.primary;
    const double balance = 1260000;
    const double progress = 0.28;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.tr.balanceGeneral,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  '${(progress * 100).toInt()}%',
                  style: TextStyle(
                    color: honey,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                CurrencyFormatter.format(balance, provider.currency),
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                context.tr.assignedToExpenses,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
              ),
            ),
            const SizedBox(height: 12),
            _CurrencySelector(),
          ],
        ),
      ),
    );
  }
}

// ─── Selector de moneda ─────────────────────────────────────────────────────

class _CurrencySelector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final theme = Theme.of(context);

    return Row(
      children: [
        Text(context.tr.currency, style: theme.textTheme.bodySmall),
        const SizedBox(width: 12),
        DropdownButton<String>(
          value: provider.currency,
          underline: const SizedBox(),
          isDense: true,
          items: const [
            DropdownMenuItem(value: 'PYG', child: Text('GS - Guaraní')),
            DropdownMenuItem(value: 'USD', child: Text('USD - Dólar')),
            DropdownMenuItem(value: 'EUR', child: Text('EUR - Euro')),
          ],
          onChanged: (val) {
            if (val != null) provider.setCurrency(val);
          },
        ),
      ],
    );
  }
}

// ─── Grid Hexagonal ─────────────────────────────────────────────────────────

class _HexGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final items = [
      _HexItem(icon: Icons.arrow_downward_rounded, label: tr.income, route: '/transaction'),
      _HexItem(icon: Icons.arrow_upward_rounded, label: tr.expense, route: '/transaction'),
      _HexItem(icon: Icons.pie_chart_rounded, label: tr.destinar, route: '/transaction'),
      _HexItem(icon: Icons.grid_view_rounded, label: tr.categories, route: '/transaction'),
      _HexItem(icon: Icons.compare_arrows_rounded, label: tr.reparto, route: '/transaction'),
      _HexItem(icon: Icons.history_rounded, label: tr.history, route: '/transaction'),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.95,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) => _HexButton(item: items[i]),
    );
  }
}

class _HexItem {
  final IconData icon;
  final String label;
  final String route;
  const _HexItem({required this.icon, required this.label, required this.route});
}

class _HexButton extends StatelessWidget {
  final _HexItem item;
  const _HexButton({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final honey = theme.colorScheme.primary;
    final onPrimary = theme.colorScheme.onPrimary;

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, item.route),
      child: ClipPath(
        clipper: _HexClipper(),
        child: Container(
          color: honey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(item.icon, color: onPrimary, size: 28),
              const SizedBox(height: 6),
              Text(
                item.label,
                style: TextStyle(
                  color: onPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HexClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    return Path()
      ..moveTo(w * 0.5, 0)
      ..lineTo(w, h * 0.25)
      ..lineTo(w, h * 0.75)
      ..lineTo(w * 0.5, h)
      ..lineTo(0, h * 0.75)
      ..lineTo(0, h * 0.25)
      ..close();
  }

  @override
  bool shouldReclip(_HexClipper old) => false;
}

// ─── Placeholder Ahorros ────────────────────────────────────────────────────

class _SavingsPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final honey = theme.colorScheme.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(color: honey, width: 2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        'VIAJE',
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}