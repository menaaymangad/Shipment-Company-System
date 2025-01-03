
import 'package:app/models/branches_model.dart';

import 'sql_helper.dart';

extension BranchDatabaseHelper on DatabaseHelper {
  // Insert a new branch
  Future<int> insertBranch(Branch branch) async {
    final db = await database;
    return await db.insert('branches', branch.toMap());
  }

  // Get all branches
  Future<List<Branch>> getAllBranches() async {
    final db = await database;
    final result = await db.query('branches');
    return result.map((map) => Branch.fromMap(map)).toList();
  }

  // Get a specific branch by ID
  Future<Branch?> getBranch(int id) async {
    final db = await database;
    final result = await db.query('branches', where: 'id = ?', whereArgs: [id]);
    if (result.isEmpty) return null;
    return Branch.fromMap(result.first);
  }

  // Update an existing branch
  Future<int> updateBranch(Branch branch) async {
    final db = await database;
    return await db.update('branches', branch.toMap(),
        where: 'id = ?', whereArgs: [branch.id]);
  }

  // Delete a branch
  Future<int> deleteBranch(int id) async {
    final db = await database;
    return await db.delete('branches', where: 'id = ?', whereArgs: [id]);
  }
}
