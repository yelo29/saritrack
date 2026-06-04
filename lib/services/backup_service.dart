import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';

class BackupService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<Map<String, dynamic>> exportDatabase() async {
    final db = await _dbHelper.database;
    final backup = <String, dynamic>{};

    // Get all table names
    final tables = await db
        .query('sqlite_master', where: 'type = ?', whereArgs: ['table']);

    for (final table in tables) {
      final tableName = table['name'] as String;
      // Skip sqlite internal tables
      if (tableName.startsWith('sqlite_')) continue;

      final data = await db.query(tableName);
      backup[tableName] = data;
    }

    // Add metadata
    backup['_metadata'] = {
      'version': await db.getVersion(),
      'exported_at': DateTime.now().toIso8601String(),
      'app_name': 'SariTrack',
    };

    return backup;
  }

  Future<String> exportToJson() async {
    final backup = await exportDatabase();
    return jsonEncode(backup);
  }

  Future<File> exportToFile() async {
    final jsonString = await exportToJson();
    final directory = await getTemporaryDirectory();
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final file = File('${directory.path}/saritrack_backup_$timestamp.json');
    await file.writeAsString(jsonString);
    return file;
  }

  Future<void> shareBackup() async {
    final file = await exportToFile();
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'SariTrack Backup',
      text: 'SariTrack database backup file',
    );
  }

  Future<bool> restoreFromJson(String jsonString, {bool merge = false}) async {
    try {
      final backup = jsonDecode(jsonString) as Map<String, dynamic>;
      final db = await _dbHelper.database;

      // Verify metadata
      if (!backup.containsKey('_metadata')) {
        throw Exception('Invalid backup file: missing metadata');
      }

      // If not merging, clear existing data
      if (!merge) {
        final tables = await db
            .query('sqlite_master', where: 'type = ?', whereArgs: ['table']);
        for (final table in tables) {
          final tableName = table['name'] as String;
          if (tableName.startsWith('sqlite_')) continue;
          await db.delete(tableName);
        }
      }

      // Restore data
      for (final entry in backup.entries) {
        final key = entry.key;
        if (key == '_metadata') continue;

        final data = entry.value as List;
        if (data.isEmpty) continue;

        final batch = db.batch();
        for (final row in data) {
          batch.insert(key, row as Map<String, dynamic>,
              conflictAlgorithm: ConflictAlgorithm.replace);
        }
        await batch.commit(noResult: true);
      }

      return true;
    } catch (e) {
      print('Restore error: $e');
      return false;
    }
  }

  Future<bool> restoreFromFile(File file, {bool merge = false}) async {
    try {
      final jsonString = await file.readAsString();
      return await restoreFromJson(jsonString, merge: merge);
    } catch (e) {
      print('Restore from file error: $e');
      return false;
    }
  }
}
