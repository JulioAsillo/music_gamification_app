import 'package:flutter/material.dart';

import '../../../widgets/ui/ui.dart';

/// Avatar circular con la inicial del nombre (o una nota si está vacío).
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({super.key, required this.name, this.radius = 26});

  final String name;
  final double radius;

  static String initialOf(String name) {
    final clean = name.trim();
    return clean.isEmpty ? '♪' : clean.characters.first.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return CircleAvatar(
      radius: radius,
      backgroundColor: p.accent,
      child: Text(
        initialOf(name),
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: p.onAccent,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}
