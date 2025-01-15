import 'package:flutter/foundation.dart';

import '../models/user_model.dart';
import 'sql_helper.dart';

extension UserDatabaseHelper on DatabaseHelper {
  Future<int> insertUser(User user) async {
    final db = await database;

    final userMap = {
      'userName': user.userName,
      'password': user.password, // Use plain text password
      'branchName': user.branchName,
      'authorization': user.authorization,
      'allowLogin': 1 // Make sure this is set to 1 to allow login
    };

    return await db.insert('users', userMap);
  }

  Future<int> updateUser(User user) async {
    final db = await database;

    final userMap = {
      'userName': user.userName,
      'password': user.password, // Use plain text password
      'branchName': user.branchName,
      'authorization': user.authorization,
      'allowLogin': user.allowLogin ? 1 : 0,
    };

    return await db
        .update('users', userMap, where: 'id = ?', whereArgs: [user.id]);
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

  Future<int> deleteUser(int id) async {
    final db = await database;
    return await db.delete('users', where: 'id = ?', whereArgs: [id]);
  }

  // String hashPassword(String password) {
  //   return sha256.convert(utf8.encode(password)).toString();
  // }

  Future<User?> authenticateUser(String username, String password) async {
    try {
      final db = await database;

      // Fetch the user by username with case-insensitive comparison
      final result = await db.query(
        'users',
        where: 'LOWER(userName) = LOWER(?)',
        whereArgs: [username],
      );

      if (result.isEmpty) {
        // User not found, return null
        return null;
      }

      // Get the stored password from the database
      final storedPassword = result.first['password'] as String;

      // Compare the passwords directly
      if (storedPassword == password) {
        // Passwords match, return the user
        return User.fromMap(result.first);
      } else {
        // Passwords do not match, return null
        return null;
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Authentication error: $e');
        print('Stack trace: $stackTrace');
      }
      // Rethrow the exception if it's not related to user not found or password mismatch
      rethrow;
    }
  }

  Future<void> trackFailedLoginAttempt(String username) async {
    final db = await database;
    await db.insert('login_attempts', {
      'username': username,
      'attempt_time': DateTime.now().toIso8601String(),
      'is_success': 0,
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
