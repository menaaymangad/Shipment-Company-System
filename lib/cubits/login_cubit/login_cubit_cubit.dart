import 'package:app/cubits/login_cubit/login_cubit_state.dart';
import 'package:app/cubits/user_cubit/user_cubit.dart';
import 'package:app/helper/shared_prefs_service.dart';
import 'package:app/helper/sql_helper.dart';
import 'package:app/helper/user_db_helper.dart';
import 'package:app/models/user_model.dart';
import 'package:app/pages/main_pages/login_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
          await SharedPrefsService.saveBranch(branch);
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

      // Check if the provided credentials match the stored admin credentials
      if (username == adminUsername && password == storedPassword) {
        await SharedPrefsService.saveAuthData(
          DateTime.now().toString(),
          0, // Admin ID (can be 0 or any placeholder)
          'Admin', // Admin role
        );
        _userRole = 'Admin';

        await SharedPrefsService.saveBranch(
            'Baghdad'); // Default branch for admin

        emit(AuthSuccess(User(
          userName: 'admin',
          branchName: 'Admin',
          authorization: 'Admin',
          allowLogin: true,
          password: password, // Use the provided password
        )));
      } else {
        emit(AuthFailure('Invalid admin credentials'));
      }
    } catch (e) {
      emit(AuthFailure('Admin authentication error: ${e.toString()}'));
    }
  }

  Future<void> changeAdminPassword(
    BuildContext context, {
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    // Validate password match
    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New passwords do not match')),
      );
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final storedPassword = prefs.getString('admin_password');

      // Verify current password
      if (currentPassword != storedPassword) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Current password is incorrect')),
        );
        return;
      }

      // Update password in SharedPreferences
      await prefs.setString('admin_password', newPassword);

      if (kDebugMode) {
        print('Admin password updated successfully');
        print('New password stored: ${prefs.getString('admin_password')}');
      }

      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password updated successfully')),
        );
      }

      // Force logout to ensure security
      if (context.mounted) {
        final authCubit = context.read<AuthCubit>();
        await authCubit.logout();
        Navigator.of(context).pushNamedAndRemoveUntil(
          LoginPage.id,
          (route) => false,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating admin password: $e');
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating password: $e')),
        );
      }
    }
  } // Add methods to check user role

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
