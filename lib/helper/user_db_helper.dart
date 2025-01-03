import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

import '../models/user_model.dart';
import 'sql_helper.dart';

extension UserDatabaseHelper on DatabaseHelper {
Future<int> insertUser(User user) async {
    final db = await database;

    // Hash the password before inserting
    final hashedPassword = hashPassword(user.password);

    final userMap = {
      'userName': user.userName,
      'password': hashedPassword,
      'branchName': user.branchName,
      'authorization': user.authorization,
      'allowLogin': 1 // Make sure this is set to 1 to allow login
    };

    if (kDebugMode) {
      print('Inserting new user: $userMap');
    } // Debug line
    return await db.insert('users', userMap);
  }

  Future<List<User>> getAllUsers() async {
    final db = await database;
    final result = await db.query('users');
    return result.map((map) => User.fromMap(map)).toList();
  }

  Future<User?> getUser(int id) async {
    final db = await database;
    final result = await db.query('users', where: 'id = ?', whereArgs: [id]);
    if (result.isEmpty) return null;
    return User.fromMap(result.first);
  }

  Future<int> updateUser(User user) async {
    final db = await database;
    return await db
        .update('users', user.toMap(), where: 'id = ?', whereArgs: [user.id]);
  }

  Future<int> deleteUser(int id) async {
    final db = await database;
    return await db.delete('users', where: 'id = ?', whereArgs: [id]);
  }

  String hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

// Update authentication to use hashed passwords
 // In user_db_helper.dart
  Future<User?> authenticateUser(String username, String password) async {
    try {
      final db = await database;

      // Verify users table exists
      final tableCheck = await db.query('sqlite_master',
          where: 'type = ? AND name = ?', whereArgs: ['table', 'users']);

      if (tableCheck.isEmpty) {
        throw Exception('Users table does not exist');
      }

      final hashedPassword = hashPassword(password);
      final result = await db.query('users',
          where: 'userName = ? AND password = ?',
          whereArgs: [username, hashedPassword]);

      return result.isEmpty ? null : User.fromMap(result.first);
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Authentication error: $e');
      }
      if (kDebugMode) {
        print('Stack trace: $stackTrace');
      }
      rethrow;
    }
  }

  Future<void> trackFailedLoginAttempt(String username) async {
    // Optionally log failed login attempts to the database
    final db = await database;
    await db.insert('login_attempts', {
      'username': username,
      'attempt_time': DateTime.now().toIso8601String(),
      'is_success': 0
    });
  }
  Future<void> printAllUsers() async {
    final db = await database;
    final users = await db.query('users');
    if (kDebugMode) {
      print('All users in database:');
    }
    for (var user in users) {
      if (kDebugMode) {
        print(
          'User: ${user['userName']}, Authorization: ${user['authorization']}, AllowLogin: ${user['allowLogin']}');
      }
    }
  }
}
