import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/theme_provider.dart';
import '../../widgets/ui/ui.dart';

/// Galería de los componentes del sistema de diseño (Fase 2).
///
/// Sirve para revisar en el dispositivo cómo se ven con cada modo y acento
/// antes de construir las pantallas. Se puede quitar al cerrar la Fase 6.
class DesignPreviewScreen extends ConsumerStatefulWidget {
  const DesignPreviewScreen({super.key});

  @override
  ConsumerState<DesignPreviewScreen> createState() => _DesignPreviewScreenState();
}

class _DesignPreviewScreenState extends ConsumerState<DesignPreviewScreen> {
  int _chip = 0;
  int _segment = 0;
  int _playing = 0;

  static const _songs = [
    ('Bohemian Rhapsody', 'Queen • A Night at the Opera', '5:54'),
    ('Blinding Lights', 'The Weeknd • After Hours', '3:20'),
    ('Lamento Boliviano', 'Enanitos Verdes • Big Bang', '3:46'),
    ('Persiana Americana', 'Soda Stereo • Signos', '4:50'),
  ];

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final tt = Theme.of(context).textTheme;
    final themeMode = ref.watch(themeModeProvider);
    final accent = ref.watch(accentColorProvider);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 12),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Expanded(child: ScreenTitle('Diseño', subtitle: 'Vista previa')),
                  CircleIconButton(
                    icon: themeMode == ThemeMode.light ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                    tooltip: 'Cambiar modo',
                    onPressed: () => ref.read(themeModeProvider.notifier).toggleTheme(),
                  ),
                  const SizedBox(width: 8),
                  CircleIconButton(
                    icon: Icons.close_rounded,
                    tooltip: 'Cerrar',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            _Section('Acento', child: AccentPicker(
              selected: accent,
              onChanged: (a) => ref.read(accentColorProvider.notifier).setAccent(a),
            )),

            _Section('Header de Inicio', child: Row(
              children: [
                const Expanded(child: ScreenTitle('Tu música hoy', subtitle: 'Buenas noches')),
                StreakBadge(days: 5, onTap: () {}),
              ],
            )),

            const _Section('Tarjeta de nivel', child: LevelCard(level: 7, currentXp: 2340, nextLevelXp: 3000)),

            _Section('Tabs segmentados', child: SegmentedTabs(
              labels: const ['Estadísticas', 'Logros'],
              selectedIndex: _segment,
              onChanged: (i) => setState(() => _segment = i),
            )),

            _Section(
              'Chips de filtro',
              padded: false,
              child: AppFilterChipRow(
                labels: const ['Canciones', 'Artistas', 'Álbumes', 'Favoritas'],
                selectedIndex: _chip,
                onChanged: (i) => setState(() => _chip = i),
              ),
            ),

            _Section('Encabezado de sección', child: SectionHeader(
              title: 'Continuar escuchando',
              actionLabel: 'Ver todo',
              onAction: () {},
            )),

            _Section(
              'Portadas',
              padded: false,
              child: SizedBox(
                height: 120,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: 6,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (_, i) => TrackCover(seed: i, size: 120, showIcon: true),
                ),
              ),
            ),

            _Section(
              'Canciones',
              padded: false,
              child: Column(
                children: [
                  for (var i = 0; i < _songs.length; i++)
                    SongTile(
                      leading: TrackCover(seed: i),
                      title: _songs[i].$1,
                      subtitle: _songs[i].$2,
                      duration: _songs[i].$3,
                      isPlaying: i == _playing,
                      onTap: () => setState(() => _playing = i),
                    ),
                ],
              ),
            ),

            _Section('Tarjeta secundaria', child: AppCard(
              tone: AppCardTone.surface,
              padding: const EdgeInsets.all(14),
              onTap: () {},
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppPalette.gold.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.emoji_events_rounded, color: AppPalette.gold),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Coleccionista', style: tt.titleMedium),
                        Text('812 / 1000 canciones · +500 XP', style: tt.bodySmall),
                        const SizedBox(height: 8),
                        const XpProgressBar(value: 0.81, height: 6),
                      ],
                    ),
                  ),
                ],
              ),
            )),

            _Section('Botones', child: Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                FilledButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.shuffle_rounded, size: 18),
                  label: const Text('Aleatorio'),
                ),
                CircleIconButton(icon: Icons.document_scanner_outlined, tooltip: 'Escanear', onPressed: () {}),
                CircleIconButton(icon: Icons.play_arrow_rounded, tooltip: 'Reproducir', filled: true, size: 56, onPressed: () {}),
              ],
            )),

            const SizedBox(height: 8),
            Center(child: Text('${accent.label} · ${themeMode.name}', style: tt.labelSmall?.copyWith(color: p.text2))),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title, {required this.child, this.padded = true});

  final String title;
  final Widget child;
  final bool padded;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              title.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing: 1.1),
            ),
          ),
          const SizedBox(height: 10),
          if (padded) Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: child) else child,
        ],
      ),
    );
  }
}
