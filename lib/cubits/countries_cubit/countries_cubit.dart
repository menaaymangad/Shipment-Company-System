import 'package:flutter_bloc/flutter_bloc.dart';

import '../../helper/sql_helper.dart';
import '../../models/country_model.dart';
import 'countries_state.dart';


// Currency Cubit
// Country Cubit
class CountryCubit extends Cubit<CountryState> {
  final DatabaseHelper _databaseHelper;

  CountryCubit(this._databaseHelper) : super(CountryInitial());

  Future<void> fetchCountries() async {
    try {
      emit(CountryLoading());
      final countries = await _getAllCountries();
      emit(CountryLoaded(countries));
    } catch (e) {
      emit(CountryError('Failed to load countries: ${e.toString()}'));
    }
  }

  Future<List<Country>> _getAllCountries() async {
    final db = await _databaseHelper.database;
    final result = await db.query('countries');
    return result.map((map) => Country.fromMap(map)).toList();
  }

  Future<void> addCountry(Country country) async {
    try {
      final db = await _databaseHelper.database;
      await db.insert('countries', country.toMap());
      await fetchCountries();
    } catch (e) {
      emit(CountryError('Failed to add country: ${e.toString()}'));
    }
  }

  Future<void> updateCountry(Country country) async {
    try {
      final db = await _databaseHelper.database;
      await db.update('countries', country.toMap(),
          where: 'id = ?', whereArgs: [country.id]);
      await fetchCountries();
    } catch (e) {
      emit(CountryError('Failed to update country: ${e.toString()}'));
    }
  }

  Future<void> deleteCountry(int id) async {
    try {
      final db = await _databaseHelper.database;
      await db.delete('countries', where: 'id = ?', whereArgs: [id]);
      await fetchCountries();
    } catch (e) {
      emit(CountryError('Failed to delete country: ${e.toString()}'));
    }
  }
}
