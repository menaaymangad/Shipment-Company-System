import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/good_description_model.dart';
import 'sql_helper.dart';

extension GoodsDescriptionDatabaseHelper on DatabaseHelper {
  Future<int> insertGoodsDescription(GoodsDescription goodsDescription) async {
    final db = await database;
    return await db.insert(
      'goods_descriptions',
      goodsDescription.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<GoodsDescription>> getAllGoodsDescriptions() async {
    try {
      final db = await database;
      final result = await db.query('goods_descriptions');
      return result.map((map) => GoodsDescription.fromMap(map)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting all goods descriptions: $e');
      }
      rethrow;
    }
  }

  Future<int> updateGoodsDescription(GoodsDescription description) async {
    try {
      final db = await database;
      return await db.update(
        'goods_descriptions',
        {
          'descriptionEn': description.descriptionEn,
          'descriptionAr': description.descriptionAr,
          'weight': description.weight
        },
        where: 'id = ?',
        whereArgs: [description.id],
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error updating goods description: $e');
      }
      rethrow;
    }
  }

  Future<int> deleteGoodsDescription(int id) async {
    try {
      final db = await database;

      // Delete the item
      final result = await db.delete(
        'goods_descriptions',
        where: 'id = ?',
        whereArgs: [id],
      );

      // Renumber the remaining items
      await renumberGoodsDescriptions();

      return result;
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting goods description: $e');
      }
      rethrow;
    }
  }

  Future<void> renumberGoodsDescriptions() async {
    try {
      final db = await database;

      // Fetch all goods descriptions ordered by their current ID
      final List<Map<String, dynamic>> results = await db.query(
        'goods_descriptions',
        orderBy: 'id ASC',
      );

      // Renumber the IDs starting from 1
      for (int i = 0; i < results.length; i++) {
        final int oldId = results[i]['id'];
        final int newId = i + 1;

        if (oldId != newId) {
          await db.update(
            'goods_descriptions',
            {'id': newId},
            where: 'id = ?',
            whereArgs: [oldId],
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error renumbering goods descriptions: $e');
      }
      rethrow;
    }
  }
}
