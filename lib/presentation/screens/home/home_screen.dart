import 'package:flutter/material.dart';

import '../../widgets/ui/ui.dart';

/// Inicio (Fase 3: marcador de posición; contenido completo en la Fase 5).
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 20, 16, 16),
          child: ScreenTitle('Tu música hoy', subtitle: 'Hola'),
        ),
      ),
    );
  }
}
