import 'package:flutter/foundation.dart' show debugPrint;
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';  // ✅ IMPORTANTE: Importar este
import 'package:music_gamification_app/data/database/tables/sessions_presets_table.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

// Importar todas las tablas
import 'daos/achievements_dao.dart';
import 'daos/play_sessions_dao.dart';
import 'daos/stats_dao.dart';
import 'daos/tracks_dao.dart';
import 'daos/playlists_dao.dart';
import 'tables/tracks_table.dart';
import 'tables/play_sessions_table.dart';
import 'tables/user_stats_table.dart';
import 'tables/genre_stats_table.dart';
import 'tables/achievements_table.dart';
import 'tables/playlists_table.dart';


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
  PlaylistsTable,
  PlaylistTracksTable,
],
  daos: [
    TracksDao,
    PlaySessionsDao,
    AchievementsDao,
    StatsDao,
    PlaylistsDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2; // Incrementado para nueva migración

  // Getters para los DAOs
  @override
  TracksDao get tracksDao => TracksDao(this);
  @override
  PlaySessionsDao get playSessionsDao => PlaySessionsDao(this);
  @override
  AchievementsDao get achievementsDao => AchievementsDao(this);
  @override
  StatsDao get statsDao => StatsDao(this);
  @override
  PlaylistsDao get playlistsDao => PlaylistsDao(this);

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
        // Migración de v1 a v2: Agregar tablas de playlists
        if (from < 2) {
          await m.createTable(playlistsTable);
          await m.createTable(playlistTracksTable);
          debugPrint('✅ Tablas de playlists creadas');
        }
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
