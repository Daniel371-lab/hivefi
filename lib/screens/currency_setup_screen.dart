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

  String _seleccionada = 'USD';
  bool _guardando = false;

  Future<void> _confirmar() async {
    setState(() => _guardando = true);
    final provider = context.read<AppProvider>();
    await provider.confirmarMonedaConfigurada(_seleccionada);
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                    final seleccionada = _seleccionada == moneda['code'];
                    return InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => setState(() => _seleccionada = moneda['code']!),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: seleccionada
                              ? theme.colorScheme.primary.withOpacity(0.12)
                              : theme.colorScheme.surface,
                          border: Border.all(
                            color: seleccionada
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outline.withOpacity(0.3),
                            width: seleccionada ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                moneda['label']!,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: seleccionada
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ),
                            if (seleccionada)
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
              SizedBox(
                width: double.infinity,
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
        ),
      ),
    );
  }
}