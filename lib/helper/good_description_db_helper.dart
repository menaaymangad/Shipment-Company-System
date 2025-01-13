import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/good_description_model.dart';
import 'sql_helper.dart';

extension GoodsDescriptionDatabaseHelper on DatabaseHelper {


Future<int> insertGoodsDescription(
      String descriptionEn, String descriptionAr,double weight) async {
    try {
      final db = await database;
      final descriptionMap = {
        'descriptionEn': descriptionEn.trim(),
        'descriptionAr': descriptionAr.trim(),
        'weight': weight, 
      };
      return await db.insert(
        'goods_descriptions',
        descriptionMap,
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error inserting goods description: $e');
      }
      rethrow;
    }
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
