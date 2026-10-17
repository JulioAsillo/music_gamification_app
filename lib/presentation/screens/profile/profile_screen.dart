import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_info.dart';
import '../../../services/cache_service.dart';
import '../../providers/profile_provider.dart';
import '../../providers/stats_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/ui/ui.dart';
import '../scan/scan_sheet.dart';
import 'widgets/edit_name_sheet.dart';
import 'widgets/profile_header.dart';
import 'widgets/settings_row.dart';

/// Perfil (diseños "5 · Perfil y temas" y "6 · Perfil claro").
///
/// Avatar + nivel, Apariencia (modo y acento), carpetas de música,
/// almacenamiento y "Acerca de".
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  static const _modes = [ThemeMode.light, ThemeMode.dark, ThemeMode.system];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(displayNameProvider);
    final stats = ref.watch(watchUserStatsProvider).value;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
          children: [
            ProfileHeader(
              name: name,
              level: stats?.level ?? 1,
              tracksPlayed: stats?.totalTracksPlayed ?? 0,
              onEdit: () => _editName(context, ref, name),
            ),
            const SizedBox(height: 20),
            const _AppearanceCard(modes: _modes),
            const SizedBox(height: 16),
            AppCard(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                children: [
                  SettingsRow(
                    icon: Icons.folder_outlined,
                    title: 'Carpetas de música',
                    subtitle: 'Escanear, actualizar biblioteca y carátulas',
                    onTap: () => showScanSheet(context),
                  ),
                  SettingsRow(
                    icon: Icons.delete_outline_rounded,
                    title: 'Almacenamiento y caché',
                    subtitle: 'Eliminar archivos temporales',
                    onTap: () => _clearCache(context),
                  ),
                  SettingsRow(
                    icon: Icons.info_outline_rounded,
                    title: 'Acerca de',
                    subtitle: 'Versión ${AppInfo.version}',
                    onTap: () => _showAbout(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editName(BuildContext context, WidgetRef ref, String current) async {
    final result = await showEditNameSheet(context, initial: current);
    if (result == null || !context.mounted) return;
    ref.read(displayNameProvider.notifier).set(result);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nombre actualizado')));
  }

  Future<void> _clearCache(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Liberar espacio?'),
        content: const Text(
          'Se eliminarán los archivos temporales. Tu música, estadísticas y logros no se tocan.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (ok != true) return;

    final freed = await CacheService.clearTemporaryFiles();
    if (!context.mounted) return;
    final mb = (freed / (1024 * 1024)).toStringAsFixed(1);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Caché liberada ($mb MB)')));
  }

  void _showAbout(BuildContext context) {
    final p = context.palette;
    showAboutDialog(
      context: context,
      applicationName: AppInfo.name,
      applicationVersion: AppInfo.version,
      applicationIcon: CircleAvatar(
        backgroundColor: p.accent,
        child: Icon(Icons.music_note_rounded, color: p.onAccent),
      ),
      children: const [
        Text('Tu música local con estadísticas, rachas y logros.'),
      ],
    );
  }
}

/// Tarjeta "Apariencia": modo (claro/oscuro/sistema) y color de acento.
class _AppearanceCard extends ConsumerWidget {
  const _AppearanceCard({required this.modes});

  final List<ThemeMode> modes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tt = Theme.of(context).textTheme;
    final themeMode = ref.watch(themeModeProvider);
    final accent = ref.watch(accentColorProvider);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Apariencia', style: tt.titleMedium),
          const SizedBox(height: 14),
          Text('Modo', style: tt.bodySmall),
          const SizedBox(height: 8),
          SegmentedTabs(
            labels: const ['Claro', 'Oscuro', 'Sistema'],
            selectedIndex: modes.indexOf(themeMode),
            onChanged: (i) => ref.read(themeModeProvider.notifier).setMode(modes[i]),
          ),
          const SizedBox(height: 18),
          Text('Color de acento · ${accent.label}', style: tt.bodySmall),
          const SizedBox(height: 12),
          AccentPicker(
            selected: accent,
            onChanged: (a) => ref.read(accentColorProvider.notifier).setAccent(a),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}
