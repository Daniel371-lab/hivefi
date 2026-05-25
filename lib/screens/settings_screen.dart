import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/app_translator.dart';

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
        appBar: AppBar(
          title: Text(context.tr.settings),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              _SectionHeader(label: 'CUENTA'),
              _SettingsTile(
                icon: Icons.person_outline_rounded,
                label: context.tr.profile,
                onTap: () {},
              ),
              _SectionHeader(label: 'APARIENCIA'),
              _ThemeTile(),
              _LanguageTile(),
              _SectionHeader(label: 'BENEFICIOS'),
              _SettingsTile(
                icon: Icons.workspace_premium_outlined,
                label: context.tr.premium,
                onTap: () {},
                trailing: _BadgePremium(),
              ),
              _SettingsTile(
                icon: Icons.block_outlined,
                label: context.tr.adFreeMode,
                onTap: () {},
              ),
              _SettingsTile(
                icon: Icons.favorite_border_rounded,
                label: context.tr.donate,
                onTap: () {},
              ),
              _SectionHeader(label: 'SESIÓN'),
              _SettingsTile(
                icon: Icons.logout_rounded,
                label: context.tr.logout,
                onTap: () => _confirmLogout(context),
              ),
              _SettingsTile(
                icon: Icons.delete_outline_rounded,
                label: context.tr.deleteAccount,
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

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(context.tr.logout),
        content: const Text('¿Seguro que querés cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr.confirm),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(context.tr.deleteAccount),
        content: const Text('Esta acción es irreversible. ¿Querés eliminar tu cuenta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr.cancel),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr.confirm),
          ),
        ],
      ),
    );
  }
}

// ─── Section Header ──────────────────────────────────────────────────────────

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

// ─── Tile genérico ───────────────────────────────────────────────────────────

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
    final color = isDestructive ? Colors.red : theme.colorScheme.onSurface;

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

// ─── Tile Tema ───────────────────────────────────────────────────────────────

class _ThemeTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final theme = Theme.of(context);

    final options = {
      ThemeMode.system: 'Sistema',
      ThemeMode.light: 'Claro',
      ThemeMode.dark: 'Oscuro',
    };

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: Icon(Icons.brightness_6_outlined,
          color: theme.colorScheme.onSurface),
      title: Text(context.tr.darkMode, style: theme.textTheme.bodyMedium),
      trailing: DropdownButton<ThemeMode>(
        value: provider.themeMode,
        underline: const SizedBox(),
        isDense: true,
        items: options.entries
            .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
            .toList(),
        onChanged: (val) {
          if (val != null) provider.setThemeMode(val);
        },
      ),
    );
  }
}

// ─── Tile Idioma ─────────────────────────────────────────────────────────────

class _LanguageTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final theme = Theme.of(context);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: Icon(Icons.language_rounded, color: theme.colorScheme.onSurface),
      title: Text(context.tr.language, style: theme.textTheme.bodyMedium),
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

// ─── Badge Premium ───────────────────────────────────────────────────────────

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