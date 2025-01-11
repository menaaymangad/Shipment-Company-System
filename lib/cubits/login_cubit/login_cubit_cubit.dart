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
  // Getter for the selected branch
  String? get selectedBranch => _selectedBranch;

  AuthCubit(this.userCubit, this.databaseHelper) : super(AuthInitial());

Future<void> login(String branch, String username, String password) async {
    emit(AuthLoading());

    try {
      await databaseHelper.printAllUsers();

      // Check login attempt limits
      if (!LoginAttemptTracker.canAttemptLogin(username)) {
        emit(AuthFailure('Too many login attempts. Please try again later.'));
        return;
      }

      final User? authenticatedUser =
          await databaseHelper.authenticateUser(username, password);

      if (authenticatedUser != null) {
        if (authenticatedUser.branchName == branch &&
            authenticatedUser.allowLogin) {
          // Reset failed attempts on successful login
          LoginAttemptTracker.resetAttempts(username);

          // Save auth data
          await SharedPrefsService.saveAuthData(
            DateTime.now().toString(),
            authenticatedUser.id ?? 0,
          );
          // Store the selected branch
          _selectedBranch = branch;

          emit(AuthSuccess(authenticatedUser));
          return;
        }
      }

      // Record failed attempt
      LoginAttemptTracker.recordFailedAttempt(username);
      emit(AuthFailure('Invalid credentials or login not allowed'));
    } catch (e) {
      if (e.toString().contains('Password mismatch')) {
        // Handle password mismatch error
        emit(AuthFailure('Password mismatch'));
      } else {
        emit(AuthFailure('Authentication error: ${e.toString()}'));
      }
    }
  }
  
  Future<void> adminLogin(String username, String password) async {
    emit(AuthLoading());

    try {
      // Check login attempt limits
      if (!LoginAttemptTracker.canAttemptLogin(username)) {
        emit(AuthFailure('Too many login attempts. Please try again later.'));
        return;
      }

      final User? authenticatedUser =
          await databaseHelper.authenticateUser(username, password);

      if (authenticatedUser != null) {
        // Add explicit admin authorization check
        if (authenticatedUser.authorization == 'Admin' &&
            authenticatedUser.allowLogin) {
          // Reset failed attempts on successful login
          LoginAttemptTracker.resetAttempts(username);

          // Save auth data
          await SharedPrefsService.saveAuthData(
              DateTime.now().toString(), authenticatedUser.id ?? 0);

          // Separately save admin status
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isAdmin', true);

          emit(AuthSuccess(authenticatedUser));
          return;
        }
      }

      // Record failed attempt
      LoginAttemptTracker.recordFailedAttempt(username);
      emit(AuthFailure('Invalid admin credentials or login not allowed'));
    } catch (e) {
      emit(AuthFailure('Admin authentication error: ${e.toString()}'));
    }
  }

  Future<void> logout() async {
    try {
      await SharedPrefsService.clearAuthData();
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
