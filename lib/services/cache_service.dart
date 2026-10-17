import 'dart:io';

import 'package:flutter/painting.dart';
import 'package:path_provider/path_provider.dart';

/// Limpieza de archivos temporales de la app.
abstract final class CacheService {
  /// Borra el directorio temporal de la app y la caché de imágenes en memoria.
  /// No toca la música, la base de datos ni las carátulas guardadas.
  ///
  /// Devuelve los bytes liberados (aproximado: archivos sueltos en la raíz
  /// del temporal + archivos dentro de subcarpetas).
  static Future<int> clearTemporaryFiles() async {
    var freed = 0;
    try {
      final tmp = await getTemporaryDirectory();
      if (await tmp.exists()) {
        await for (final entity in tmp.list(followLinks: false)) {
          try {
            freed += await _sizeOf(entity);
            await entity.delete(recursive: true);
          } catch (_) {
            // Archivo en uso: se omite.
          }
        }
      }
    } catch (_) {
      // Sin acceso al directorio temporal.
    }
    PaintingBinding.instance.imageCache.clear();
    return freed;
  }

  static Future<int> _sizeOf(FileSystemEntity entity) async {
    if (entity is File) return entity.length();
    if (entity is Directory) {
      var total = 0;
      await for (final child in entity.list(recursive: true, followLinks: false)) {
        if (child is File) total += await child.length();
      }
      return total;
    }
    return 0;
  }
}
