import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'theme_provider.dart';

const _kDisplayNameKey = 'display_name';

/// Nombre que se muestra en Perfil (y su inicial en el avatar). Se persiste.
final displayNameProvider = NotifierProvider<DisplayNameNotifier, String>(DisplayNameNotifier.new);

class DisplayNameNotifier extends Notifier<String> {
  @override
  String build() => ref.watch(sharedPreferencesProvider).getString(_kDisplayNameKey) ?? '';

  void set(String name) {
    final clean = name.trim();
    state = clean;
    ref.read(sharedPreferencesProvider).setString(_kDisplayNameKey, clean);
  }
}
