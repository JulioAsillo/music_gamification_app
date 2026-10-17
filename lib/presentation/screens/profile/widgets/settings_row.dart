import 'package:flutter/material.dart';

import '../../../widgets/ui/ui.dart';

/// Fila de ajustes de Perfil: icono, título, subtítulo y chevron.
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
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
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(subtitle),
      trailing: Icon(Icons.chevron_right_rounded, color: p.text2),
      onTap: onTap,
    );
  }
}
