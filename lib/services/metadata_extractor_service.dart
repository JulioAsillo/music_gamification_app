import 'dart:io';
import 'dart:isolate';

import 'package:audio_metadata_reader/audio_metadata_reader.dart' as amr;
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

import 'cover_art_service.dart';

/// Metadatos de un archivo de audio encontrado al escanear.
///
/// La carátula ya viene guardada en disco ([coverArtPath]); no se cargan los
/// bytes de la imagen en memoria (con cientos de canciones eso eran decenas
/// de MB retenidos en el estado del escáner).
@immutable
class AudioMetadata {
  const AudioMetadata({
    required this.filePath,
    required this.title,
    required this.artist,
    required this.album,
    required this.fileSize,
    this.duration,
    this.year,
    this.genre,
    this.trackNumber,
    this.coverArtPath,
  });

  final String filePath;
  final String title;
  final String artist;
  final String album;
  final int? duration; // en segundos
  final int? year;
  final String? genre;
  final int? trackNumber;
  final int fileSize;

  /// Ruta de la carátula extraída del archivo, o `null` si no trae imagen.
  final String? coverArtPath;

  static const unknownArtist = 'Artista Desconocido';
  static const unknownAlbum = 'Album Desconocido';

  /// Título a partir del nombre del archivo (`mi_cancion-01.mp3` → `mi cancion 01`).
  static String titleFromFilename(String filePath) =>
      path.basenameWithoutExtension(filePath).replaceAll('_', ' ').replaceAll('-', ' ');
}

/// Extrae metadatos (y la carátula) de archivos de audio.
abstract final class MetadataExtractorService {
  static const supportedExtensions = {'.mp3', '.m4a', '.aac', '.flac', '.wav', '.ogg'};

  /// Extrae los metadatos de [filePath] en un isolate aparte (leer y
  /// decodificar las etiquetas es CPU + I/O síncrono y trababa la UI durante
  /// el escaneo). Si el archivo trae carátula, se guarda en [coversDir].
  static Future<AudioMetadata?> extractMetadata(String filePath, {String? coversDir}) {
    return Isolate.run(() => _extractSync(filePath, coversDir));
  }

  static AudioMetadata? _extractSync(String filePath, String? coversDir) {
    final file = File(filePath);
    if (!file.existsSync()) return null;

    final int fileSize;
    try {
      fileSize = file.lengthSync();
    } catch (_) {
      return null;
    }

    try {
      final m = amr.readMetadata(file, getImage: coversDir != null);

      String? coverPath;
      if (coversDir != null && m.pictures.isNotEmpty) {
        // Preferir la portada frontal si el archivo trae varias imágenes.
        final pic = m.pictures.firstWhere(
          (p) => p.pictureType == amr.PictureType.coverFront,
          orElse: () => m.pictures.first,
        );
        coverPath = CoverArtService.saveSync(coversDir, pic.bytes);
      }

      return AudioMetadata(
        filePath: filePath,
        title: _nonEmpty(m.title) ?? AudioMetadata.titleFromFilename(filePath),
        artist: _nonEmpty(m.artist) ?? AudioMetadata.unknownArtist,
        album: _nonEmpty(m.album) ?? AudioMetadata.unknownAlbum,
        duration: m.duration?.inSeconds,
        year: m.year?.year,
        genre: m.genres.isNotEmpty ? m.genres.first : null,
        trackNumber: m.trackNumber,
        fileSize: fileSize,
        coverArtPath: coverPath,
      );
    } catch (_) {
      // Etiquetas ilegibles: se usa el nombre del archivo.
      return AudioMetadata(
        filePath: filePath,
        title: AudioMetadata.titleFromFilename(filePath),
        artist: AudioMetadata.unknownArtist,
        album: AudioMetadata.unknownAlbum,
        fileSize: fileSize,
      );
    }
  }

  static String? _nonEmpty(String? s) {
    final t = s?.trim();
    return (t == null || t.isEmpty) ? null : t;
  }

  /// `true` si el archivo tiene una extensión de audio soportada.
  static bool isSupportedAudioFile(String filePath) =>
      supportedExtensions.contains(path.extension(filePath).toLowerCase());
}
