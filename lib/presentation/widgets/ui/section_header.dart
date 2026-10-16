import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';

/// Título de sección 18/700 con acción opcional a la derecha ("Ver todo").
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: Text(title, style: tt.titleLarge)),
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              foregroundColor: context.palette.accent,
              textStyle: tt.labelLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            child: Text(actionLabel!),
          ),
      ],
    );
  }
}

/// Título grande de pantalla (26/800, como "Biblioteca", "Progreso").
class ScreenTitle extends StatelessWidget {
  const ScreenTitle(this.text, {super.key, this.subtitle});

  final String text;

  /// Línea pequeña encima del título (p. ej. "Buenas noches").
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (subtitle != null) Text(subtitle!, style: tt.bodyMedium?.copyWith(color: context.palette.text2)),
        Text(text, style: tt.headlineMedium),
      ],
    );
  }
}
