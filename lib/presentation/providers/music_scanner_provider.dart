import 'package:drift/drift.dart' as drift;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database/app_database.dart';
import '../../data/database/daos/tracks_dao.dart';
import '../../services/cover_art_service.dart';
import '../../services/metadata_extractor_service.dart';
import '../../services/music_scanner_service.dart';
import '../../services/permission_service.dart';
import 'database_provider.dart';

/// Estado del escaneo de música.
@immutable
class MusicScannerState {
  MusicScannerState({
    this.foundCount = 0,
    ScanProgress? progress,
    this.hasPermission = false,
    this.isScanning = false,
    this.isSavingToDb = false,
    this.lastResult,
    this.errorMessage,
  }) : progress = progress ?? ScanProgress();

  /// Canciones encontradas en el escaneo en curso (solo el número: la lista
  /// completa no hace falta en la UI y ocupaba memoria).
  final int foundCount;
  final ScanProgress progress;
  final bool hasPermission;
  final bool isScanning;
  final bool isSavingToDb;

  /// Resumen del último guardado en la base de datos.
  final ScanSaveResult? lastResult;
  final String? errorMessage;

  bool get isBusy => isScanning || isSavingToDb;

  MusicScannerState copyWith({
    int? foundCount,
    ScanProgress? progress,
    bool? hasPermission,
    bool? isScanning,
    bool? isSavingToDb,
    ScanSaveResult? lastResult,
    String? errorMessage,
    bool clearError = false,
  }) {
    return MusicScannerState(
      foundCount: foundCount ?? this.foundCount,
      progress: progress ?? this.progress,
      hasPermission: hasPermission ?? this.hasPermission,
      isScanning: isScanning ?? this.isScanning,
      isSavingToDb: isSavingToDb ?? this.isSavingToDb,
      lastResult: lastResult ?? this.lastResult,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// Resultado de guardar un escaneo: canciones nuevas, ya existentes y
/// carátulas recuperadas para canciones que ya estaban en la biblioteca.
@immutable
class ScanSaveResult {
  const ScanSaveResult({this.added = 0, this.existing = 0, this.coversRecovered = 0});

  final int added;
  final int existing;
  final int coversRecovered;
}

/// Escaneo del dispositivo y guardado en la base de datos.
final musicScannerProvider =
    NotifierProvider<MusicScannerNotifier, MusicScannerState>(MusicScannerNotifier.new);

class MusicScannerNotifier extends Notifier<MusicScannerState> {
  TracksDao get _tracksDao => ref.read(appDatabaseProvider).tracksDao;

  @override
  MusicScannerState build() {
    Future.microtask(_checkPermissions);
    return MusicScannerState();
  }

  Future<void> _checkPermissions() async {
    final granted = await PermissionService.hasStoragePermission();
    if (!ref.mounted) return;
    state = state.copyWith(hasPermission: granted);
  }

  /// Solicita permisos de almacenamiento.
  Future<bool> requestPermissions() async {
    final granted = await PermissionService.requestStoragePermission();
    if (!ref.mounted) return granted;
    state = state.copyWith(
      hasPermission: granted,
      errorMessage: granted ? null : 'Se necesitan permisos de almacenamiento para escanear música',
      clearError: granted,
    );
    return granted;
  }

  /// Escanea todo el almacenamiento.
  Future<void> startScan() => _scan((scanner) => scanner.scanDevice());

  /// Escanea un directorio específico.
  Future<void> scanDirectory(String path) => _scan((scanner) => scanner.scanSpecificDirectory(path));

  Future<void> _scan(Future<List<AudioMetadata>> Function(MusicScannerService) run) async {
    if (state.isBusy) return;
    if (!state.hasPermission && !await requestPermissions()) return;

    // Estado limpio para este escaneo (sin resultado ni error anteriores).
    state = MusicScannerState(hasPermission: state.hasPermission, isScanning: true);

    final scanner = MusicScannerService(
      onProgress: (progress) {
        if (ref.mounted) state = state.copyWith(progress: progress);
      },
      onAudioFound: (_) {
        if (ref.mounted) state = state.copyWith(foundCount: state.foundCount + 1);
      },
    );

    try {
      final songs = await run(scanner);
      if (!ref.mounted) return;
      state = state.copyWith(
        isScanning: false,
        foundCount: songs.length,
        progress: state.progress.copyWith(status: ScanStatus.completed, foundAudioFiles: songs.length),
      );
      await _saveTracks(songs);
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(
        isScanning: false,
        errorMessage: 'Error al escanear: $e',
        progress: ScanProgress(status: ScanStatus.error, errorMessage: e.toString()),
      );
    }
  }

  /// Inserta las canciones nuevas y, para las que ya existían, recupera la
  /// carátula si antes no tenían (o el archivo de la carátula se borró).
  Future<void> _saveTracks(List<AudioMetadata> songs) async {
    if (songs.isEmpty) return;
    state = state.copyWith(isSavingToDb: true);

    var added = 0;
    var existingCount = 0;
    var coversRecovered = 0;
    final now = DateTime.now();

    try {
      for (final song in songs) {
        final existing = await _tracksDao.getTrackByPath(song.filePath);

        if (existing == null) {
          await _tracksDao.insertTrack(TracksTableCompanion.insert(
            filePath: song.filePath,
            title: song.title,
            artist: song.artist,
            album: song.album,
            genre: song.genre ?? 'Desconocido',
            durationMs: (song.duration ?? 0) * 1000,
            addedAt: now,
            coverArtPath: drift.Value(song.coverArtPath),
          ));
          added++;
          continue;
        }

        existingCount++;
        final newCover = song.coverArtPath;
        if (newCover != null &&
            newCover != existing.coverArtPath &&
            !CoverArtService.existsSync(existing.coverArtPath)) {
          await _tracksDao.updateCoverArt(existing.id, newCover);
          coversRecovered++;
        }
      }
      debugPrint('Escaneo guardado: $added nuevas, $existingCount existentes, '
          '$coversRecovered carátulas recuperadas');
      if (!ref.mounted) return;
      state = state.copyWith(
        lastResult: ScanSaveResult(added: added, existing: existingCount, coversRecovered: coversRecovered),
      );
    } catch (e) {
      debugPrint('Error guardando tracks: $e');
      if (ref.mounted) state = state.copyWith(errorMessage: 'Error guardando canciones: $e');
    } finally {
      if (ref.mounted) state = state.copyWith(isSavingToDb: false);
    }
  }

  /// Vuelve al estado inicial (conserva el permiso).
  void reset() {
    state = MusicScannerState(hasPermission: state.hasPermission);
  }

  /// Abre los ajustes del sistema para conceder el permiso.
  Future<void> openSettings() => PermissionService.openSettings();
}
