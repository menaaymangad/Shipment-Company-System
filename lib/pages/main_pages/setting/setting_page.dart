import 'package:app/cubits/login_cubit/login_cubit_cubit.dart';
import 'package:app/pages/main_pages/login_page.dart';
import 'package:app/pages/main_pages/setting/database_management.dart';
import 'package:app/widgets/delete_db_button.dart';
import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});
  static String id = 'SettingPage';

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  String? selectedAgent;
  String? selectedBranch;
  bool userSQLAuth = false;
  DatabaseManagementExcelImport importDatabase =
      DatabaseManagementExcelImport();

  @override
  void initState() {
    super.initState();
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
  }

  @override
  Widget build(BuildContext context) {
    final authCubit = context.read<AuthCubit>();
    if (!authCubit.isAdmin()) {
      return const Center(
        child: Text('You are not authorized to access the Setting page.'),
      );
    }
    return Padding(
      padding: EdgeInsets.all(32.0.r),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Panel - Agent Address
          leftSideContent(),
          SizedBox(width: 16.w),

          // Middle Panel - Backup Operations
          middleSideContent(),
          SizedBox(width: 16.w),

          // Right Panel - DB Connection Settings
          rightSideContent(),
        ],
      ),
    );
  }

  Expanded rightSideContent() {
    return Expanded(
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(64.0.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  'DB Connection Settings',
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 45.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 100.h),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Server Name',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 24.h),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Database Name',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 64.h),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                      ),
                      child: const Text(
                        'Save',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    SizedBox(
                      width: 10.w,
                    ),
                    DatabaseDeletionButton(
                      onDeleted: () {
                        // Handle post-deletion tasks, like navigating to login screen
                        Navigator.of(context).pushNamedAndRemoveUntil(
                            LoginPage.id, (route) => false);
                      },
                    )
                  ],
                ),
              ),
              SizedBox(height: 64.h),
              const Divider(),
              SizedBox(height: 32.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Checkbox(value: true, onChanged: (value) {}),
                  const Text('User SQL Auth.'),
                ],
              ),
              SizedBox(height: 32.h),
              const Divider(),
              SizedBox(height: 64.h),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Database Name',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 32.h),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              SizedBox(height: 64.h),
              Center(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                  ),
                  child: const Text(
                    'Save',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Expanded middleSideContent() {
    return Expanded(
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(64.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  'Make Backup',
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 45.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 100.h),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Server Name',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 24.h),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Database Name',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 24.h),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Backup Name',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 24.h),
              Expanded(
                child: TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Backup Path',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              SizedBox(height: 24.h),
              Center(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                  ),
                  child: const Text(
                    'Open',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
              SizedBox(height: 24.h),
              Center(
                child: ElevatedButton(
                  onPressed: () =>
                      DatabaseManagementExcelImport.exportToExcel(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                  ),
                  child: const Text(
                    'Backup',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
              SizedBox(height: 32.h),
              const Divider(),
              SizedBox(height: 24.h),
              Center(
                child: Text(
                  'Restore Backup',
                  style: TextStyle(
                    color: Colors.pink,
                    fontSize: 45.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 32.h),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Select Backup Path To Restore',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 32.h),
              Center(
                child: ElevatedButton(
                  onPressed: () =>
                      DatabaseManagementExcelImport.importFromExcel(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pink,
                  ),
                  child: const Text(
                    'Restore',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Expanded leftSideContent() {
    final TextEditingController currentPasswordController =
        TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController =
        TextEditingController();

    return Expanded(
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(64.0.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  'Admin Password Change',
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 45.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 100.h),
              TextFormField(
                controller: currentPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Current Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              SizedBox(height: 32.h),
              TextFormField(
                controller: newPasswordController,
                decoration: const InputDecoration(
                  labelText: 'New Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              SizedBox(height: 32.h),
              TextFormField(
                controller: confirmPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Confirm New Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              SizedBox(height: 32.h),
              Center(
                child: ElevatedButton(
                  onPressed: () async {
                    await changeAdminPassword(
                      context,
                      currentPassword: currentPasswordController.text,
                      newPassword: newPasswordController.text,
                      confirmPassword: confirmPasswordController.text,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                  ),
                  child: const Text(
                    'Change Password',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
              const Spacer(),
              const Divider(),
              Padding(
                padding: EdgeInsets.all(8.0.r),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Designed By: Mina Ayman',
                      style: TextStyle(
                          fontSize: 35.sp, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(
                      height: 32.h,
                    ),
                    Text(
                      'Version : 4.0 - 2024',
                      style: TextStyle(
                          fontSize: 35.sp, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(
                      height: 32.h,
                    ),
                    Text(
                      '© All Copyrights Reserved To EUKnet Company',
                      style: TextStyle(
                          fontSize: 30.sp, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(
                      height: 32.h,
                    ),
                    Text(
                      '2021 - 2024',
                      style: TextStyle(
                          fontSize: 35.sp, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
