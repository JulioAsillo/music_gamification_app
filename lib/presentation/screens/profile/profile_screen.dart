import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/utils/formatters.dart';
import '../../providers/profile_provider.dart';
import '../../providers/stats_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/ui/ui.dart';
import '../scan/scan_sheet.dart';

/// Perfil (diseños "5 · Perfil y temas" y "6 · Perfil claro").
///
/// Avatar + nivel, Apariencia (modo y acento), carpetas de música,
/// almacenamiento y "Acerca de".
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  static const _modes = [ThemeMode.light, ThemeMode.dark, ThemeMode.system];
  static const appVersion = '1.0.0';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final tt = Theme.of(context).textTheme;
    final themeMode = ref.watch(themeModeProvider);
    final accent = ref.watch(accentColorProvider);
    final name = ref.watch(displayNameProvider);
    final stats = ref.watch(watchUserStatsProvider).value;

    final initial = name.isEmpty ? '♪' : name.characters.first.toUpperCase();

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
          children: [
            // ── Encabezado ──
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _editName(context, ref, name),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: p.accent,
                      child: Text(
                        initial,
                        style: tt.titleLarge?.copyWith(color: p.onAccent, fontWeight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name.isEmpty ? 'Perfil' : name, style: tt.headlineMedium?.copyWith(fontSize: 24)),
                          Text(
                            'Nivel ${stats?.level ?? 1} · ${Fmt.songs(stats?.totalTracksPlayed ?? 0)} escuchadas',
                            style: tt.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.edit_outlined, size: 20, color: p.text2),
                  ],
                ),
              ),
            ),
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

            // ── Música / datos / info ──
            AppCard(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                children: [
                  _Row(
                    icon: Icons.folder_outlined,
                    title: 'Carpetas de música',
                    subtitle: 'Escanear y actualizar biblioteca',
                    onTap: () => showScanSheet(context),
                  ),
                  _Row(
                    icon: Icons.delete_outline_rounded,
                    title: 'Almacenamiento y caché',
                    subtitle: 'Eliminar archivos temporales',
                    onTap: () => _clearCache(context),
                  ),
                  _Row(
                    icon: Icons.info_outline_rounded,
                    title: 'Acerca de',
                    subtitle: 'Versión $appVersion',
                    onTap: () => showAboutDialog(
                      context: context,
                      applicationName: 'MusiQuest',
                      applicationVersion: appVersion,
                      applicationIcon: CircleAvatar(
                        backgroundColor: p.accent,
                        child: Icon(Icons.music_note_rounded, color: p.onAccent),
                      ),
                      children: const [
                        Text('Tu música local con estadísticas, rachas y logros.'),
                      ],
                    ),
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
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => _EditNameSheet(initial: current),
    );
    if (result == null || !context.mounted) return;
    ref.read(displayNameProvider.notifier).set(result);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nombre actualizado')));
  }

  /// Borra los archivos temporales de la app y la caché de imágenes en memoria.
  /// No toca la música, la base de datos ni las carátulas guardadas.
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

    var freed = 0;
    try {
      final tmp = await getTemporaryDirectory();
      if (await tmp.exists()) {
        await for (final entity in tmp.list(followLinks: false)) {
          try {
            if (entity is File) freed += await entity.length();
            await entity.delete(recursive: true);
          } catch (_) {
            // Archivo en uso: se omite
          }
        }
      }
    } catch (_) {
      // Sin acceso al directorio temporal
    }
    PaintingBinding.instance.imageCache.clear();

    if (!context.mounted) return;
    final mb = (freed / (1024 * 1024)).toStringAsFixed(1);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Caché liberada ($mb MB)')));
  }
}

/// Hoja para editar el nombre de usuario. Valida que no esté vacío, muestra
/// una vista previa del avatar y es dueña de su [TextEditingController]
/// (se libera al desmontarse, no antes de la animación de salida).
class _EditNameSheet extends StatefulWidget {
  const _EditNameSheet({required this.initial});

  final String initial;

  @override
  State<_EditNameSheet> createState() => _EditNameSheetState();
}

class _EditNameSheetState extends State<_EditNameSheet> {
  late final TextEditingController _controller = TextEditingController(text: widget.initial);
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(_controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 4, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
      child: Form(
        key: _formKey,
        child: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            final typed = _controller.text.trim();
            final initial = typed.isEmpty ? '♪' : typed.characters.first.toUpperCase();

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Nombre de usuario', style: tt.titleLarge),
                const SizedBox(height: 4),
                Text('Así aparecerás en tu perfil.', style: tt.bodySmall),
                const SizedBox(height: 20),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: p.accent,
                      child: Text(
                        initial,
                        style: tt.titleLarge?.copyWith(color: p.onAccent, fontWeight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: TextFormField(
                        controller: _controller,
                        autofocus: true,
                        maxLength: 30,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _save(),
                        decoration: const InputDecoration(hintText: 'Escribe tu nombre'),
                        validator: (v) {
                          final clean = (v ?? '').trim();
                          if (clean.isEmpty) return 'El nombre no puede estar vacío';
                          if (clean.length < 2) return 'Usa al menos 2 caracteres';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(onPressed: _save, child: const Text('Guardar')),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.title, required this.subtitle, required this.onTap});

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
