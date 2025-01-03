// // lib/packaging/windows_packager.dart
// import 'dart:io';
// import 'package:app/helper/sql_helper.dart';
// import 'package:path/path.dart';

// class WindowsPackager {
//   static Future<void> createDistribution() async {
//     // Ensure the Windows build exists
//     final buildDir = Directory('build/windows/runner/Release');
//     if (!await buildDir.exists()) {
//       throw Exception(
//           'Windows build not found. Run "flutter build windows" first.');
//     }

//     // Create distribution directory
//     final distDir = Directory('dist');
//     if (await distDir.exists()) {
//       await distDir.delete(recursive: true);
//     }
//     await distDir.create();

//     // Create data directory for database
//     final dataDir = Directory(join(distDir.path, 'data'));
//     await dataDir.create();

//     print('Copying application files...');
//     await _copyApplicationFiles(buildDir.path, distDir.path);

//     print('Setting up database...');
//     await _setupDatabase(dataDir.path);

//     print('Creating installation guide...');
//     await _createInstallationGuide(distDir.path);

//     print('Distribution package created successfully!');
//   }

//   static Future<void> _copyApplicationFiles(
//       String buildPath, String distPath) async {
//     // Copy exe and required DLLs
//     final buildDir = Directory(buildPath);
//     await for (final entity in buildDir.list()) {
//       if (entity is File) {
//         final fileName = basename(entity.path);
//         if (fileName.endsWith('.exe') || fileName.endsWith('.dll')) {
//           await entity.copy(join(distPath, fileName));
//         }
//       }
//     }

//     // Copy data folder if it exists in build
//     final buildDataDir = Directory(join(buildPath, 'data'));
//     if (await buildDataDir.exists()) {
//       await _copyDirectory(buildDataDir.path, join(distPath, 'data'));
//     }
//   }

//   static Future<void> _setupDatabase(String dataPath) async {
//     // Copy initial database if it exists
//     final sourceDb = File('assets/euknet_transport.db');
//     if (await sourceDb.exists()) {
//       await sourceDb.copy(join(dataPath, 'euknet_transport.db'));
//     }

//     // Create empty database with schema if no initial database exists
//     else {
//       final dbHelper = DatabaseHelper();
//       // Initialize database at the new location
//       // You'll need to modify your DatabaseHelper to accept a custom path
//       await dbHelper.initializeNewDatabase(dataPath);
//     }
//   }

//   static Future<void> _createInstallationGuide(String distPath) async {
//     const readmeContent = '''
// Installation Instructions
// ========================

// 1. System Requirements:
//    - Windows 10 or later
//    - At least 100MB of free disk space

// 2. Installation Steps:
//    a. Extract all files to your preferred location
//    b. Keep all files and folders in the same directory
//    c. Do not modify the 'data' folder - it contains important application data
//    d. Double-click the .exe file to run the application

// 3. First-Time Setup:
//    - Use the default admin credentials to log in:
//      Username: admin
//      Password: [Your default password]
//    - Change the admin password immediately after first login

// 4. Troubleshooting:
//    - If the application doesn't start, ensure all .dll files are present
//    - If you get a database error, verify the 'data' folder exists and has proper permissions

// For technical support, contact your system administrator.
// ''';

//     await File(join(distPath, 'README.txt')).writeAsString(readmeContent);
//   }

//   static Future<void> _copyDirectory(String source, String destination) async {
//     final sourceDir = Directory(source);
//     final destDir = Directory(destination);

//     if (!await destDir.exists()) {
//       await destDir.create(recursive: true);
//     }

//     await for (final entity in sourceDir.list(recursive: false)) {
//       final newPath = join(destination, basename(entity.path));
//       if (entity is Directory) {
//         await _copyDirectory(entity.path, newPath);
//       } else if (entity is File) {
//         await entity.copy(newPath);
//       }
//     }
//   }
// }
