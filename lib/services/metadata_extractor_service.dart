import 'dart:io';
import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:path/path.dart' as path;

/// 🎵 Modelo para metadatos de audio
class AudioMetadata {
  final String filePath;
  final String title;
  final String artist;
  final String album;
  final int? duration; // en segundos
  final int? year;
  final String? genre;
  final int? trackNumber;
  final int fileSize;

  AudioMetadata({
    required this.filePath,
    required this.title,
    required this.artist,
    required this.album,
    this.duration,
    this.year,
    this.genre,
    this.trackNumber,
    required this.fileSize,
  });

  /// Genera un título predeterminado desde el nombre del archivo
  static String _getTitleFromFilename(String filePath) {
    final filename = path.basenameWithoutExtension(filePath);
    // Reemplazar guiones bajos y guiones por espacios
    return filename.replaceAll('_', ' ').replaceAll('-', ' ');
  }
}

/// 🔍 Servicio para extraer metadatos de archivos de audio
class MetadataExtractorService {
  /// Extrae metadatos de un archivo de audio
  static Future<AudioMetadata?> extractMetadata(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return null;

      final fileSize = await file.length();

      try {
        // Intentar leer metadatos con audio_metadata_reader
        final metadata = await readMetadata(file, getImage: false);

        return AudioMetadata(
          filePath: filePath,
          title: metadata.title?.isNotEmpty == true
              ? metadata.title!
              : AudioMetadata._getTitleFromFilename(filePath),
          artist: metadata.artist?.isNotEmpty == true
              ? metadata.artist!
              : 'Artista Desconocido',
          album: metadata.album?.isNotEmpty == true
              ? metadata.album!
              : 'Album Desconocido',
          duration: metadata.duration?.inSeconds,
          year: metadata.year?.year,
          genre: metadata.genres?.isNotEmpty == true
              ? metadata.genres!.first
              : null,
          trackNumber: metadata.trackNumber,
          fileSize: fileSize,
        );
      } catch (e) {
        // Si falla la lectura de metadatos, usar valores predeterminados
        return AudioMetadata(
          filePath: filePath,
          title: AudioMetadata._getTitleFromFilename(filePath),
          artist: 'Artista Desconocido',
          album: 'Album Desconocido',
          duration: null,
          year: null,
          genre: null,
          trackNumber: null,
          fileSize: fileSize,
        );
      }
    } catch (e) {
      print('❌ Error extrayendo metadatos de $filePath: $e');
      return null;
    }
  }

  /// Verifica si un archivo es de audio soportado
  static bool isSupportedAudioFile(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    return ['.mp3', '.m4a', '.aac', '.flac', '.wav', '.ogg'].contains(extension);
  }

  /// Obtiene la extensión del archivo
  static String getFileExtension(String filePath) {
    return path.extension(filePath).toUpperCase().replaceAll('.', '');
  }

  /// Formatea la duración en formato mm:ss
  static String formatDuration(int? seconds) {
    if (seconds == null || seconds <= 0) return '--:--';

    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  /// Formatea el tamaño del archivo
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
