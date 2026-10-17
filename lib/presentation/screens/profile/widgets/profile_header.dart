import 'package:flutter/material.dart';

import '../../../../core/utils/formatters.dart';
import '../../../widgets/ui/ui.dart';
import 'profile_avatar.dart';

/// Encabezado de Perfil: avatar, nombre, nivel y canciones escuchadas.
/// Al tocarlo se edita el nombre.
class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    super.key,
    required this.name,
    required this.level,
    required this.tracksPlayed,
    required this.onEdit,
  });

  final String name;
  final int level;
  final int tracksPlayed;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final tt = Theme.of(context).textTheme;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onEdit,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            ProfileAvatar(name: name),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name.isEmpty ? 'Toca para poner tu nombre' : name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: tt.headlineMedium?.copyWith(fontSize: name.isEmpty ? 18 : 24),
                  ),
                  Text(
                    'Nivel $level · ${Fmt.songs(tracksPlayed)} escuchadas',
                    style: tt.bodySmall,
                  ),
                ],
              ),
            ),
            Icon(Icons.edit_outlined, size: 20, color: p.text2),
          ],
        ),
      ),
    );
  }
}
