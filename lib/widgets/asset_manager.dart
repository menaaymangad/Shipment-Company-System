import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:flutter/foundation.dart';

class AssetManager {
  // Base directory for all assets
  static const String _baseAssetsDir = 'assets';
  static const String _flagsDir = 'flags';

  // Get the absolute path to the assets directory
  static Future<String> get _assetsPath async {
    final exePath = Platform.resolvedExecutable;
    final appDir = path.dirname(exePath);
    final assetsDir = path.join(appDir, _baseAssetsDir, _flagsDir);

    // Ensure the directory exists
    final directory = Directory(assetsDir);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    return assetsDir;
  }

  // Save an image to the assets directory
  static Future<String> saveImageToAssets(
      String sourcePath, String fileName) async {
    try {
      final assetsDir = await _assetsPath;
      final extension = path.extension(sourcePath);
      final destinationPath = path.join(assetsDir, '$fileName$extension');

      // Create a copy of the file in the assets directory
      await File(sourcePath).copy(destinationPath);

      if (kDebugMode) {
        print('Image saved successfully to: $destinationPath');
      }

      return destinationPath;
    } catch (e) {
      if (kDebugMode) {
        print('Error saving image to assets: $e');
      }
      rethrow;
    }
  }

  // Delete an image from the assets directory
  static Future<void> deleteImageFromAssets(String imagePath) async {
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
        if (kDebugMode) {
          print('Image deleted successfully: $imagePath');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting image from assets: $e');
      }
      rethrow;
    }
  }

  // Get all saved flags
  static Future<List<String>> getAllFlags() async {
    try {
      final assetsDir = await _assetsPath;
      final directory = Directory(assetsDir);

      if (!await directory.exists()) {
        return [];
      }

      return directory
          .listSync()
          .whereType<File>()
          .map((file) => file.path)
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting flags: $e');
      }
      return [];
    }
  }

  // Get a specific flag by country name
  static Future<String?> getFlagByCountry(String countryName,
      {bool isCircular = true}) async {
    try {
      final assetsDir = await _assetsPath;
      final prefix = isCircular ? 'circular_' : 'square_';
      final pattern = '$prefix${countryName.replaceAll(' ', '_')}';

      final directory = Directory(assetsDir);
      if (!await directory.exists()) {
        return null;
      }

      final files = directory
          .listSync()
          .whereType<File>()
          .where((file) => path.basename(file.path).startsWith(pattern))
          .toList();

      return files.isEmpty ? null : files.first.path;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting flag for country $countryName: $e');
      }
      return null;
    }
  }

  // Check if a flag exists
  static Future<bool> flagExists(String countryName,
      {bool isCircular = true}) async {
    final flag = await getFlagByCountry(countryName, isCircular: isCircular);
    return flag != null;
  }
}
