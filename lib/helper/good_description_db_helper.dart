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
      return await db.delete(
        'goods_descriptions',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting goods description: $e');
      }
      rethrow;
    }
  }
}
