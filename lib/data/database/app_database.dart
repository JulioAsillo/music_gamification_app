import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';  // ✅ IMPORTANTE: Importar este
import 'package:music_gamification_app/data/database/tables/sessions_presets_table.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

// Importar todas las tablas
import 'tables/tracks_table.dart';
import 'tables/play_sessions_table.dart';
import 'tables/user_stats_table.dart';
import 'tables/genre_stats_table.dart';
import 'tables/achievements_table.dart';

// Importar los modelos para conversiones
import '../models/track.dart' as models;
import '../models/play_session.dart' as models;
import '../models/user_stats.dart' as models;
import '../models/genre_stats.dart' as models;
import '../models/achievement.dart' as models;
import '../models/session_preset.dart' as models;

// Esta parte es para code generation
part 'app_database.g.dart';

/// Base de datos principal de la app
@DriftDatabase(tables: [
  TracksTable,
  PlaySessionsTable,
  UserStatsTable,
  GenreStatsTable,
  AchievementsTable,
  SessionPresetsTable,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();

        // Insertar estadísticas iniciales del usuario
        await into(userStatsTable).insert(
          UserStatsTableCompanion.insert(
            lastListeningDate: DateTime.now(),
          ),
        );
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // Migraciones futuras van aquí
      },
    );
  }
}

/// Función para abrir la conexión a la BD
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'music_gamification.sqlite'));

    // ✅ VERSIÓN CORRECTA: Usar NativeDatabase directamente
    return NativeDatabase(file);
  });
}
