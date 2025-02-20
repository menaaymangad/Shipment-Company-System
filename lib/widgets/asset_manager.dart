import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class AssetManager {
  static Future<Directory> ensureAssetsDirectoryExists() async {
    try {
      // Get the executable directory
      final exePath = Platform.resolvedExecutable;
      final appDir = path.dirname(exePath);

      if (kDebugMode) {
        print('Application directory: $appDir');
      }

      // Create the full path for assets/flags
      final assetDir = Directory(path.join(appDir, 'assets', 'flags'));

      if (kDebugMode) {
        print('Attempting to create directory at: ${assetDir.path}');
      }

      // Check if directory exists
      final exists = await assetDir.exists();
      if (kDebugMode) {
        print('Directory exists: $exists');
      }

      // Create if it doesn't exist
      if (!exists) {
        final createdDir = await assetDir.create(recursive: true);
        if (kDebugMode) {
          print('Created directory at: ${createdDir.path}');
        }
        return createdDir;
      }

      return assetDir;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Error creating assets directory: $e');
        print('Stack trace: $stackTrace');
      }
      rethrow;
    }
  }

static Future<String> saveImageToAssets(
      String sourceImagePath, String fileName) async {
    try {
      if (kDebugMode) {
        print('Attempting to save image from: $sourceImagePath');
      }

      // Get the application documents directory
      final appDir = await getApplicationDocumentsDirectory();

      // Create the flags directory if it doesn't exist
      final flagsDir = Directory('${appDir.path}/assets/flags');
      if (!await flagsDir.exists()) {
        await flagsDir.create(recursive: true);
      }

      // Generate unique filename
      final extension = path.extension(sourceImagePath);
      final uniqueFileName = '$fileName$extension';

      // Create destination path
      final destinationPath = path.join(flagsDir.path, uniqueFileName);

      if (kDebugMode) {
        print('Saving image to: $destinationPath');
      }

      // Copy the file
      await File(sourceImagePath).copy(destinationPath);

      // Return the asset path format
      return 'assets/flags/$uniqueFileName';
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Error saving image to assets: $e');
        print('Stack trace: $stackTrace');
      }
      rethrow;
    }
  }
  static Future<void> deleteImageFromAssets(String imagePath) async {
    try {
      if (kDebugMode) {
        print('Attempting to delete image at: $imagePath');
      }

      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
        if (kDebugMode) {
          print('Image deleted successfully');
        }
      } else {
        if (kDebugMode) {
          print('Image file does not exist: $imagePath');
        }
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Error deleting image from assets: $e');
        print('Stack trace: $stackTrace');
      }
      rethrow;
    }
  }
}
