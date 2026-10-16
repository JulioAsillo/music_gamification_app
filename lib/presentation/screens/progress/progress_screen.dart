import 'package:flutter/material.dart';

import '../../widgets/ui/ui.dart';
import '../achievements/achievements_screen.dart';
import '../stats/stats_screen.dart';

/// Progreso: Estadísticas / Logros
/// (Fase 3: reutiliza las pantallas antiguas; rediseño en la Fase 5).
class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  late int _tab = widget.initialTab;

  @override
  void didUpdateWidget(ProgressScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTab != widget.initialTab) _tab = widget.initialTab;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 20, 16, 12),
              child: ScreenTitle('Progreso'),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SegmentedTabs(
                labels: const ['Estadísticas', 'Logros'],
                selectedIndex: _tab,
                onChanged: (i) => setState(() => _tab = i),
              ),
            ),
            Expanded(
              child: IndexedStack(
                index: _tab,
                children: const [StatsScreen(), AchievementsScreen()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
