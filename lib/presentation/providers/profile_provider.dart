import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'theme_provider.dart';

const _kDisplayNameKey = 'display_name';

/// Nombre que se muestra en Perfil (y su inicial en el avatar). Se persiste.
final displayNameProvider = NotifierProvider<DisplayNameNotifier, String>(DisplayNameNotifier.new);

class DisplayNameNotifier extends Notifier<String> {
  @override
  String build() => ref.watch(sharedPreferencesProvider).getString(_kDisplayNameKey) ?? '';

  /// Guarda el nombre limpio: sin espacios sobrantes ni repetidos, máximo 30
  /// caracteres. Un nombre vacío borra el nombre guardado.
  void set(String name) {
    final clean = name.trim().replaceAll(RegExp(r'\s+'), ' ');
    final limited = clean.length > 30 ? clean.substring(0, 30).trimRight() : clean;
    state = limited;
    final prefs = ref.read(sharedPreferencesProvider);
    if (limited.isEmpty) {
      prefs.remove(_kDisplayNameKey);
    } else {
      prefs.setString(_kDisplayNameKey, limited);
    }
  }
}
