import 'package:app/cubits/login_cubit/login_cubit_state.dart';
import 'package:app/cubits/user_cubit/user_cubit.dart';
import 'package:app/helper/shared_prefs_service.dart';
import 'package:app/helper/sql_helper.dart';
import 'package:app/helper/user_db_helper.dart';
import 'package:app/models/user_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthCubit extends Cubit<AuthState> {
  final UserCubit userCubit;
  final DatabaseHelper databaseHelper;
  String? _selectedBranch;
  String? _userRole;
  // Getter for the selected branch
  String? get selectedBranch => _selectedBranch;
  String? get userRole => _userRole; // Getter for user role

  AuthCubit(this.userCubit, this.databaseHelper) : super(AuthInitial());

  Future<void> login(String branch, String username, String password) async {
    emit(AuthLoading());

    try {
      final User? authenticatedUser =
          await databaseHelper.authenticateUser(username, password);

      if (authenticatedUser != null) {
        if (authenticatedUser.branchName == branch &&
            authenticatedUser.allowLogin) {
          // Save auth data
          await SharedPrefsService.saveAuthData(
            DateTime.now().toString(),
            authenticatedUser.id ?? 0,
            authenticatedUser.authorization,
          );
          _selectedBranch = branch;
          _userRole = authenticatedUser.authorization;
          emit(AuthSuccess(authenticatedUser));
          return;
        }
      }

      // Emit AuthFailure if authentication fails
      emit(AuthFailure('Invalid credentials or login not allowed'));
    } catch (e) {
      emit(AuthFailure('Authentication error: ${e.toString()}'));
    }
  }

  Future<void> adminLogin(String username, String password) async {
    emit(AuthLoading());

    try {
      final prefs = await SharedPreferences.getInstance();
      final adminUsername = prefs.getString('admin_username');
      final storedPassword = prefs.getString('admin_password');

      // Add debug logging
      if (kDebugMode) {
        print('Attempting admin login:');
        print('Stored password hash: $storedPassword');
        print('Input username: $username');
      }

      if (username == adminUsername && password == storedPassword) {
        await SharedPrefsService.saveAuthData(
          DateTime.now().toString(),
          0,
          'Admin',
        );
        _userRole = 'Admin';

        if (kDebugMode) {
          print('Admin login successful');
          print('User role set to: $_userRole');
        }

        emit(AuthSuccess(User(
          userName: 'admin',
          branchName: 'Admin',
          authorization: 'Admin',
          allowLogin: true,
          password: password,
        )));
      } else {
        if (kDebugMode) {
          print('Admin login failed: Invalid credentials');
        }
        emit(AuthFailure('Invalid admin credentials'));
      }
    } catch (e) {
      if (kDebugMode) {
        print('Admin login error: ${e.toString()}');
      }
      emit(AuthFailure('Admin authentication error: ${e.toString()}'));
    }
  }

  // Add methods to check user role
  bool isAdmin() => _userRole == 'Admin';
  bool isManager() => _userRole == 'Manager';
  bool isUser() => _userRole == 'User';
  Future<String?> getStoredUserRole() async {
    return await SharedPrefsService.getUserRole();
  }

// In AuthCubit class
  Future<void> resetState() async {
    emit(AuthInitial());
  }

  Future<void> logout() async {
    try {
      await SharedPrefsService.clearAuthData();
      _userRole = null; // Clear the user role on logout

      emit(AuthInitial());
    } catch (e) {
      if (kDebugMode) {
        print('Error during logout: ${e.toString()}');
      }
      // Still emit AuthInitial even if there's an error clearing preferences
      emit(AuthInitial());
    }
  }

  bool isValidUsername(String username) {
    // Enforce username rules
    return RegExp(r'^[a-zA-Z0-9_]{3,20}$').hasMatch(username);
  }

  bool isStrongPassword(String password) {
    return password.length >= 8 &&
        RegExp(r'(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[!@#$%^&*])')
            .hasMatch(password);
  }
}

class LoginAttemptTracker {
  static final _attempts = <String, int>{};
  static final _lockouts = <String, DateTime>{};

  static bool canAttemptLogin(String username) {
    final lockoutTime = _lockouts[username];
    if (lockoutTime != null && DateTime.now().isBefore(lockoutTime)) {
      return false;
    }

    final attempts = _attempts[username] ?? 0;
    return attempts < 5; // Allow 5 attempts
  }

  static void recordFailedAttempt(String username) {
    final currentAttempts = (_attempts[username] ?? 0) + 1;
    _attempts[username] = currentAttempts;

    if (currentAttempts >= 5) {
      // Lock out for 15 minutes
      _lockouts[username] = DateTime.now().add(const Duration(minutes: 15));
    }
  }

  // Add the missing reset method
  static void resetAttempts(String username) {
    _attempts.remove(username);
    _lockouts.remove(username);
  }
}
