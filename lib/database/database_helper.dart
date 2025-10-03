import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  // Database version and name
  static const _databaseName = "reminder_app.db";
  static const _databaseVersion = 1;

  // Table names
  static const tableUser = 'users';
  static const tableSchedule = 'schedules';

  // User table columns
  static const columnUserId = 'id';
  static const columnUserName = 'name';
  static const columnUserEmail = 'email';
  static const columnUserPassword = 'password';

  // Schedule table columns
  static const columnScheduleId = 'id';
  static const columnCourseName = 'course_name';
  static const columnLecturer = 'lecturer';
  static const columnRoom = 'room';
  static const columnDay = 'day';
  static const columnStartTime = 'start_time';
  static const columnEndTime = 'end_time';

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // users table
    await db.execute('''
      CREATE TABLE $tableUser (
        $columnUserId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnUserName TEXT NOT NULL,
        $columnUserEmail TEXT,
        $columnUserPassword TEXT NOT NULL
      )
    ''');

    // schedules table
    await db.execute('''
      CREATE TABLE $tableSchedule (
        $columnScheduleId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnCourseName TEXT NOT NULL,
        $columnLecturer TEXT NOT NULL,
        $columnRoom TEXT NOT NULL,
        $columnDay TEXT NOT NULL,
        $columnStartTime TEXT NOT NULL,
        $columnEndTime TEXT NOT NULL
      )
    ''');
  }

  // Helper methods for Users

  Future<int> insertUser(Map<String, dynamic> row) async {
    Database db = await database;
    return await db.insert(tableUser, row);
  }

  Future<Map<String, dynamic>?> getUser() async {
    Database db = await database;
    List<Map<String, dynamic>> users = await db.query(tableUser);
    if (users.isEmpty) return null;
    return users.first;
  }

  Future<bool> hasUser() async {
    Database db = await database;
    List<Map<String, dynamic>> users = await db.query(tableUser);
    return users.isNotEmpty;
  }

  Future<int> updateUser(Map<String, dynamic> row) async {
    Database db = await database;
    return await db.update(
      tableUser,
      row,
      where: '$columnUserId = ?',
      whereArgs: [row[columnUserId]],
    );
  }

  Future<int> deleteUser() async {
    Database db = await database;
    return await db.delete(tableUser);
  }

  // Helper methods for Schedules

  Future<int> insertSchedule(Map<String, dynamic> row) async {
    Database db = await database;
    return await db.insert(tableSchedule, row);
  }

  Future<List<Map<String, dynamic>>> getAllSchedules() async {
    Database db = await database;
    return await db.query(tableSchedule);
  }

  Future<List<Map<String, dynamic>>> getSchedulesByDay(String day) async {
    Database db = await database;
    return await db.query(
      tableSchedule,
      where: '$columnDay = ?',
      whereArgs: [day],
    );
  }

  Future<int> updateSchedule(int id, Map<String, dynamic> row) async {
    Database db = await database;
    return await db.update(
      tableSchedule,
      row,
      where: '$columnScheduleId = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteSchedule(int id) async {
    Database db = await database;
    return await db.delete(
      tableSchedule,
      where: '$columnScheduleId = ?',
      whereArgs: [id],
    );
  }
}
