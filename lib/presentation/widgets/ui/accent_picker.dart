import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';

/// Selector de color de acento (Perfil → Apariencia).
///
/// Círculos de 40px; el seleccionado lleva un anillo doble (fondo + texto).
class AccentPicker extends StatelessWidget {
  const AccentPicker({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final AppAccent selected;
  final ValueChanged<AppAccent> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final brightness = Theme.of(context).brightness;

    return Wrap(
      spacing: 14,
      runSpacing: 14,
      children: [
        for (final a in AppAccent.values)
          Semantics(
            label: 'Color de acento ${a.label}',
            selected: a == selected,
            button: true,
            child: GestureDetector(
              onTap: () => onChanged(a),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: a.colorFor(brightness),
                  shape: BoxShape.circle,
                  boxShadow: a == selected
                      ? [
                          // Flutter pinta las sombras en orden: primero el anillo externo
                          BoxShadow(color: p.text, spreadRadius: 5),
                          BoxShadow(color: p.card, spreadRadius: 3),
                        ]
                      : const [],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
