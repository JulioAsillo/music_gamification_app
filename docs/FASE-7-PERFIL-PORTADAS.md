# Fase 7 · Perfil, portadas y refactor

Rama: `fase-7-perfil-portadas` (sale de `fase-2-sistema-diseno`).

## Perfil · editar nombre
- La hoja de edición se abre en el **navigator raíz** (`useRootNavigator: true`): tapa mini-player y barra, y recibe el `viewInsets` real del teclado. Antes se abría dentro del `Navigator` de la pestaña, debajo del `Scaffold` del shell.
- El `TextField` ya no está dentro de un `ListenableBuilder` que lo reconstruía en cada tecla; solo la vista previa del avatar escucha al controller.
- Foco pedido después del primer frame (no `autofocus` durante la animación).
- Perfil dividido en `widgets/` (`ProfileHeader`, `ProfileAvatar`, `EditNameSheet`, `SettingsRow`) y la limpieza de caché movida a `CacheService`.

## Portadas embebidas
**Hallazgos:**
1. Las carátulas se guardaban como `cover_<milisegundos>.jpg`; varias canciones guardadas en el mismo milisegundo **compartían archivo** → portadas cruzadas.
2. Al re-escanear, las canciones ya existentes se saltaban: si no tenían carátula, nunca la recuperaban.
3. El estado del escáner retenía los bytes de **todas** las imágenes en memoria.
4. La lectura de etiquetas corría en el hilo de UI.

**Cambios:**
- `CoverArtService`: nombre por hash FNV-1a del contenido + tamaño (sin colisiones, un archivo por álbum), extensión real (jpg/png/webp/gif). Prefiere la imagen "portada frontal" si el archivo trae varias.
- `MetadataExtractorService.extractMetadata` corre en `Isolate.run` y guarda la carátula ahí mismo; `AudioMetadata` lleva `coverArtPath`, no bytes.
- Re-escanear **recupera carátulas** de canciones existentes sin portada (o cuyo archivo se borró). El sheet muestra "N carátulas recuperadas".
- `TrackCover`: fundido al cargar, sombra en portadas grandes, gradiente mientras carga o si falla.
- Reproductor: fondo con la carátula desenfocada (o el degradado de acento si no hay), con fundido al cambiar de canción.
- Detalle de playlist usa `TrackCover` (sin `File.existsSync()` en el `build`).

> Para ver las portadas de una biblioteca ya escaneada: **Perfil → Carpetas de música → Escanear**.

## Refactor
- `MusicScannerNotifier` migrado a `Notifier` (Riverpod 3), estado con contador en vez de lista de canciones.
- Eliminados sin uso: `play_sessions_provider.dart`, `session_preset.dart` (modelo), `permission_handler_service.dart`, `data_utils.dart`.
- `print` → `debugPrint` en toda la app.
- `AppInfo` centraliza nombre y versión.

## Checklist de prueba
```powershell
git fetch; git checkout fase-7-perfil-portadas
flutter pub get
dart run build_runner build -d
flutter analyze
```
1. Perfil → toca el nombre → escribe (el texto y la inicial del avatar cambian) → Guardar.
2. Biblioteca → buscador: confirma que también acepta texto.
3. Perfil → Carpetas de música → Escanear → "N carátulas recuperadas".
4. Biblioteca, Inicio y mini-player muestran las portadas; Reproductor con fondo desenfocado.
