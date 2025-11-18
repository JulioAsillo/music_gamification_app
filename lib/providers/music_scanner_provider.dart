import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/music_scanner_service.dart';
import '../services/metadata_extractor_service.dart';
import '../services/permission_service.dart';

/// 🎵 Estado del escaneo de música
class MusicScannerState {
  final List<AudioMetadata> songs;
  final ScanProgress progress;
  final bool hasPermission;
  final bool isScanning;
  final String? errorMessage;

  MusicScannerState({
    this.songs = const [],
    ScanProgress? progress,
    this.hasPermission = false,
    this.isScanning = false,
    this.errorMessage,
  }) : progress = progress ?? ScanProgress();

  MusicScannerState copyWith({
    List<AudioMetadata>? songs,
    ScanProgress? progress,
    bool? hasPermission,
    bool? isScanning,
    String? errorMessage,
  }) {
    return MusicScannerState(
      songs: songs ?? this.songs,
      progress: progress ?? this.progress,
      hasPermission: hasPermission ?? this.hasPermission,
      isScanning: isScanning ?? this.isScanning,
      errorMessage: errorMessage,
    );
  }
}

/// 📦 Notifier para el estado del escaneo
class MusicScannerNotifier extends StateNotifier<MusicScannerState> {
  MusicScannerNotifier() : super(MusicScannerState()) {
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

/// 🎵 Provider del escaneador de música
final musicScannerProvider = StateNotifierProvider<MusicScannerNotifier, MusicScannerState>(
  (ref) => MusicScannerNotifier(),
);

/// 📊 Provider para el progreso del escaneo
final scanProgressProvider = Provider<ScanProgress>((ref) {
  return ref.watch(musicScannerProvider).progress;
});

/// 🎶 Provider para la lista de canciones encontradas
final scannedSongsProvider = Provider<List<AudioMetadata>>((ref) {
  return ref.watch(musicScannerProvider).songs;
});

/// 🔐 Provider para verificar si hay permisos
final hasStoragePermissionProvider = Provider<bool>((ref) {
  return ref.watch(musicScannerProvider).hasPermission;
});

/// ⏳ Provider para verificar si está escaneando
final isScanningProvider = Provider<bool>((ref) {
  return ref.watch(musicScannerProvider).isScanning;
});
