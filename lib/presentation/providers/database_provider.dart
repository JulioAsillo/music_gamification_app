import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/database/app_database.dart';

part 'database_provider.g.dart';

/// Provider de la base de datos (singleton)
@Riverpod(keepAlive: true)
AppDatabase appDatabase(AppDatabaseRef ref) {
  final database = AppDatabase();

  // Cleanup cuando el provider se destruye
  ref.onDispose(() {
    database.close();
  });

  return database;
}
