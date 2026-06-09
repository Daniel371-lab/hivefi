import 'dart:async';
import 'package:flutter/material.dart';
import '../widgets/banner_ad_widget.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/app_provider.dart';
import '../utils/app_translator.dart';
import '../services/ad_service.dart';
import '../screens/premium_screen.dart';
import '../services/premium_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
        bottomNavigationBar: const BannerAdWidget(),
        appBar: AppBar(
          title: Text(context.tr('settings')),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              _SectionHeader(label: context.tr('sectionAccount')),
              _SettingsTile(
                icon: Icons.person_outline_rounded,
                label: context.tr('profile'),
                onTap: () => _showProfileSheet(context),
              ),
              _SectionHeader(label: context.tr('sectionAppearance')),
              _ThemeTile(),
              _LanguageTile(),
              _CurrencyTile(),
              _SectionHeader(label: context.tr('sectionBenefits')),
              _SettingsTile(
                icon: Icons.workspace_premium_outlined,
                label: context.tr('premium'),
                onTap: () => showDialog(
                  context: context,
                  builder: (_) => const PremiumScreen(),
                ),
                trailing: _BadgePremium(),
              ),
              const _AdFreeTile(),
            _SettingsTile(
                icon: Icons.favorite_border_rounded,
                label: context.tr('donate'),
                onTap: () => Navigator.pushNamed(context, '/donar'),
              ),
              _SectionHeader(label: context.tr('sectionAbout')),
              _SettingsTile(
                icon: Icons.info_outline_rounded,
                label: context.tr('aboutApp'),
                onTap: () => _showAboutSheet(context),
              ),
              _SectionHeader(label: context.tr('sectionSession')),
              _SettingsTile(
                icon: Icons.logout_rounded,
                label: context.tr('logout'),
                onTap: () => _confirmLogout(context),
              ),
              _SettingsTile(
                icon: Icons.delete_outline_rounded,
                label: context.tr('deleteAccount'),
                onTap: () => _confirmDeleteAccount(context),
                isDestructive: true,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  void _showProfileSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _ProfileSheet(),
    );
  }

  void _showAboutSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _AboutSheet(),
    );
  }

  void _confirmLogout(BuildContext context) {
    final provider = context.read<AppProvider>();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(context.tr('logout')),
        content: Text(context.tr('logoutConfirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr('cancel')),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await provider.authService.logout();
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
              }
            },
            child: Text(context.tr('confirm')),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount(BuildContext context) {
    final provider = context.read<AppProvider>();
    final passwordController = TextEditingController();
    String? errorMsg;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setStateDialog) => AlertDialog(
          title: Text(context.tr('deleteAccount')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.tr('deleteAccountConfirm')),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  errorText: errorMsg,
                ),
                onChanged: (_) {
                  if (errorMsg != null) setStateDialog(() => errorMsg = null);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(context.tr('cancel')),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              onPressed: () async {
                final password = passwordController.text;
                if (password.isEmpty) {
                  setStateDialog(() => errorMsg = 'Ingresá tu contraseña.');
                  return;
                }
                Navigator.pop(dialogContext);
                try {
                  await provider.authService.deleteAccount(
                    firestoreService: provider.firestoreService,
                    password: password,
                  );
                  if (context.mounted) {
                    Navigator.of(context)
                        .pushNamedAndRemoveUntil('/login', (_) => false);
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.toString())),
                    );
                  }
                }
              },
              child: Text(context.tr('confirm')),
            ),
          ],
        ),
      ),
    );
  }
}

// --- AD FREE TILE ---

class _AdFreeTile extends StatefulWidget {
  const _AdFreeTile();

  @override
  State<_AdFreeTile> createState() => _AdFreeTileState();
}

class _AdFreeTileState extends State<_AdFreeTile> {
  bool _adFreeActivo = false;
  DateTime? _hastaDateTime;

  @override
  void initState() {
    super.initState();
    _verificar();
  }

  Future<void> _verificar() async {
    final prefs = await SharedPreferences.getInstance();
    final until = prefs.getInt('ad_free_until') ?? 0;
    final ahora = DateTime.now().millisecondsSinceEpoch;
    final activo = ahora < until;
    if (mounted) {
      setState(() {
        _adFreeActivo = activo;
        _hastaDateTime =
            activo ? DateTime.fromMillisecondsSinceEpoch(until) : null;
      });
    }
  }

  Future<void> _activar() async {
    final exito = await AdService.instance.mostrarRewarded();
    if (mounted) {
      if (exito) {
        await _verificar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('adFreeActivated')),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('adFreeError')),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _adFreeActivo
        ? theme.colorScheme.onSurface.withOpacity(0.38)
        : theme.colorScheme.onSurface;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: Icon(Icons.block_outlined, color: color),
      title: Text(
        context.tr('adFreeMode'),
        style: theme.textTheme.bodyMedium?.copyWith(color: color),
      ),
      trailing: _adFreeActivo && _hastaDateTime != null
          ? Text(
              'Hasta ${_hastaDateTime!.hour.toString().padLeft(2, '0')}:${_hastaDateTime!.minute.toString().padLeft(2, '0')}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            )
          : const Icon(Icons.chevron_right_rounded),
      onTap: _adFreeActivo ? null : _activar,
    );
  }
}

// --- PROFILE SHEET ---

class _ProfileSheet extends StatefulWidget {
  const _ProfileSheet();

  @override
  State<_ProfileSheet> createState() => _ProfileSheetState();
}

class _ProfileSheetState extends State<_ProfileSheet> {
  late TextEditingController _nameController;
  bool _loadingName = false;
  bool _loadingReset = false;
  String? _nameError;
  String? _nameSuccess;
  String? _resetMessage;

  @override
  void initState() {
    super.initState();
    final provider = context.read<AppProvider>();
    final currentName = provider.authService.currentUser?.displayName ?? '';
    _nameController = TextEditingController(text: currentName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveName() async {
    final provider = context.read<AppProvider>();
    final newName = _nameController.text.trim();
    if (newName.isEmpty) {
      setState(() => _nameError = context.tr('nameEmpty'));
      return;
    }
    setState(() {
      _loadingName = true;
      _nameError = null;
      _nameSuccess = null;
    });
    try {
      await provider.authService.currentUser?.updateDisplayName(newName);
      await provider.authService.currentUser?.reload();
      setState(() => _nameSuccess = context.tr('nameUpdated'));
    } catch (_) {
      setState(() => _nameError = context.tr('genericError'));
    } finally {
      setState(() => _loadingName = false);
    }
  }

  Future<void> _sendReset() async {
    final provider = context.read<AppProvider>();
    final email = provider.authService.currentUser?.email ?? '';
    if (email.isEmpty) return;
    setState(() {
      _loadingReset = true;
      _resetMessage = null;
    });
    try {
      await provider.authService.resetPassword(email);
      setState(() => _resetMessage = context.tr('resetSent'));
    } catch (_) {
      setState(() => _resetMessage = context.tr('genericError'));
    } finally {
      setState(() => _loadingReset = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.read<AppProvider>();
    final email = provider.authService.currentUser?.email ?? '';

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            context.tr('profile'),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            email,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            context.tr('name'),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            maxLength: 20,
            decoration: InputDecoration(
              hintText: context.tr('nameHint'),
              errorText: _nameError,
            ),
          ),
          if (_nameSuccess != null) ...[
            const SizedBox(height: 6),
            Text(
              _nameSuccess!,
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.green),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _loadingName ? null : _saveName,
              child: _loadingName
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(context.tr('saveName')),
            ),
          ),
          const SizedBox(height: 24),
          Divider(color: theme.colorScheme.outlineVariant),
          const SizedBox(height: 16),
          Text(
            context.tr('changePassword'),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            context.tr('changePasswordDesc'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (_resetMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              _resetMessage!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _loadingReset ? null : _sendReset,
              style: OutlinedButton.styleFrom(
                alignment: Alignment.center,
              ),
              child: _loadingReset
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      context.tr('sendResetEmail'),
                      textAlign: TextAlign.center,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- ABOUT SHEET ---

class _AboutSheet extends StatelessWidget {
  const _AboutSheet();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Image.asset(
            'assets/images/logo_hivefi.webp',
            width: 64,
            height: 64,
          ),
          const SizedBox(height: 12),
          Text(
            'Hivefi',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            context.tr('appVersion'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          Divider(color: theme.colorScheme.outlineVariant),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                context.tr('madeBy'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'JPLABS',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// --- CURRENCY TILE ---

class _CurrencyTile extends StatelessWidget {
  static const _currencies = [
    ('PYG', 'Guaraní — PYG'),
    ('ARS', 'Peso argentino — ARS'),
    ('BRL', 'Real brasileño — BRL'),
    ('CLP', 'Peso chileno — CLP'),
    ('COP', 'Peso colombiano — COP'),
    ('PEN', 'Sol peruano — PEN'),
    ('UYU', 'Peso uruguayo — UYU'),
    ('BOB', 'Boliviano — BOB'),
    ('VES', 'Bolívar venezolano — VES'),
    ('MXN', 'Peso mexicano — MXN'),
    ('GTQ', 'Quetzal — GTQ'),
    ('HNL', 'Lempira — HNL'),
    ('NIO', 'Córdoba — NIO'),
    ('CRC', 'Colón — CRC'),
    ('DOP', 'Peso dominicano — DOP'),
    ('USD', 'Dólar — USD'),
    ('EUR', 'Euro — EUR'),
  ];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final theme = Theme.of(context);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: Icon(Icons.attach_money_rounded, color: theme.colorScheme.onSurface),
      title: Text(context.tr('currency'), style: theme.textTheme.bodyMedium),
      trailing: DropdownButton<String>(
        value: provider.currency,
        underline: const SizedBox(),
        isDense: true,
        items: _currencies
            .map((c) => DropdownMenuItem(value: c.$1, child: Text(c.$1)))
            .toList(),
        onChanged: (val) {
          if (val != null) provider.setCurrency(val);
        },
      ),
    );
  }
}

// --- SECTION HEADER ---

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Text(
        label,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.4,
        ),
      ),
    );
  }
}

// --- SETTINGS TILE ---

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Widget? trailing;
  final bool isDestructive;

  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isDestructive
        ? theme.colorScheme.error
        : theme.colorScheme.onSurface;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: Icon(icon, color: color),
      title: Text(
        label,
        style: theme.textTheme.bodyMedium?.copyWith(color: color),
      ),
      trailing: trailing ?? const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}

// --- THEME TILE ---

class _ThemeTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final premium = context.watch<PremiumService>();
    final theme = Theme.of(context);
    final isDark = provider.themeMode == ThemeMode.dark;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: Icon(
        isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
        color: theme.colorScheme.onSurface,
      ),
      title: Text(context.tr('darkMode'), style: theme.textTheme.bodyMedium),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'PRO',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
                fontSize: 10,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Switch(
            value: isDark,
            onChanged: (val) {
              if (!premium.isPremium) {
                showDialog(
                  context: context,
                  builder: (_) => const PremiumScreen(),
                );
                return;
              }
              provider.setThemeMode(
                val ? ThemeMode.dark : ThemeMode.light,
              );
            },
          ),
        ],
      ),
    );
  }
}

// --- LANGUAGE TILE ---

class _LanguageTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final theme = Theme.of(context);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: Icon(Icons.language_rounded, color: theme.colorScheme.onSurface),
      title: Text(context.tr('language'), style: theme.textTheme.bodyMedium),
      trailing: DropdownButton<Locale>(
        value: provider.locale,
        underline: const SizedBox(),
        isDense: true,
        items: const [
          DropdownMenuItem(value: Locale('es'), child: Text('Español')),
          DropdownMenuItem(value: Locale('en'), child: Text('English')),
        ],
        onChanged: (val) {
          if (val != null) provider.setLocale(val);
        },
      ),
    );
  }
}

// --- BADGE PREMIUM ---

class _BadgePremium extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final honey = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: honey,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'PRO',
        style: TextStyle(
          color: Theme.of(context).colorScheme.onPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}