// Example usage in a widget
import 'package:app/helper/send_db_helper.dart';
import 'package:flutter/material.dart';

class DeleteRecordsButton extends StatelessWidget {
  const DeleteRecordsButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        try {
          final db = SendRecordDatabaseHelper();

          // Show confirmation dialog
          final confirm = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Reset Database'),
              content: Text(
                  'This will reset the database to its initial state. Continue?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text('Reset'),
                ),
              ],
            ),
          );

          if (confirm != true) return;

          // Reset database
          await db.resetDatabase();

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Database reset successful'),
            ),
          );
        } catch (e) {
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error resetting database: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Text('Reset Database'),
    );
  }
}
