import '../data/database.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class DatabaseService {
  static DatabaseService? _instance;
  static AppDatabase? _database;

  DatabaseService._internal();

  factory DatabaseService() {
    _instance ??= DatabaseService._internal();
    return _instance!;
  }

  AppDatabase get database {
    _database ??= AppDatabase();
    return _database!;
  }

  Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  // Method to reset database if there are schema issues
  Future<void> resetDatabase() async {
    try {
      await closeDatabase();
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, 'reminder_app.db'));
      if (await file.exists()) {
        await file.delete();
      }
      // Recreate database instance
      _database = AppDatabase();
    } catch (e) {
      debugPrint('Error resetting database: $e');
    }
  }

  static Future<void> dispose() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
      _instance = null;
    }
  }
}
