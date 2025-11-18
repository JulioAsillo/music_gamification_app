import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

/// 🔐 Servicio para manejar permisos de almacenamiento
class PermissionService {
  /// Solicita permisos de almacenamiento según la versión de Android
  static Future<bool> requestStoragePermission() async {
    if (Platform.isAndroid) {
      // Android 13+ (API 33+) usa permisos específicos de audio
      if (await _isAndroid13OrHigher()) {
        final status = await Permission.audio.request();
        return status.isGranted;
      } else {
        // Android 12 y anteriores usan storage permission
        final status = await Permission.storage.request();
        if (status.isGranted) return true;
        
        // Si no se concede, intenta con manageExternalStorage
        final manageStatus = await Permission.manageExternalStorage.request();
        return manageStatus.isGranted;
      }
    }
    
    // iOS siempre tiene acceso a su propia carpeta
    return true;
  }

  /// Verifica si los permisos están concedidos
  static Future<bool> hasStoragePermission() async {
    if (Platform.isAndroid) {
      if (await _isAndroid13OrHigher()) {
        return await Permission.audio.isGranted;
      } else {
        return await Permission.storage.isGranted ||
               await Permission.manageExternalStorage.isGranted;
      }
    }
    return true;
  }

  /// Abre la configuración de la app para cambiar permisos
  static Future<void> openAppSettings() async {
    await openAppSettings();
  }

  /// Verifica si es Android 13 o superior
  static Future<bool> _isAndroid13OrHigher() async {
    if (!Platform.isAndroid) return false;

    // Verificar si el permiso de audio existe (solo en Android 13+)
    try {
      final status = await Permission.audio.status;
      // Si podemos consultar el estado, es Android 13+
      return true;
    } catch (e) {
      // Si falla, es Android 12 o anterior
      return false;
    }
  }

  /// Verifica el estado actual del permiso
  static Future<PermissionStatus> getStoragePermissionStatus() async {
    if (Platform.isAndroid) {
      if (await _isAndroid13OrHigher()) {
        return await Permission.audio.status;
      } else {
        final storageStatus = await Permission.storage.status;
        if (storageStatus.isGranted) return storageStatus;
        return await Permission.manageExternalStorage.status;
      }
    }
    return PermissionStatus.granted;
  }

  /// Muestra diálogo explicando por qué se necesita el permiso
  static String getPermissionRationale() {
    return 'Esta aplicación necesita acceso a tu música para poder '
           'escanear y reproducir tus canciones locales.';
  }
}
