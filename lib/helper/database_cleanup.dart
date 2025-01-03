import 'package:app/helper/sql_helper.dart';
import 'package:flutter/foundation.dart';

extension DatabaseCleanup on DatabaseHelper {
  Future<void> dropAllTables() async {
    try {
      final db = await database;

      // Get all table names
      final tables = await db.query(
        'sqlite_master',
        where: 'type = ?',
        whereArgs: ['table'],
        columns: ['name'],
      );

      // Create a batch operation
      final batch = db.batch();

      // Drop each table
      for (var table in tables) {
        final tableName = table['name'] as String;
        // Skip the sqlite_sequence table as it's internal to SQLite
        if (tableName != 'sqlite_sequence') {
          if (kDebugMode) {
            print('Dropping table: $tableName');
          }
          batch.execute('DROP TABLE IF EXISTS $tableName');
        }
      }

      // Execute all drop commands
      await batch.commit(noResult: true);

      if (kDebugMode) {
        print('All tables dropped successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error dropping tables: $e');
      }
      rethrow;
    }
  }

  Future<void> resetDatabase() async {
    try {
      await DatabaseHelper.closeDatabase(); // Close existing connections

      // Get database instance
      final db = await database;

      // Drop all existing tables
      await dropAllTables();

      // Recreate all tables
      await createTables(db, 3); // Use your current version number

      if (kDebugMode) {
        print('Database reset completed successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error resetting database: $e');
      }
      rethrow;
    }
  }
}
