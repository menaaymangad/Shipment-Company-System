import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefsService {
  static const String _keyAuthToken = 'auth_token';
  static const String _keyUserId = 'user_id';
  static const String _keyUserRole = 'user_role';
  static const String _keyLastBranch = 'last_branch';
  static const String _keyLastUsername = 'last_username';
  static const String _keyIsAdmin = 'is_admin';
  static Future<void> saveAuthData(
      String token, int userId, String userRole) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAuthToken, token);
    await prefs.setInt(_keyUserId, userId);
    await prefs.setString(_keyUserRole, userRole);
    if (kDebugMode) {
      print(
          'Auth data saved - Token: $token, User ID: $userId, Role: $userRole');
    }
    final savedRole = prefs.getString(_keyUserRole);
    if (kDebugMode) {
      print('Saved role in SharedPreferences: $savedRole');
    }
  }

  static Future<void> saveLastLoginInfo(String branch, String username) async {
    final prefs = await SharedPreferences.getInstance();
    final isAdmin = await isAdminUser(); // Check if current user is admin

    // Only save if not admin
    if (!isAdmin) {
      await prefs.setString(_keyLastBranch, branch);
      await prefs.setString(_keyLastUsername, username);
    }
  }

  static Future<Map<String, String?>> getLastLoginInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final isAdmin = await isAdminUser();

    // Return null values if admin
    if (isAdmin) {
      return {'branch': null, 'username': null};
    }

    return {
      'branch': prefs.getString(_keyLastBranch),
      'username': prefs.getString(_keyLastUsername),
    };
  }

  static Future<bool> isAdminUser() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsAdmin) ?? false;
  }

  static Future<void> initializeAdminCredentials() async {
    final prefs = await SharedPreferences.getInstance();

    // Only initialize if credentials don't exist
    if (!prefs.containsKey('admin_username') ||
        !prefs.containsKey('admin_password')) {
      await prefs.setString('admin_username', 'admin');
      await prefs.setString('admin_password', 'admin');
    }
  }

  static Future<void> clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    final isAdmin = await isAdminUser();
    await prefs.remove(_keyAuthToken);
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyUserRole);
    if (isAdmin) {
      await prefs.remove(_keyLastBranch);
      await prefs.remove(_keyLastUsername);
    }
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_keyAuthToken);
  }

  static Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserRole);
  }

  static Future<void> saveBranch(String branch) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLastBranch, branch);
  }

  static Future<String?> getBranch() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLastBranch);
  }
}
