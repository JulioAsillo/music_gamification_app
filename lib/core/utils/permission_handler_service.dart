import 'package:permission_handler/permission_handler.dart';

/// Servicio para gestión de permisos de la app
class PermissionHandlerService {
  /// Solicita permiso de almacenamiento
  Future<bool> requestStoragePermission() async {
    final status = await Permission.storage.request();
    return status.isGranted;
  }

  /// Solicita permiso de notificaciones
  Future<bool> requestNotificationPermission() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  /// Solicita permiso de audio
  Future<bool> requestAudioPermission() async {
    // En Android 13+ necesitamos READ_MEDIA_AUDIO
    if (await Permission.audio.isPermanentlyDenied) {
      openAppSettings();
      return false;
    }
    final status = await Permission.audio.request();
    return status.isGranted;
  }

  /// Verifica si tiene todos los permisos necesarios
  Future<bool> hasAllRequiredPermissions() async {
    final storage = await Permission.storage.isGranted;
    final audio = await Permission.audio.isGranted;
    return storage && audio;
  }

  /// Solicita todos los permisos necesarios
  Future<Map<String, bool>> requestAllPermissions() async {
    final results = await [
      Permission.storage,
      Permission.audio,
      Permission.notification,
    ].request();

    return {
      'storage': results[Permission.storage]?.isGranted ?? false,
      'audio': results[Permission.audio]?.isGranted ?? false,
      'notification': results[Permission.notification]?.isGranted ?? false,
    };
  }

  /// Abre configuración de la app si permisos fueron denegados permanentemente
  Future<void> openAppSettings() async {
    await openAppSettings();
  }
}
