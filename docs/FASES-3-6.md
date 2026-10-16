# Fases 3 a 6 · Navegación, pantallas y gamificación

Rama: `fase-2-sistema-diseno` (un commit por fase).

## Fase 3 · Navegación
- `go_router` con `StatefulShellRoute.indexedStack` (`lib/core/router/app_router.dart`): **Inicio · Biblioteca · Progreso · Perfil**. Cada pestaña conserva su scroll y su pila; tocar la pestaña activa vuelve a su raíz.
- `AppShell`: `NavigationBar` con indicador en el acento + **mini-player persistente** encima.
- **Reproductor** como ruta de pantalla completa (`/reproductor`) que sube desde abajo, con Hero de la portada.
- **Escanear** como bottom sheet (`showScanSheet`), accesible desde Biblioteca y Perfil.
- Eliminados: `MainScreen`, `CustomBottomNavBar`, `MusicScanScreen`.

## Fase 4 · Biblioteca y Reproductor
- Biblioteca: buscador que filtra la pestaña activa, chips **Canciones / Artistas / Álbumes / Favoritas / Playlists**, fila "N canciones · X h Y min" + **Aleatorio**, botón de ordenar/filtrar (usa la `FiltersScreen` existente) y estado vacío con botón de escanear.
- Artistas (lista) y Álbumes (grilla) abren `TrackCollectionScreen`.
- Las **Playlists** pasan de pestaña propia a chip dentro de Biblioteca (el diseño tiene 4 pestañas). Crear, abrir y editar siguen igual.
- Mantener presionada una canción → menú: reproducir, agregar a la cola, favorita, agregar a playlist.
- Reproductor: fondo degradado con el acento, portada grande, favorito, barra de progreso arrastrable, aleatorio / anterior / play / siguiente / repetir, "+12 XP por esta canción · racha de N días" y cola.
- Eliminados: `SearchScreen`, `FavoritesScreen`, `GroupedLibraryScreen`, `PlaylistsScreen` (absorbidos por Biblioteca).

## Fase 5 · Inicio, Progreso y gamificación
**Hallazgo:** el registro de estadísticas estaba como `TODO` en `MusicPlayerNotifier`, los logros nunca se creaban en la BD y el timer contaba el tiempo de escucha de más. Se implementó:

- `GamificationService` (`lib/domain/services/`):
  - Registra **tramos de escucha** (sesión en `play_sessions`, tiempo total, tiempo por género).
  - **Racha**: +1 si la última escucha fue ayer, se mantiene si fue hoy, vuelve a 1 si hubo un hueco.
  - **+12 XP** por canción escuchada (30 % o 30 s, lo que ocurra primero) y **nivel** = ⌊√(XP/1000)⌋ + 1.
  - **8 logros** sembrados al iniciar: Primera canción, Maratonista (10 h), Racha de 7 días, Explorador (5 géneros), Ecléctico (20 artistas), Búho nocturno, Coleccionista (1000), Imparable (30 días). Al desbloquearse suman su XP.
- `MusicPlayerNotifier`: seguimiento por tramos (al pausar, al cambiar de canción y cada 30 s).
- **Inicio**: saludo según la hora, racha, tarjeta de nivel, "Continuar escuchando" (o "Agregadas recientemente" sin historial), "Próximo logro".
- **Progreso**: Estadísticas (nivel + barra, racha, tiempo total, barras de la semana, top géneros) y Logros.

> El progreso se cuenta **desde ahora**: lo escuchado antes de esta versión no tenía registro.

## Fase 6 · Perfil y pulido
- **Perfil**: avatar con inicial (toca para poner tu nombre), nivel y canciones escuchadas, Apariencia (modo + acento), Carpetas de música, Almacenamiento y caché (borra temporales; no toca música ni estadísticas), Acerca de.
- Aviso al **desbloquear un logro** (con botón "Ver") y al **subir de nivel**.
- Eliminados: `SettingsScreen`, `StatsScreen`, `AchievementsScreen`, `DesignPreviewScreen`.

## Pendiente conocido
- `PlaylistDetailScreen`, sus diálogos y `FiltersScreen` funcionan pero conservan su estilo anterior (toman el tema, no todos los colores del acento).
- Quedan avisos `avoid_print` y `withOpacity` en archivos no rediseñados.
- Toolchain Android (Gradle 9 / AGP 9 / Kotlin 2.3) como tarea aparte.

## Checklist de prueba
```powershell
git pull
flutter pub get
dart run build_runner build
flutter analyze
```
1. Abre la app → **Inicio** (sin música: tarjeta "Empieza agregando tu música").
2. **Biblioteca → escanear** → conceder permiso → "N canciones encontradas" → Listo.
3. Recorre los chips; busca algo; abre un artista y un álbum; **Aleatorio**.
4. Reproduce una canción: aparece el **mini-player**; cambia de pestaña (sigue ahí); tócalo → **reproductor**.
5. Deja sonar ≥ 30 s → Progreso: canciones +1, XP +12 (+50 por "Primera canción" con su aviso).
6. **Progreso**: barra de hoy en la semana, logros con progreso.
7. **Perfil**: pon tu nombre, cambia modo y acento, cierra y reabre la app (debe recordarlos).
