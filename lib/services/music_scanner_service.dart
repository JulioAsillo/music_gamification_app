import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'metadata_extractor_service.dart';

/// 📂 Estado del escaneo
enum ScanStatus {
  idle,
  scanning,
  completed,
  error,
}

/// 📊 Progreso del escaneo
class ScanProgress {
  final int totalFiles;
  final int scannedFiles;
  final int foundAudioFiles;
  final String currentPath;
  final ScanStatus status;
  final String? errorMessage;

  ScanProgress({
    this.totalFiles = 0,
    this.scannedFiles = 0,
    this.foundAudioFiles = 0,
    this.currentPath = '',
    this.status = ScanStatus.idle,
    this.errorMessage,
  });

  double get progress {
    if (totalFiles == 0) return 0.0;
    return scannedFiles / totalFiles;
  }

  ScanProgress copyWith({
    int? totalFiles,
    int? scannedFiles,
    int? foundAudioFiles,
    String? currentPath,
    ScanStatus? status,
    String? errorMessage,
  }) {
    return ScanProgress(
      totalFiles: totalFiles ?? this.totalFiles,
      scannedFiles: scannedFiles ?? this.scannedFiles,
      foundAudioFiles: foundAudioFiles ?? this.foundAudioFiles,
      currentPath: currentPath ?? this.currentPath,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// 🔍 Servicio para escanear archivos de música en el dispositivo
class MusicScannerService {
  /// Callback para reportar progreso
  final Function(ScanProgress)? onProgress;
  
  /// Callback cuando se encuentra un archivo de audio
  final Function(AudioMetadata)? onAudioFound;

  MusicScannerService({
    this.onProgress,
    this.onAudioFound,
  });

  /// Escanea el dispositivo en busca de archivos de audio
  Future<List<AudioMetadata>> scanDevice() async {
    final List<AudioMetadata> audioFiles = [];
    
    try {
      _reportProgress(ScanProgress(
        status: ScanStatus.scanning,
        currentPath: 'Iniciando escaneo...',
      ));

      // Obtener directorios a escanear
      final directories = await _getMusicDirectories();
      
      if (directories.isEmpty) {
        _reportProgress(ScanProgress(
          status: ScanStatus.error,
          errorMessage: 'No se encontraron directorios para escanear',
        ));
        return [];
      }

      // Contar archivos totales primero (opcional, para mejor UX)
      int totalFiles = 0;
      for (final dir in directories) {
        totalFiles += await _countFiles(dir);
      }

      _reportProgress(ScanProgress(
        status: ScanStatus.scanning,
        totalFiles: totalFiles,
        currentPath: 'Escaneando...',
      ));

      // Escanear cada directorio
      int scannedFiles = 0;
      for (final directory in directories) {
        final files = await _scanDirectory(
          directory,
          onFileScanned: (filePath) {
            scannedFiles++;
            _reportProgress(ScanProgress(
              status: ScanStatus.scanning,
              totalFiles: totalFiles,
              scannedFiles: scannedFiles,
              foundAudioFiles: audioFiles.length,
              currentPath: filePath,
            ));
          },
        );
        
        audioFiles.addAll(files);
      }

      _reportProgress(ScanProgress(
        status: ScanStatus.completed,
        totalFiles: totalFiles,
        scannedFiles: scannedFiles,
        foundAudioFiles: audioFiles.length,
        currentPath: 'Escaneo completado',
      ));

      return audioFiles;
    } catch (e) {
      _reportProgress(ScanProgress(
        status: ScanStatus.error,
        errorMessage: 'Error durante el escaneo: $e',
      ));
      return [];
    }

  }

  /// Obtiene los directorios de música del dispositivo (sin duplicados)
  Future<List<Directory>> _getMusicDirectories() async {
    final Set<String> uniquePaths = {}; // Usar Set para evitar duplicados
    final List<Directory> directories = [];

    if (Platform.isAndroid) {
      final externalStorage = await getExternalStorageDirectory();

      if (externalStorage != null) {
        // Buscar en la raíz del almacenamiento
        final storagePath = externalStorage.path.split('Android')[0];

        // Lista de posibles directorios
        final possibleDirs = [
          Directory('$storagePath/Music'),
          Directory('$storagePath/Download'),
          Directory('$storagePath/Downloads'),
          Directory('$storagePath/Podcasts'),
          Directory('$storagePath/Audiobooks'),
        ];

        for (final dir in possibleDirs) {
          if (await dir.exists()) {
            // Normalizar path (eliminar doble slash, etc.)
            final normalizedPath = dir.path.replaceAll('//', '/');

            // Solo agregar si no existe ya
            if (uniquePaths.add(normalizedPath)) {
              directories.add(Directory(normalizedPath));
              print('📁 Directorio agregado: $normalizedPath');
            } else {
              print('⚠️ Directorio duplicado ignorado: ${dir.path}');
            }
          }
        }
      }
    } else if (Platform.isIOS) {
      final appDir = await getApplicationDocumentsDirectory();
      directories.add(appDir);
    }

    print('📊 Total de directorios únicos: ${directories.length}');
    return directories;
  }


  /// Cuenta archivos en un directorio recursivamente
  Future<int> _countFiles(Directory directory) async {
    int count = 0;
    try {
      await for (final entity in directory.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          count++;
        }
      }
    } catch (e) {
      // Ignorar errores de permisos
    }
    return count;
  }

  /// Escanea un directorio recursivamente
  Future<List<AudioMetadata>> _scanDirectory(
    Directory directory, {
    Function(String)? onFileScanned,
  }) async {
    final List<AudioMetadata> audioFiles = [];

    try {
      await for (final entity in directory.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          final filePath = entity.path;
          onFileScanned?.call(filePath);

          // Verificar si es un archivo de audio soportado
          if (MetadataExtractorService.isSupportedAudioFile(filePath)) {
            final metadata = await MetadataExtractorService.extractMetadata(filePath);
            
            if (metadata != null) {
              audioFiles.add(metadata);
              onAudioFound?.call(metadata);
            }
          }
        }
      }
    } catch (e) {
      print('❌ Error escaneando directorio ${directory.path}: $e');
    }

    return audioFiles;
  }

  /// Reporta el progreso del escaneo
  void _reportProgress(ScanProgress progress) {
    onProgress?.call(progress);
  }

  /// Escanea un directorio específico
  Future<List<AudioMetadata>> scanSpecificDirectory(String path) async {
    final directory = Directory(path);
    
    if (!await directory.exists()) {
      return [];
    }

    _reportProgress(ScanProgress(
      status: ScanStatus.scanning,
      currentPath: path,
    ));

    final files = await _scanDirectory(directory);

    _reportProgress(ScanProgress(
      status: ScanStatus.completed,
      foundAudioFiles: files.length,
    ));

    return files;
  }

}
