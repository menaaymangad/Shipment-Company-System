import 'package:app/helper/sql_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class DatabaseDeletionButton extends StatelessWidget {
  final VoidCallback? onDeleted;
  final DatabaseHelper dbHelper;

  // Removed const constructor since DatabaseHelper isn't const
  DatabaseDeletionButton({super.key, this.onDeleted, DatabaseHelper? dbHelper})
      : dbHelper = dbHelper ?? DatabaseHelper();

  Future<void> _resetDatabase(BuildContext context) async {
    try {
      // Ensure database is initialized before reset
      await dbHelper.ensureInitialized();

      // Close existing connections
      await DatabaseHelper.closeDatabase();

      // Reset database
      await dbHelper.resetDatabase();

      if (!context.mounted) return;

      // Show success dialog and trigger callback
      await _showSuccessDialog(context);
      onDeleted?.call();
    } catch (e) {
      if (kDebugMode) {
        print('Error resetting database: $e');
      }

      if (!context.mounted) return;
      await _showErrorDialog(context, e.toString());
    }
  }

  Future<void> _showSuccessDialog(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Database Reset'),
        content: const Text('Database reset successful. All tables cleared.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _showErrorDialog(BuildContext context, String error) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Failed'),
        content: SingleChildScrollView(
          child: Text(error, style: const TextStyle(color: Colors.red)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => _showConfirmDialog(context),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      ),
      child:
          const Text('Reset Database', style: TextStyle(color: Colors.white)),
    );
  }

  Future<void> _showConfirmDialog(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Reset'),
        content: const Text(
          'This will delete ALL data. This action cannot be undone.',
          style: TextStyle(color: Colors.red),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _resetDatabase(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}
