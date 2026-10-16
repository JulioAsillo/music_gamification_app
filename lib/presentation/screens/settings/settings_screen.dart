import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/theme_provider.dart';
import '../../widgets/ui/ui.dart';
import '../scan/scan_sheet.dart';
import 'design_preview_screen.dart';

/// Pantalla de ajustes.
///
/// Fase 2: la sección Apariencia ya usa el sistema de diseño nuevo
/// (modo Claro/Oscuro/Sistema + color de acento). En la Fase 6 esta pantalla
/// se convierte en "Perfil".
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const _modes = [ThemeMode.light, ThemeMode.dark, ThemeMode.system];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final accent = ref.watch(accentColorProvider);
    final p = context.palette;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
          children: [
            const ScreenTitle('Ajustes'),
            const SizedBox(height: 20),

            // ── Apariencia ──
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Apariencia', style: tt.titleMedium),
                  const SizedBox(height: 14),
                  Text('Modo', style: tt.bodySmall),
                  const SizedBox(height: 8),
                  SegmentedTabs(
                    labels: const ['Claro', 'Oscuro', 'Sistema'],
                    selectedIndex: _modes.indexOf(themeMode),
                    onChanged: (i) => ref.read(themeModeProvider.notifier).setMode(_modes[i]),
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
            ),
            const SizedBox(height: 16),

            // ── Música / Datos / Info ──
            AppCard(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                children: [
                  _SettingsRow(
                    icon: Icons.folder_open_rounded,
                    title: 'Escanear música',
                    subtitle: 'Buscar canciones en el dispositivo',
                    onTap: () => showScanSheet(context),
                  ),
                  _SettingsRow(
                    icon: Icons.delete_outline_rounded,
                    title: 'Almacenamiento y caché',
                    subtitle: 'Eliminar archivos temporales',
                    onTap: () {
                      // Fase 6
                    },
                  ),
                  _SettingsRow(
                    icon: Icons.palette_outlined,
                    title: 'Vista previa del diseño',
                    subtitle: 'Componentes del sistema de diseño',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const DesignPreviewScreen()),
                    ),
                  ),
                  _SettingsRow(
                    icon: Icons.info_outline_rounded,
                    title: 'Acerca de',
                    subtitle: 'Versión 1.0.0',
                    onTap: () {
                      // Fase 6
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text('MusiQuest', style: tt.labelSmall?.copyWith(color: p.text2)),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ListTile(
      leading: Icon(icon, color: p.text2),
      title: Text(title, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      trailing: Icon(Icons.chevron_right_rounded, color: p.text2),
      onTap: onTap,
    );
  }
}
