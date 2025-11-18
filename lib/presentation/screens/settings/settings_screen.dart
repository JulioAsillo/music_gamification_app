import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../providers/theme_provider.dart';

/// Pantalla de ajustes
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Ajustes',
          style: AppTextStyles.heading2(context),
        ),
      ),
      body: ListView(
        children: [
          // Sección de Apariencia
          _SectionHeader(title: 'Apariencia'),
          SwitchListTile(
            title: const Text('Modo Oscuro'),
            subtitle: const Text('Cambiar entre tema claro y oscuro'),
            value: themeMode == ThemeMode.dark,
            onChanged: (value) {
              ref.read(themeModeNotifierProvider.notifier).toggleTheme();
            },
          ),

          const Divider(),

          // Sección de Música
          _SectionHeader(title: 'Música'),
          ListTile(
            leading: const Icon(Icons.folder_open),
            title: const Text('Escanear Música'),
            subtitle: const Text('Buscar canciones en el dispositivo'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // TODO: Implementar escaneo
            },
          ),
          ListTile(
            leading: const Icon(Icons.refresh),
            title: const Text('Actualizar Biblioteca'),
            subtitle: const Text('Re-escanear archivos de música'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // TODO: Implementar actualización
            },
          ),

          const Divider(),

          // Sección de Datos
          _SectionHeader(title: 'Datos'),
          ListTile(
            leading: const Icon(Icons.delete_forever),
            title: const Text('Limpiar Caché'),
            subtitle: const Text('Eliminar archivos temporales'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // TODO: Implementar limpieza
            },
          ),

          const Divider(),

          // Sección de Información
          _SectionHeader(title: 'Información'),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('Acerca de'),
            subtitle: const Text('Versión 1.0.0'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // TODO: Mostrar información de la app
            },
          ),
        ],
      ),
    );
  }
}

/// Header de sección
class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: AppTextStyles.heading3(context),
      ),
    );
  }
}
