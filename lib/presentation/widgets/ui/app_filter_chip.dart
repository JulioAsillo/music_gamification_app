import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';

/// Chip de filtro del diseño (Biblioteca: Canciones/Artistas/Álbumes/Favoritas).
///
/// Activo: relleno con el acento. Inactivo: transparente con borde `divider`.
class AppFilterChip extends StatelessWidget {
  const AppFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? p.accent : Colors.transparent,
        shape: StadiumBorder(
          side: selected ? BorderSide.none : BorderSide(color: p.divider),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.center,
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: selected ? p.onAccent : p.text,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Fila horizontal desplazable de [AppFilterChip].
class AppFilterChipRow extends StatelessWidget {
  const AppFilterChipRow({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: padding,
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            AppFilterChip(
              label: labels[i],
              selected: i == selectedIndex,
              onTap: () => onChanged(i),
            ),
          ],
        ],
      ),
    );
  }
}
