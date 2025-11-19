import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import '../../data/database/app_database.dart';
import '../../data/database/daos/tracks_dao.dart';
import '../../services/music_scanner_service.dart';
import '../../services/metadata_extractor_service.dart';
import '../../services/permission_service.dart';
import '../../data/database/tables/tracks_table.dart';
import 'repositories_provider.dart';

/// 🎵 Estado del escaneo de música
class MusicScannerState {
  final List<AudioMetadata> songs;
  final ScanProgress progress;
  final bool hasPermission;
  final bool isScanning;
  final bool isSavingToDb;
  final String? errorMessage;

  MusicScannerState({
    this.songs = const [],
    ScanProgress? progress,
    this.hasPermission = false,
    this.isScanning = false,
    this.isSavingToDb = false,
    this.errorMessage,
  }) : progress = progress ?? ScanProgress();

  MusicScannerState copyWith({
    List<AudioMetadata>? songs,
    ScanProgress? progress,
    bool? hasPermission,
    bool? isScanning,
    bool? isSavingToDb,
    String? errorMessage,
  }) {
    return MusicScannerState(
      songs: songs ?? this.songs,
      progress: progress ?? this.progress,
      hasPermission: hasPermission ?? this.hasPermission,
      isScanning: isScanning ?? this.isScanning,
      isSavingToDb: isSavingToDb ?? this.isSavingToDb,
      errorMessage: errorMessage,
    );
  }
}

/// 📦 Notifier para el estado del escaneo
class MusicScannerNotifier extends StateNotifier<MusicScannerState> {
  final TracksDao tracksDao;

  MusicScannerNotifier(this.tracksDao) : super(MusicScannerState()) {
    _checkPermissions();
  }

  /// Verifica permisos al inicializar
  Future<void> _checkPermissions() async {
    final hasPermission = await PermissionService.hasStoragePermission();
    state = state.copyWith(hasPermission: hasPermission);
  }

  /// Solicita permisos de almacenamiento
  Future<bool> requestPermissions() async {
    final granted = await PermissionService.requestStoragePermission();
    state = state.copyWith(hasPermission: granted);

    if (!granted) {
      state = state.copyWith(
        errorMessage: 'Se necesitan permisos de almacenamiento para escanear música',
      );
    }

    return granted;
  }

  /// Inicia el escaneo de música
  Future<void> startScan() async {
    if (state.isScanning) return;

    // Verificar permisos
    if (!state.hasPermission) {
      final granted = await requestPermissions();
      if (!granted) return;
    }

    state = state.copyWith(
      isScanning: true,
      songs: [],
      errorMessage: null,
    );

    final scanner = MusicScannerService(
      onProgress: (progress) {
        state = state.copyWith(progress: progress);
      },
      onAudioFound: (metadata) {
        // Agregar canción a la lista en tiempo real
        final updatedSongs = [...state.songs, metadata];
        state = state.copyWith(songs: updatedSongs);
      },
    );

    try {
      final songs = await scanner.scanDevice();

      state = state.copyWith(
        songs: songs,
        isScanning: false,
        progress: ScanProgress(
          status: ScanStatus.completed,
          totalFiles: state.progress.totalFiles,
          scannedFiles: state.progress.scannedFiles,
          foundAudioFiles: songs.length,
        ),
      );

      // ✅ GUARDAR EN BASE DE DATOS
      await _saveTracksToDatabase(songs);

    } catch (e) {
      state = state.copyWith(
        isScanning: false,
        errorMessage: 'Error al escanear: $e',
        progress: ScanProgress(
          status: ScanStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  /// ✅ NUEVO: Guardar tracks en la base de datos
  Future<void> _saveTracksToDatabase(List<AudioMetadata> songs) async {
    if (songs.isEmpty) return;

    state = state.copyWith(isSavingToDb: true);

    try {
      int savedCount = 0;
      int duplicateCount = 0;

      for (final song in songs) {
        // Verificar si ya existe
        final existing = await tracksDao.getTrackByPath(song.filePath);

        if (existing == null) {
          // Insertar nuevo track
          final companion = TracksTableCompanion.insert(
            filePath: song.filePath,
            title: song.title,
            artist: song.artist,
            album: song.album,
            genre: song.genre ?? 'Desconocido',
            durationMs: song.duration != null ? song.duration! * 1000 : 0,
            addedAt: DateTime.now(),
            coverArtPath: drift.Value(null),
          );

          await tracksDao.insertTrack(companion);
          savedCount++;
        } else {
          duplicateCount++;
        }
      }

      print('✅ Guardados: $savedCount tracks');
      print('⚠️ Duplicados omitidos: $duplicateCount tracks');

    } catch (e) {
      print('❌ Error guardando tracks: $e');
      state = state.copyWith(
        errorMessage: 'Error guardando canciones: $e',
      );
    } finally {
      state = state.copyWith(isSavingToDb: false);
    }
  }

  /// Escanea un directorio específico
  Future<void> scanDirectory(String path) async {
    if (state.isScanning) return;

    state = state.copyWith(
      isScanning: true,
      errorMessage: null,
    );

    final scanner = MusicScannerService(
      onProgress: (progress) {
        state = state.copyWith(progress: progress);
      },
      onAudioFound: (metadata) {
        final updatedSongs = [...state.songs, metadata];
        state = state.copyWith(songs: updatedSongs);
      },
    );

    try {
      final songs = await scanner.scanSpecificDirectory(path);

      state = state.copyWith(
        songs: [...state.songs, ...songs],
        isScanning: false,
      );

      // Guardar en DB
      await _saveTracksToDatabase(songs);
    } catch (e) {
      state = state.copyWith(
        isScanning: false,
        errorMessage: 'Error al escanear directorio: $e',
      );
    }
  }

  /// Limpia la lista de canciones
  void clearSongs() {
    state = state.copyWith(
      songs: [],
      progress: ScanProgress(),
    );
  }

  /// Abre configuración de la app
  Future<void> openSettings() async {
    await PermissionService.openAppSettings();
  }
}

/// 🎵 Provider del escaneador de música (ACTUALIZADO)
final musicScannerProvider = StateNotifierProvider<MusicScannerNotifier, MusicScannerState>(
      (ref) {
    final tracksRepository = ref.watch(tracksRepositoryProvider);
    return MusicScannerNotifier(tracksRepository);
  },
);
