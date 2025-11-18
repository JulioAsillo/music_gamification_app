import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

/// Pantalla de biblioteca de música
class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Biblioteca',
          style: AppTextStyles.heading2(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implementar búsqueda
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // TODO: Implementar filtros
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.library_music,
              size: 80,
              color: AppColors.accentDark.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Biblioteca de Música',
              style: AppTextStyles.heading2(context),
            ),
            const SizedBox(height: 8),
            Text(
              'Tus canciones aparecerán aquí',
              style: AppTextStyles.bodyMedium(context),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                // TODO: Implementar escaneo de música
              },
              icon: const Icon(Icons.folder_open),
              label: const Text('Escanear Música'),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Ir a reproductor
        },
        child: const Icon(Icons.play_arrow),
      ),
    );
  }
}
