# Music Gamification App — Roadmap del rediseño

> Repo: `JulioAsillo/music_gamification_app` · Stack: Flutter + Riverpod + Drift + just_audio/audio_service
> Diseño de referencia: canvas **"Music App – Navegación"** (10 pantallas: Prototipo, Inicio, Biblioteca, Progreso–Estadísticas, Progreso–Logros, Perfil oscuro, Perfil claro + Esmeralda, Reproductor, Escanear bottom sheet, Biblioteca claro + Rosa).

## Decisión base

**No se empieza de cero.** El rediseño afecta la capa de presentación; la capa de datos y servicios se mantiene.

| Capa | Decisión |
|---|---|
| `lib/data/` (Drift: tablas, DAOs, repositorios, modelos) | Mantener |
| `lib/domain/services/` (AudioHandler + `audio_service`) | Mantener |
| `lib/services/` (scanner, metadata, permisos) | Mantener |
| `lib/presentation/providers/` | Reutilizar, migrados a Riverpod 3 |
| `lib/presentation/screens/` y `widgets/` | Rehacer según el diseño nuevo |

Regla de trabajo: **cada fase termina con la app compilando y usable**. Una rama por fase (`fase-N-...`), merge a `main` al cerrar.

---

## Fase 1 · Dependencias y base técnica
Sin cambios visuales.
- Quitar paquetes sin uso: `just_audio_background` (choca con `audio_service`), `lottie`, `shimmer`, `cached_network_image`, `flutter_svg`, `uuid`, `flutter_local_notifications`, `drift_flutter`.
- Actualizar: Riverpod 3 (`flutter_riverpod 3.4`, `riverpod_annotation 4`, `riverpod_generator 4`), `go_router 18`, `fl_chart 1.2`, `permission_handler 13`, `drift 2.35`, `flutter_lints 6`.
- `riverpod_lint` pasa a `plugins:` en `analysis_options.yaml`.
- Providers generados: `XxxRef ref` → `Ref ref`.
- `StateProvider` / `StateNotifierProvider` → import `flutter_riverpod/legacy.dart` (migración a `Notifier` se hace al reescribir cada pantalla).
- Regenerar código: `dart run build_runner build -d`.

**Cierre:** `flutter analyze` sin errores, la app reproduce, escanea y guarda igual que antes.

## Fase 2 · Sistema de diseño
- `AppTheme` nuevo: modos **Claro / Oscuro / Sistema**.
- Color de acento configurable (Índigo, Esmeralda, Ámbar, Rosa, Cian, Rojo…) persistido.
- Componentes reutilizables: cards, chips/tabs segmentados, barra de XP, portada con gradiente, tile de canción, badge de racha.

**Cierre:** la app actual ya usa el tema nuevo y el acento cambia en vivo.

## Fase 3 · Navegación
- `go_router` con `StatefulShellRoute` → 4 pestañas: **Inicio · Biblioteca · Progreso · Perfil**.
- Bottom nav nuevo (ítem activo en píldora con el acento).
- Mini-player persistente sobre el nav.
- Reproductor completo como ruta modal (desde el mini-player).
- Escanear como bottom sheet.
- Migrar `currentTabIndexProvider` (lo reemplaza el router).

**Cierre:** la app navega como el prototipo, aunque algunas pantallas sigan siendo las antiguas.

## Fase 4 · Biblioteca y Reproductor
- Biblioteca: buscador, pestañas **Canciones / Artistas / Álbumes / Favoritos**, contador "N canciones · Xh Ym", botón **Aleatorio**, canción en reproducción resaltada.
- Reproductor: portada grande, "Reproduciendo desde Biblioteca", barra de progreso, controles, feedback "+12 XP por esta canción · racha de N días activa".
- Migrar `searchQueryProvider`, `sortTypeProvider`, `currentFilterProvider`, `FavoritesNotifier`, `MusicPlayerNotifier` a `Notifier`.

## Fase 5 · Inicio y Progreso
- Inicio: saludo por hora, badge de racha, card de Nivel + barra XP ("faltan N para el nivel X"), **Continuar escuchando** (carrusel), **Próximo logro**.
- Progreso con tabs **Estadísticas / Logros**:
  - Estadísticas: Nivel · XP, Racha, Tiempo total, gráfico **Esta semana** (`fl_chart`, barras L–D, hoy resaltado).
  - Logros: cards desbloqueadas (borde dorado, "Desbloqueado") y en progreso (barra + %), con XP.
- Consultas nuevas en DAOs si faltan: historial reciente, minutos por día de la semana.

## Fase 6 · Perfil y pulido
- Perfil: avatar + nivel + canciones escuchadas, **Apariencia** (modo + acento), Carpetas de música, Almacenamiento y caché, Acerca de.
- Estados vacíos, transiciones, animación de XP ganado, revisión claro/oscuro con todos los acentos.
- Migrar `MusicScannerNotifier` y `PlaylistsNotifier` a `Notifier` y quitar el import `legacy.dart`.

---

## Tarea aparte · Actualizar toolchain Android
Flutter 3.47 avisa que pronto dejará de soportar la configuración actual:
- Gradle 8.14 → **9.1+**
- Android Gradle Plugin 8.11.1 → **9.0.1+**
- Kotlin 2.2.20 → **2.3.20+**
- Al hacerlo: volver a `permission_handler: ^13.x` (requiere compileSdk 37) y ya no hará falta forzar JDK 21.

Hacerlo entre fases, con la app estable, en su propia rama.

---

## Estado

Todo el rediseño vive en la rama `fase-2-sistema-diseno` (un commit por fase).

| Fase | Estado |
|---|---|
| 1 · Dependencias | ✅ En `master` |
| 2 · Sistema de diseño | ✅ Probada en emulador |
| 3 · Navegación | Entregada, pendiente de probar |
| 4 · Biblioteca y Reproductor | Entregada, pendiente de probar |
| 5 · Inicio y Progreso (+ gamificación) | Entregada, pendiente de probar |
| 6 · Perfil y pulido | Entregada, pendiente de probar |
| Toolchain Android (Gradle 9 / AGP 9) | Pendiente, tarea aparte |

Detalle de las fases 3–6 y checklist de prueba: `docs/FASES-3-6.md`.
