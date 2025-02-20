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

  // Get all cities with POST option enabled
  Future<List<City>> getPostCities() async {
    final db = await database;
    final result = await db.query('cities',
        where: 'isPost = ?', whereArgs: [1], orderBy: 'country, cityName');
    return result.map((map) => City.fromMap(map)).toList();
  }

  // Get all cities with Agent option (but not POST)
  Future<List<City>> getAgentOnlyCities() async {
    final db = await database;
    final result = await db.query('cities',
        where: 'hasAgent = ? AND isPost = ?',
        whereArgs: [1, 0],
        orderBy: 'country, cityName');
    return result.map((map) => City.fromMap(map)).toList();
  }

  // Get cities by country
  Future<List<City>> getCitiesByCountry(String country) async {
    final db = await database;
    final result = await db.query('cities',
        where: 'country = ?', whereArgs: [country], orderBy: 'cityName');
    return result.map((map) => City.fromMap(map)).toList();
  }

  // Get all unique countries
  Future<List<String>> getUniqueCountries() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT DISTINCT country 
      FROM cities 
      ORDER BY country
    ''');
    return result.map((map) => map['country'] as String).toList();
  }

  // Search cities by name or country
  Future<List<City>> searchCities(String query) async {
    final db = await database;
    final result = await db.query('cities',
        where: 'cityName LIKE ? OR country LIKE ?',
        whereArgs: ['%$query%', '%$query%'],
        orderBy: 'country, cityName');
    return result.map((map) => City.fromMap(map)).toList();
  }

  // Bulk insert cities
  Future<void> bulkInsertCities(List<City> cities) async {
    final db = await database;
    final batch = db.batch();

    for (final city in cities) {
      batch.insert('cities', city.toMap());
    }

    await batch.commit(noResult: true);
  }
}
