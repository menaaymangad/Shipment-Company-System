import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefsService {
  static const String _keyAuthToken = 'auth_token';
  static const String _keyUserId = 'user_id';

  static Future<void> saveAuthData(String token, int userId,{bool isAdmin = false}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAuthToken, token);
    await prefs.setInt(_keyUserId, userId);
        await prefs.setBool('isAdmin', isAdmin);
  }

  static Future<void> clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyAuthToken);
    await prefs.remove(_keyUserId);
      await prefs.remove('isAdmin'); 
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_keyAuthToken);
  }
   static Future<bool> isUserAdmin() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool('isAdmin') ?? false;
  }
}
