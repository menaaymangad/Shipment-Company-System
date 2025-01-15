import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefsService {
  static const String _keyAuthToken = 'auth_token';
  static const String _keyUserId = 'user_id';
  static const String _keyUserRole = 'user_role';

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
    final savedRole =  prefs.getString(_keyUserRole);
    if (kDebugMode) {
      print('Saved role in SharedPreferences: $savedRole');
    }
  }

  static Future<void> clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyAuthToken);
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyUserRole);
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_keyAuthToken);
  }

  static Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserRole);
  }
}
