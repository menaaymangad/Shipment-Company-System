// // bin/create_distribution.dart

// import 'dart:io';
// import 'package:path/path.dart' as path;

// void main() async {
//   print('Starting distribution package creation...');

//   try {
//     // Ensure we're in the project root directory
//     final currentDir = Directory.current;
//     print('Working directory: ${currentDir.path}');

//     // Build Windows application
//     print('Building Windows application...');
//     final buildResult = await Process.run('flutter', ['build', 'windows']);
//     if (buildResult.exitCode != 0) {
//       print('Build output: ${buildResult.stdout}');
//       print('Build error: ${buildResult.stderr}');
//       throw Exception('Flutter build failed');
//     }
//     print('Windows build completed successfully');

//     // Create dist directory
//     final distDir = Directory('dist');
//     if (await distDir.exists()) {
//       await distDir.delete(recursive: true);
//     }
//     await distDir.create();
//     print('Created dist directory at: ${distDir.absolute.path}');

//     // Copy build files - Updated path to include x64
//     final buildDir =
//         Directory(path.join('build', 'windows', 'x64', 'runner', 'Release'));
//     if (!await buildDir.exists()) {
//       throw Exception(
//           'Build directory not found at: ${buildDir.absolute.path}');
//     }

//     print('Copying application files...');
//     await _copyBuildFiles(buildDir, distDir);

//     // Create data directory
//     final dataDir = Directory(path.join(distDir.path, 'data'));
//     await dataDir.create();
//     print('Created data directory at: ${dataDir.absolute.path}');

//     // Copy database file
//     final dbSource = File('assets/euknet_transport.db');
//     if (await dbSource.exists()) {
//       final dbDest = File(path.join(dataDir.path, 'euknet_transport.db'));
//       await dbSource.copy(dbDest.path);
//       print('Database copied to: ${dbDest.path}');
//     } else {
//       print('Warning: Database file not found at: ${dbSource.absolute.path}');
//       print('Make sure your database file is in the correct location');

//       // Print current directory contents for debugging
//       print('\nChecking available files in assets directory:');
//       final assetsDir = Directory('assets');
//       if (await assetsDir.exists()) {
//         await for (final entity in assetsDir.list()) {
//           print('Found: ${entity.path}');
//         }
//       } else {
//         print('Assets directory not found!');
//       }
//     }

//     // Create README
//     await _createReadme(distDir.path);
//     print('Created README file');

//     print('\nDistribution package created successfully!');
//     print('Location: ${distDir.absolute.path}');
//     print(
//         '\nPlease check the contents of the dist folder to ensure everything is correct.');
//   } catch (e, stackTrace) {
//     print('\nError creating distribution:');
//     print(e);
//     print('\nStack trace:');
//     print(stackTrace);
//     exit(1);
//   }
// }

// Future<void> _copyBuildFiles(Directory source, Directory dest) async {
//   print('\nCopying files from: ${source.path}');
//   print('Copying files to: ${dest.path}');

//   await for (final entity in source.list()) {
//     if (entity is File) {
//       final fileName = path.basename(entity.path);
//       if (fileName.endsWith('.exe') || fileName.endsWith('.dll')) {
//         final destFile = File(path.join(dest.path, fileName));
//         await entity.copy(destFile.path);
//         print('Copied: $fileName');
//       }
//     } else if (entity is Directory) {
//       // Copy directories that might contain necessary files
//       final dirName = path.basename(entity.path);
//       if (dirName != 'data') {
//         // Skip data directory as we handle it separately
//         final destDir = Directory(path.join(dest.path, dirName));
//         await destDir.create(recursive: true);
//         await _copyDirectory(entity, destDir);
//       }
//     }
//   }
// }

// Future<void> _copyDirectory(Directory source, Directory dest) async {
//   await for (final entity in source.list(recursive: false)) {
//     final newPath = path.join(dest.path, path.basename(entity.path));
//     if (entity is Directory) {
//       final newDir = Directory(newPath);
//       await newDir.create();
//       await _copyDirectory(entity, newDir);
//     } else if (entity is File) {
//       await entity.copy(newPath);
//       print('Copied: ${path.basename(entity.path)}');
//     }
//   }
// }

// Future<void> _createReadme(String distPath) async {
//   final readme = '''
// EUKNET Transport Application
// ===========================

// Installation Instructions:
// 1. Extract all files to your preferred location
// 2. Keep all files and folders in the same directory structure
// 3. The 'data' folder must remain in the same directory as the executable
// 4. Double-click the executable to run the application

// Important Notes:
// - Do not modify or delete the 'data' folder
// - Ensure all .dll files remain with the executable
// - For first-time login, use your provided credentials

// Directory Structure:
// - app.exe (main application)
// - data/
//   - euknet_transport.db (database file)
// - *.dll (required system files)

// For technical support, please contact your system administrator.

// Last updated: ${DateTime.now().toString()}
// ''';

//   final readmeFile = File(path.join(distPath, 'README.txt'));
//   await readmeFile.writeAsString(readme);
//   print('Created README at: ${readmeFile.absolute.path}');
// }
