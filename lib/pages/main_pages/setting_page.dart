import 'dart:io';

import 'package:app/helper/branch_db_helper.dart';
import 'package:app/helper/sql_helper.dart';
import 'package:app/models/branches_model.dart';
import 'package:app/pages/main_pages/login_page.dart';
import 'package:app/widgets/delete_db_button.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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

  Future<List<Map<String, dynamic>>> _parseExcelFile(String filePath) async {
    var bytes = File(filePath).readAsBytesSync();
    var excel = Excel.decodeBytes(bytes);

    List<Map<String, dynamic>> data = [];

    // Iterate through sheets
    for (var table in excel.tables.keys) {
      var sheet = excel.tables[table]!;

      // Iterate through rows (skip the header row)
      for (var row in sheet.rows.skip(1)) {
        // Extract data from each row
        Map<String, dynamic> rowData = {
          'branchName': row[0]?.value.toString(),
          'contactPersonName': row[1]?.value.toString(),
          'branchCompany': row[2]?.value.toString(),
          'phoneNo1': row[3]?.value.toString(),
          'phoneNo2': row[4]?.value.toString(),
          'address': row[5]?.value.toString(),
          'city': row[6]?.value.toString(),
          'charactersPrefix': row[7]?.value.toString(),
          'yearPrefix': row[8]?.value.toString(),
          'numberOfDigits': int.tryParse(row[9]?.value.toString() ?? '0'),
          'codeStyle': row[10]?.value.toString(),
          'invoiceLanguage': row[11]?.value.toString(),
        };

        data.add(rowData);
      }
    }

    return data;
  }

  Future<void> _insertDataIntoDatabase(List<Map<String, dynamic>> data) async {
    final dbHelper = DatabaseHelper();

    for (var row in data) {
      // Create a Branch object from the row data
      Branch branch = Branch(
        branchName: row['branchName'],
        contactPersonName: row['contactPersonName'],
        branchCompany: row['branchCompany'],
        phoneNo1: row['phoneNo1'],
        phoneNo2: row['phoneNo2'],
        address: row['address'],
        city: row['city'],
        charactersPrefix: row['charactersPrefix'],
        yearPrefix: row['yearPrefix'],
        numberOfDigits: row['numberOfDigits'],
        codeStyle: row['codeStyle'],
        invoiceLanguage: row['invoiceLanguage'],
      );

      // Insert the branch into the database
      await dbHelper.insertBranch(branch);
    }
  }

  Future<void> _restoreDatabase() async {
    print("Restore button pressed"); // Debugging line
    try {
      // Open file picker to select a file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'mdb', 'accdb'],
      );

      if (result != null) {
        PlatformFile file = result.files.first;
        String? filePath = file.path;

        if (filePath == null) {
          print("File path is null");
          return;
        }

        print("Selected file: $filePath"); // Debugging line

        // Check if the file exists
        if (!File(filePath).existsSync()) {
          print("File does not exist: $filePath");
          return;
        }

        // Check file extension
        if (filePath.endsWith('.xlsx')) {
          print("Processing Excel file"); // Debugging line

          // Parse the Excel file
          List<Map<String, dynamic>> data = await _parseExcelFile(filePath);

          // Insert the data into the SQLite database
          await _insertDataIntoDatabase(data);

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Database restored successfully!')),
          );
        } else if (filePath.endsWith('.mdb') || filePath.endsWith('.accdb')) {
          print("Processing Access file"); // Debugging line
          // Handle Access file (not implemented in this example)
        }
      } else {
        // User canceled the picker
        print("No file selected");
      }
    } catch (e) {
      // Handle errors
      print("Error restoring database: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error restoring database: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  onPressed: () {},
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
                  onPressed: _restoreDatabase,
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
    return Expanded(
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(64.0.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  'Agent Address',
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 45.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 100.h),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Agents',
                  border: OutlineInputBorder(),
                ),
                value: selectedAgent,
                items: const [],
                onChanged: (value) {
                  setState(() => selectedAgent = value);
                },
              ),
              SizedBox(height: 32.h),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Branches',
                  border: OutlineInputBorder(),
                ),
                value: selectedBranch,
                items: const [],
                onChanged: (value) {
                  setState(() => selectedBranch = value);
                },
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
