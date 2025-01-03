
import '../models/city_model.dart';
import 'sql_helper.dart';

extension CityDatabaseHelper on DatabaseHelper {
  // Insert a new city
   Future<int> insertCity(City city) async {
    final db = await database;
    return await db.insert('cities', city.toMap());
  }

  // Update an existing city
  Future<int> updateCity(City city) async {
    final db = await database;
    return await db
        .update('cities', city.toMap(), where: 'id = ?', whereArgs: [city.id]);
  }

  // Get all cities
  Future<List<City>> getAllCities() async {
    final db = await database;
    final result = await db.query('cities');
    return result.map((map) => City.fromMap(map)).toList();
  }

  // Get a specific city by ID
  Future<City?> getCity(int id) async {
    final db = await database;
    final result = await db.query('cities', where: 'id = ?', whereArgs: [id]);
    if (result.isEmpty) return null;
    return City.fromMap(result.first);
  }

  

  // Delete a city
  Future<int> deleteCity(int id) async {
    final db = await database;
    return await db.delete('cities', where: 'id = ?', whereArgs: [id]);
  }
}
