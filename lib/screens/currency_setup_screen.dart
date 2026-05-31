import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/app_translator.dart';

class CurrencySetupScreen extends StatefulWidget {
  const CurrencySetupScreen({super.key});

  @override
  State<CurrencySetupScreen> createState() => _CurrencySetupScreenState();
}

class _CurrencySetupScreenState extends State<CurrencySetupScreen> {
  static const List<Map<String, String>> _monedas = [
    {'code': 'USD', 'label': 'USD - Dólar estadounidense'},
    {'code': 'EUR', 'label': 'EUR - Euro'},
    {'code': 'ARS', 'label': 'ARS - Peso argentino'},
    {'code': 'PYG', 'label': 'PYG - Guaraní paraguayo'},
    {'code': 'BRL', 'label': 'BRL - Real brasileño'},
    {'code': 'CLP', 'label': 'CLP - Peso chileno'},
    {'code': 'COP', 'label': 'COP - Peso colombiano'},
    {'code': 'PEN', 'label': 'PEN - Sol peruano'},
    {'code': 'UYU', 'label': 'UYU - Peso uruguayo'},
    {'code': 'BOB', 'label': 'BOB - Boliviano'},
    {'code': 'VES', 'label': 'VES - Bolívar venezolano'},
    {'code': 'MXN', 'label': 'MXN - Peso mexicano'},
    {'code': 'GTQ', 'label': 'GTQ - Quetzal guatemalteco'},
    {'code': 'HNL', 'label': 'HNL - Lempira hondureño'},
    {'code': 'NIO', 'label': 'NIO - Córdoba nicaragüense'},
    {'code': 'CRC', 'label': 'CRC - Colón costarricense'},
    {'code': 'DOP', 'label': 'DOP - Peso dominicano'},
  ];

  // Paso 1 = idioma, Paso 2 = moneda
  int _paso = 1;
  String _seleccionadaMoneda = 'USD';
  String _seleccionadoIdioma = 'es';
  bool _guardando = false;

  Future<void> _confirmar() async {
    setState(() => _guardando = true);
    final provider = context.read<AppProvider>();

    // Guardar idioma
    await provider.setLocale(Locale(_seleccionadoIdioma));

    // Guardar moneda y marcar en Firestore
    await provider.confirmarMonedaConfigurada(_seleccionadaMoneda);

    // Reset del flag para que AuthWrapper no vuelva a mandar aquí
    provider.resetMonedaConfigurada();

    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: _paso == 1
              ? _buildPasoIdioma(theme)
              : _buildPasoMoneda(theme),
        ),
      ),
    );
  }

  Widget _buildPasoIdioma(ThemeData theme) {
    final opciones = [
      {'code': 'es', 'label': 'Español', 'sub': 'Idioma predeterminado'},
      {'code': 'en', 'label': 'English', 'sub': 'Default language'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPasoIndicador(theme),
        const SizedBox(height: 24),
        Text(
          context.tr('language_setup_title'),
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          context.tr('language_setup_subtitle'),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 32),
        ...opciones.map((op) {
          final sel = _seleccionadoIdioma == op['code'];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => setState(() => _seleccionadoIdioma = op['code']!),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 18,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: sel
                      ? theme.colorScheme.primary.withOpacity(0.12)
                      : theme.colorScheme.surface,
                  border: Border.all(
                    color: sel
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline.withOpacity(0.3),
                    width: sel ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            op['label']!,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: sel
                                  ? FontWeight.w700
                                  : FontWeight.normal,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            op['sub']!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (sel)
                      Icon(
                        Icons.check_circle,
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                  ],
                ),
              ),
            ),
          );
        }),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () => setState(() => _paso = 2),
            child: Text(context.tr('language_setup_next')),
          ),
        ),
      ],
    );
  }

  Widget _buildPasoMoneda(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPasoIndicador(theme),
        const SizedBox(height: 24),
        Text(
          context.tr('currency_setup_title'),
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          context.tr('currency_setup_subtitle'),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 32),
        Expanded(
          child: ListView.separated(
            itemCount: _monedas.length,
            separatorBuilder: (_, __) => const SizedBox(height: 4),
            itemBuilder: (context, index) {
              final moneda = _monedas[index];
              final sel = _seleccionadaMoneda == moneda['code'];
              return InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () =>
                    setState(() => _seleccionadaMoneda = moneda['code']!),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: sel
                        ? theme.colorScheme.primary.withOpacity(0.12)
                        : theme.colorScheme.surface,
                    border: Border.all(
                      color: sel
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline.withOpacity(0.3),
                      width: sel ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          moneda['label']!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight:
                                sel ? FontWeight.w600 : FontWeight.normal,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                      if (sel)
                        Icon(
                          Icons.check_circle,
                          size: 18,
                          color: theme.colorScheme.primary,
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            OutlinedButton(
              onPressed: _guardando
                  ? null
                  : () => setState(() => _paso = 1),
              child: Text(context.tr('cancel')),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: _guardando ? null : _confirmar,
                child: _guardando
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(context.tr('currency_setup_confirm')),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPasoIndicador(ThemeData theme) {
    return Row(
      children: List.generate(2, (i) {
        final activo = i + 1 == _paso;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(right: 6),
          width: activo ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: activo
                ? theme.colorScheme.primary
                : theme.colorScheme.primary.withOpacity(0.25),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}