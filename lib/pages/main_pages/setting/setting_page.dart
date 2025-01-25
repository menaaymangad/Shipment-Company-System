import 'package:app/cubits/login_cubit/login_cubit_cubit.dart';
import 'package:app/helper/send_db_helper.dart';
import 'package:app/pages/main_pages/login_page.dart';
import 'package:app/pages/main_pages/setting/database_management.dart';
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
// Add these variables at the top of _SettingPageState
  String? selectedYear;
  List<String> availableYears = [];
  final SendRecordDatabaseHelper _sendDbHelper = SendRecordDatabaseHelper();

  late TextEditingController _codePrefixController;
  late final TextEditingController currentPasswordController;
  late final TextEditingController newPasswordController;
  late final TextEditingController confirmPasswordController;
  @override
  void initState() {
    super.initState();
    selectedYear = null;
    _codePrefixController = TextEditingController();
    currentPasswordController = TextEditingController();
    newPasswordController = TextEditingController();
    confirmPasswordController = TextEditingController();
    _restoreFormData();
    _loadAvailableYears();
  }

  void _restoreFormData() {
    final formData = context.read<SettingFormCubit>().state;

    if (mounted) {
      setState(() {
        selectedYear = formData['selectedYear'];
        selectedTruckNumber = formData['selectedTruckNumber'];
        _codePrefixController.text = formData['codePrefix'] ?? '';
      });
    }
    if (mounted) {
      setState(() {
        currentPasswordController.text = formData['currentPassword'] ?? '';
        newPasswordController.text = formData['newPassword'] ?? '';
        confirmPasswordController.text = formData['confirmPassword'] ?? '';
      });
    }
  }

  void _savePasswordData() {
    context.read<SettingFormCubit>().savePasswordData(
          currentPassword: currentPasswordController.text,
          newPassword: newPasswordController.text,
          confirmPassword: confirmPasswordController.text,
        );
  }

  @override
  void deactivate() {
    _saveFormData();
    _savePasswordData();
    super.deactivate();
  }

  void _saveFormData() {
    context.read<SettingFormCubit>().saveFormData(
          selectedYear: selectedYear,
          selectedTruckNumber: selectedTruckNumber,
          codePrefix: _codePrefixController.text,
        );
  }

  @override
  void dispose() {
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    _codePrefixController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableYears() async {
    try {
      final years = await _sendDbHelper
          .getAvailableYears(); // Add this to your _loadAvailableYears method
      availableYears = years.toSet().toList(); // Ensure unique values
      setState(() {
        availableYears = years;
        // Only set selectedYear if the list isn't empty
        if (years.isNotEmpty && selectedYear == null) {
          selectedYear = years.first;
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading years: ${e.toString()}')),
      );
    }
  }

  String? selectedTruckNumber;
  List<String> availableTruckNumbers = [];

  Future<void> _loadTruckNumbersByYear(String year) async {
    try {
      final truckNumbers = await _sendDbHelper.getTruckNumbersByYear(year);
      setState(() {
        availableTruckNumbers = truckNumbers;
        selectedTruckNumber = null; // Reset selected truck number
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading truck numbers: ${e.toString()}')),
      );
    }
  }

  Widget _yearSelectionWidget() {
    if (availableYears.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(8.0),
        child: Text('No shipment records found'),
      );
    }
    return Column(
      children: [
        DropdownButton<String>(
          value: availableYears.contains(selectedYear) ? selectedYear : null,
          hint: const Text('Select Year'),
          items: [
            if (availableYears.isEmpty)
              const DropdownMenuItem<String>(
                value: null,
                child: Text('No years available'),
              )
            else
              ...availableYears.map((year) => DropdownMenuItem(
                    value: year,
                    child: Text(year),
                  )),
          ],
          onChanged: availableYears.isEmpty
              ? null
              : (value) async {
                  setState(() => selectedYear = value);
                  context
                      .read<SettingFormCubit>()
                      .saveFormData(selectedYear: value);
                  await _loadTruckNumbersByYear(value!);
                },
        ),
        SizedBox(height: 10.h),
        if (selectedYear != null && availableTruckNumbers.isNotEmpty)
          DropdownButton<String>(
            value: selectedTruckNumber,
            hint: const Text('Select Truck Number'),
            items: availableTruckNumbers.map((truckNumber) {
              return DropdownMenuItem(
                value: truckNumber,
                child: Text(truckNumber),
              );
            }).toList(),
            onChanged: (value) {
              setState(() => selectedTruckNumber = value);
              context
                  .read<SettingFormCubit>()
                  .saveFormData(selectedTruckNumber: value);
            },
          ),
        SizedBox(height: 10.h),
        TextField(
          decoration: const InputDecoration(
            labelText: 'Or enter specific code prefix',
            hintText: 'e.g., 2024-005',
          ),
          controller: _codePrefixController,
          onChanged: (value) {
            context.read<SettingFormCubit>().saveFormData(codePrefix: value);
          },
        ),
      ],
    );
  }
// Delete handler

  Future<void> _deleteSelectedYear() async {
    if (selectedYear == null || selectedYear!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select a year or enter a Truck Number')),
      );
      return;
    }

    try {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirm Deletion'),
          content: Text(
              'Are you sure you want to delete records for "$selectedYear"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        ),
      );

      if (confirm == true) {
        await _sendDbHelper.deleteRecordsByYear(selectedYear!);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Successfully deleted records for $selectedYear')),
        );
        _loadAvailableYears();
        context.read<SettingFormCubit>().clearYearData();
        setState(() {
          selectedYear = null;
          selectedTruckNumber = null;
          _codePrefixController.clear();
        }); // Refresh the year list
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting records: ${e.toString()}')),
      );
    }
  }

  Future<void> _deleteSpecificShipment() async {
    if (selectedYear == null || selectedTruckNumber == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a year and truck number')),
      );
      return;
    }

    try {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirm Deletion'),
          content: Text(
              'Are you sure you want to delete records for truck "$selectedTruckNumber" in "$selectedYear"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        ),
      );

      if (confirm == true) {
        await _sendDbHelper.deleteSpecificShipment(
            selectedYear!, selectedTruckNumber!);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Successfully deleted records for truck $selectedTruckNumber in $selectedYear')),
        );
        _loadAvailableYears();
        context.read<SettingFormCubit>().clearTruckData();
        setState(() => selectedTruckNumber = null); // Refresh the year list
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting records: ${e.toString()}')),
      );
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
        context.read<SettingFormCubit>().clearPasswordData();
        currentPasswordController.clear();
        newPasswordController.clear();
        confirmPasswordController.clear();

        // Force logout
        final authCubit = context.read<AuthCubit>();
        await authCubit.logout();
        Navigator.of(context).pushNamedAndRemoveUntil(
          LoginPage.id,
          (route) => false,
        );
      }
    } catch (e) {
      _savePasswordData();
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
      padding: EdgeInsets.all(20.0.r),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Panel - Agent Address
          leftSideContent(),
          SizedBox(width: 16.w),

          // Middle Panel - Backup Operations
          middleSideContent(),
        ],
      ),
    );
  }

  Expanded middleSideContent() {
    return Expanded(
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(20.0.r),
          child: SingleChildScrollView(
            child: Column(
              spacing: 12.h,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Admin Security Section
                _buildSectionHeader('Admin Security', Icons.security),

                _buildPasswordField(
                  controller: currentPasswordController,
                  label: 'Current Password',
                  icon: Icons.lock_outline,
                ),

                _buildPasswordField(
                  controller: newPasswordController,
                  label: 'New Password',
                  icon: Icons.lock_reset,
                ),

                _buildPasswordField(
                  controller: confirmPasswordController,
                  label: 'Confirm Password',
                  icon: Icons.lock_clock,
                ),
                CheckboxListTile(
                  title: const Text('Show Passwords'),
                  value: _showPasswords,
                  onChanged: (value) {
                    setState(() {
                      _showPasswords = value ?? false;
                    });
                  },
                  secondary: const Icon(Icons.visibility),
                ),
                _buildActionButton(
                  'Change Password',
                  Icons.key,
                  Colors.blue,
                  () async => await changeAdminPassword(
                    context,
                    currentPassword: currentPasswordController.text,
                    newPassword: newPasswordController.text,
                    confirmPassword: confirmPasswordController.text,
                  ),
                ),

                // Database Operations Section
                _buildSectionDivider(),
                _buildSectionHeader('Database Management', Icons.storage),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildIconButton(
                        'Backup',
                        Icons.backup,
                        Colors.blue,
                        () => DatabaseManagementExcelImport.exportToExcel(
                            context)),
                    SizedBox(width: 20.w),
                    _buildIconButton(
                        'Restore',
                        Icons.restore,
                        Colors.green,
                        () => DatabaseManagementExcelImport.importFromExcel(
                            context)),
                  ],
                ),

                // Record Deletion Section
                _buildSectionDivider(),
                // In the middleSideContent method
                _buildSectionHeader('Record Deletion', Icons.delete_forever,
                    color: Colors.red),
                _yearSelectionWidget(),
                _buildDeleteButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Expanded leftSideContent() {
    return Expanded(
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(20.0.r),
          child: Column(
            spacing: MediaQuery.sizeOf(context).width < 800 &&
                    MediaQuery.sizeOf(context).height < 600
                ? 8.h
                : 14.h,
            mainAxisAlignment: MediaQuery.sizeOf(context).width < 800 &&
                    MediaQuery.sizeOf(context).height < 600
                ? MainAxisAlignment.start
                : MainAxisAlignment.center,
            children: [
              Icon(Icons.business_center, size: 60.sp, color: Colors.blue),
              _buildInfoItem('Version 1.0', Icons.update),
              _buildInfoItem('Developed by Mina Ayman', Icons.code),
              _buildInfoItem('EUKnet Company 2025', Icons.copyright),
              _buildSectionDivider(),
              _buildInfoItem('Support Contact', Icons.support_agent,
                  isHeader: true),
              _buildInfoItem('menaaymangad@gmail.com', Icons.email),
              _buildInfoItem('+2 012 8771 3516', Icons.phone),
            ],
          ),
        ),
      ),
    );
  }

  // Helper Widgets
  Widget _buildSectionHeader(String title, IconData icon,
      {Color color = Colors.blue}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 50.r, color: color),
        SizedBox(width: 15.w),
        Text(
          title,
          style: TextStyle(
            color: color,
            fontSize: 28.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
      String text, IconData icon, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.r),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 45.r),
          SizedBox(width: 20.w),
          Text(
            text,
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton(
      String text, IconData icon, Color color, VoidCallback onPressed) {
    return Column(
      children: [
        IconButton(
          iconSize: 50.r,
          icon: Icon(icon, color: color),
          onPressed: onPressed,
        ),
        Text(
          text,
          style: TextStyle(
            fontSize: 24.sp,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItem(String text, IconData icon, {bool isHeader = false}) {
    return ListTile(
      leading: Icon(icon,
          size: 40.r, color: isHeader ? Colors.blue : Colors.grey[700]),
      title: Text(
        text,
        style: TextStyle(
          fontSize: 24.sp,
          fontWeight: isHeader ? FontWeight.bold : FontWeight.w500,
          color: isHeader ? Colors.blue : Colors.grey[800],
        ),
      ),
    );
  }

  Widget _buildSectionDivider() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 20.h),
      child: Divider(
        thickness: 2,
        color: Colors.grey[300],
        height: 2,
      ),
    );
  }

  // Add this to _SettingPageState class
  bool _showPasswords = false;

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: !_showPasswords,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.blue),
        suffixIcon: IconButton(
          icon: Icon(
            _showPasswords ? Icons.visibility_off : Icons.visibility,
            color: Colors.blue,
          ),
          onPressed: () {
            setState(() {
              _showPasswords = !_showPasswords;
            });
          },
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15.r),
          borderSide: const BorderSide(color: Colors.blue),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15.r),
          borderSide: const BorderSide(color: Colors.blue, width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 20.w),
      ),
      style: TextStyle(fontSize: 24.sp),
    );
  }

  Widget _buildDeleteButtons() {
    return Column(
      children: [
        if (selectedYear != null)
          _buildActionButton(
            'Delete Entire Year',
            Icons.delete_forever,
            Colors.red,
            () => _deleteSelectedYear(),
          ),
        SizedBox(height: 10.h),
        if (selectedTruckNumber != null)
          _buildActionButton(
            'Delete Specific Shipment',
            Icons.delete_outline,
            Colors.orange,
            () => _deleteSpecificShipment(),
          ),
      ],
    );
  }
}

class SettingFormCubit extends Cubit<Map<String, dynamic>> {
  SettingFormCubit() : super({});
  void savePasswordData({
    String? currentPassword,
    String? newPassword,
    String? confirmPassword,
  }) {
    final newState = {
      ...state,
      if (currentPassword != null) 'currentPassword': currentPassword,
      if (newPassword != null) 'newPassword': newPassword,
      if (confirmPassword != null) 'confirmPassword': confirmPassword,
    };
    emit(newState);
  }

  void clearPasswordData() => emit({
        ...state,
        'currentPassword': null,
        'newPassword': null,
        'confirmPassword': null,
      });
  void saveFormData({
    String? selectedYear,
    String? selectedTruckNumber,
    String? codePrefix,
  }) {
    final newState = {
      ...state,
      if (selectedYear != null) 'selectedYear': selectedYear,
      if (selectedTruckNumber != null)
        'selectedTruckNumber': selectedTruckNumber,
      if (codePrefix != null) 'codePrefix': codePrefix,
    };
    emit(newState);
  }

  void clearYearData() =>
      emit({...state, 'selectedYear': null, 'selectedTruckNumber': null});
  void clearTruckData() => emit({...state, 'selectedTruckNumber': null});
}
