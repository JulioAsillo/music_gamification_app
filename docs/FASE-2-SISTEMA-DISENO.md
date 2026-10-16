# Fase 2 · Sistema de diseño

Rama: `fase-2-sistema-diseno`

## Qué se agregó

### Tokens — `lib/core/theme/app_palette.dart`
- `AppAccent` (enum): Índigo, Esmeralda, Ámbar, Rosa, Cian, Coral. Cada uno con variante oscura, clara y color de texto encima.
- `AppPalette` (`ThemeExtension`): `bg`, `surface`, `card`, `text`, `text2`, `divider`, `accent`, `onAccent` + fijos `gold`, `flame`, `success`, `error` y los 6 gradientes de portada. Valores tomados del canvas "Music App – Navegación".
- Acceso: `context.palette.accent`, `context.palette.text2`, …

### Tema — `lib/core/theme/app_theme.dart`
- `AppTheme.light(accent)` / `AppTheme.dark(accent)`.
- Fuente **Figtree** (Google Fonts), títulos de pantalla 26/800.
- Temas de componentes Material alineados al diseño: botones en píldora, inputs redondeados, bottom sheet 28px, `NavigationBar` con indicador en el acento (se usa en la Fase 3), etc.

### Preferencias — `lib/presentation/providers/theme_provider.dart`
- `themeModeProvider`: Claro / Oscuro / Sistema, persistido.
- `accentColorProvider`: acento elegido, persistido.
- Persistencia con `shared_preferences` (nuevo paquete), cargado en `main()` antes de `runApp` para que no haya parpadeo de tema al abrir.

### Componentes — `lib/presentation/widgets/ui/` (importar `ui.dart`)
| Componente | Dónde se usa en el diseño |
|---|---|
| `AppCard` (tonos `card` / `surface`) | Nivel, estadísticas, logros, Próximo logro |
| `SegmentedTabs` | Progreso (Estadísticas/Logros), Perfil (modo) |
| `AppFilterChip`, `AppFilterChipRow` | Biblioteca (Canciones/Artistas/Álbumes/Favoritas) |
| `XpProgressBar` | XP, progreso de logros |
| `TrackCover` | Portadas (carátula real o gradiente estable por id) |
| `SongTile` | Filas de canciones, resaltado si está sonando |
| `SectionHeader`, `ScreenTitle` | "Continuar escuchando · Ver todo", títulos de pantalla |
| `StreakBadge` | Racha en el header de Inicio |
| `AccentPicker` | Perfil → color de acento |
| `CircleIconButton` | Escanear, cerrar, play |
| `LevelCard` | Tarjeta de Nivel de Inicio |

### Pantallas tocadas
- **Ajustes**: sección Apariencia con modo (3 opciones) + selector de acento.
- **Vista previa del diseño** (Ajustes → Vista previa del diseño): galería con todos los componentes para revisarlos en el celular.

## Limitación conocida
Las pantallas antiguas usan constantes fijas de `AppColors` (p. ej. `AppColors.primary`), así que **no cambian de acento** todavía. Ya toman la fuente Figtree y los colores base del tema. Se corrigen al reescribirlas en las fases 3 a 6.

## Cómo verificar
```powershell
git fetch
git checkout fase-2-sistema-diseno
flutter pub get
dart run build_runner build
flutter analyze
flutter run
```
Prueba: Ajustes → cambiar modo y acento → cerrar y reabrir la app (debe recordar ambos) → abrir "Vista previa del diseño".
