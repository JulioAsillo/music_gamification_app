import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';

/// Píldora con la racha de días (llama naranja + número). Header de Inicio.
class StreakBadge extends StatelessWidget {
  const StreakBadge({super.key, required this.days, this.onTap});

  final int days;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      label: 'Racha de $days días',
      button: onTap != null,
      child: Material(
        color: p.surface,
        shape: StadiumBorder(side: BorderSide(color: p.divider)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.local_fire_department_rounded, size: 18, color: AppPalette.flame),
                const SizedBox(width: 6),
                Text(
                  '$days',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(color: p.text),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
