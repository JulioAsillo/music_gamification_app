import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Carátulas embebidas en los archivos de audio, guardadas como imágenes
/// en `<documentos de la app>/covers/`.
///
/// El nombre del archivo sale de un hash del **contenido** de la imagen, así:
/// - Dos canciones nunca pisan la carátula de otra (antes se usaba la hora en
///   milisegundos y varias canciones guardadas en el mismo milisegundo
///   compartían archivo → portadas cambiadas).
/// - Las canciones de un mismo álbum comparten un solo archivo.
abstract final class CoverArtService {
  static String? _dirPath;

  /// Ruta del directorio de carátulas (se crea si no existe).
  static Future<String> directoryPath() async {
    final cached = _dirPath;
    if (cached != null) return cached;
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'covers'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return _dirPath = dir.path;
  }

  /// Guarda [bytes] en [coversDir] y devuelve la ruta. Si ya existe una
  /// imagen idéntica, reutiliza ese archivo.
  ///
  /// Es síncrono a propósito: se llama desde el isolate de extracción de
  /// metadatos (ver `MetadataExtractorService`), no desde la UI.
  static String? saveSync(String coversDir, List<int> bytes) {
    if (bytes.length < 64) return null; // demasiado chico para ser una imagen
    try {
      final name = 'cover_${_fnv1a(bytes).toRadixString(16)}_${bytes.length}.${extensionFor(bytes)}';
      final file = File(p.join(coversDir, name));
      if (!file.existsSync()) file.writeAsBytesSync(bytes, flush: true);
      return file.path;
    } catch (_) {
      return null;
    }
  }

  /// `true` si [path] apunta a una carátula que todavía existe.
  static bool existsSync(String? path) =>
      path != null && path.isNotEmpty && File(path).existsSync();

  /// Extensión según los "magic bytes" de la imagen.
  static String extensionFor(List<int> b) {
    if (b.length > 3 && b[0] == 0x89 && b[1] == 0x50 && b[2] == 0x4E && b[3] == 0x47) return 'png';
    if (b.length > 11 && b[0] == 0x52 && b[1] == 0x49 && b[2] == 0x46 && b[3] == 0x46 &&
        b[8] == 0x57 && b[9] == 0x45 && b[10] == 0x42 && b[11] == 0x50) {
      return 'webp';
    }
    if (b.length > 2 && b[0] == 0x47 && b[1] == 0x49 && b[2] == 0x46) return 'gif';
    return 'jpg';
  }

  /// FNV-1a de 32 bits (estable entre ejecuciones, a diferencia de `hashCode`).
  static int _fnv1a(List<int> bytes) {
    var hash = 0x811c9dc5;
    for (final b in bytes) {
      hash ^= b & 0xff;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return hash;
  }
}
