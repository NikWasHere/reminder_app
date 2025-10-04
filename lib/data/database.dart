import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'database.g.dart';

// Tables
class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 255)();
  TextColumn get email => text().nullable()();
  TextColumn get password => text().withLength(min: 6, max: 255)();
}

class Schedules extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get courseName => text().withLength(min: 1, max: 255)();
  TextColumn get lecturer => text().withLength(min: 1, max: 255)();
  TextColumn get room => text().withLength(min: 1, max: 255)();
  TextColumn get day => text().withLength(min: 1, max: 20)();
  TextColumn get startTime => text().withLength(min: 1, max: 10)();
  TextColumn get endTime => text().withLength(min: 1, max: 10)();
}

class Assignments extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get courseName => text().withLength(min: 1, max: 255)();
  TextColumn get description => text().withLength(min: 1, max: 1000)();
  DateTimeColumn get dueDate => dateTime()();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// Database class
@DriftDatabase(tables: [Users, Schedules, Assignments])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // User operations
  Future<List<User>> getAllUsers() => select(users).get();

  Future<User?> getUser() async {
    final user = await (select(users)..limit(1)).getSingleOrNull();
    return user;
  }

  Future<bool> hasUser() async {
    final user = await getUser();
    return user != null;
  }

  Future<int> insertUser(UsersCompanion user) => into(users).insert(user);

  Future<bool> updateUser(User user) => update(users).replace(user);

  Future<int> deleteAllUsers() => delete(users).go();

  // Schedule operations
  Future<List<Schedule>> getAllSchedules() => select(schedules).get();

  Future<List<Schedule>> getSchedulesByDay(String day) =>
      (select(schedules)..where((tbl) => tbl.day.equals(day))).get();

  Future<int> insertSchedule(SchedulesCompanion schedule) =>
      into(schedules).insert(schedule);

  Future<bool> updateSchedule(Schedule schedule) =>
      update(schedules).replace(schedule);

  Future<int> deleteSchedule(int id) =>
      (delete(schedules)..where((tbl) => tbl.id.equals(id))).go();

  // Assignment operations
  Future<List<Assignment>> getAllAssignments() => (select(
    assignments,
  )..orderBy([(t) => OrderingTerm(expression: t.dueDate)])).get();

  Future<List<Assignment>> getUpcomingAssignments() {
    return (select(assignments)
          ..where((tbl) => tbl.isCompleted.equals(false))
          ..orderBy([(t) => OrderingTerm(expression: t.dueDate)]))
        .get();
  }

  Stream<List<Assignment>> watchUpcomingAssignments() {
    return (select(assignments)
          ..where((tbl) => tbl.isCompleted.equals(false))
          ..orderBy([(t) => OrderingTerm(expression: t.dueDate)]))
        .watch();
  }

  Stream<List<Schedule>> watchSchedulesByDay(String day) =>
      (select(schedules)..where((tbl) => tbl.day.equals(day))).watch();

  Future<Assignment?> getAssignmentById(int id) => (select(
    assignments,
  )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();

  Future<Schedule?> getScheduleById(int id) =>
      (select(schedules)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();

  Future<int> insertAssignment(AssignmentsCompanion assignment) =>
      into(assignments).insert(assignment);

  Future<bool> updateAssignment(Assignment assignment) =>
      update(assignments).replace(assignment);

  Future<int> deleteAssignment(int id) =>
      (delete(assignments)..where((tbl) => tbl.id.equals(id))).go();

  Future<bool> markAssignmentCompleted(int id) async {
    final rowsAffected =
        await (update(assignments)..where((tbl) => tbl.id.equals(id))).write(
          const AssignmentsCompanion(isCompleted: Value(true)),
        );
    return rowsAffected > 0;
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();

    // Force clean slate - delete ALL database files and recreate
    final allDbFiles = [
      'reminder_app.db',
      'reminder_app_v1.db',
      'reminder_app_v2.db',
      'reminder_app_v3.db',
    ];

    for (final dbFileName in allDbFiles) {
      final dbFile = File(p.join(dbFolder.path, dbFileName));
      if (await dbFile.exists()) {
        await dbFile.delete();
        debugPrint('Deleted database file: $dbFileName');
      }
    }

    // Use completely new database name with timestamp to ensure uniqueness
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File(
      p.join(dbFolder.path, 'reminder_app_fresh_$timestamp.db'),
    );

    debugPrint('Creating fresh database: ${file.path}');
    return NativeDatabase.createInBackground(file);
  });
}
