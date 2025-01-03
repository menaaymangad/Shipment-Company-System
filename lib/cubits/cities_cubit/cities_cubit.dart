import 'package:app/helper/cities_db_helper.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../helper/sql_helper.dart';
import '../../models/city_model.dart';
import 'cities_state.dart';


class CityCubit extends Cubit<CityState> {
  final DatabaseHelper _databaseHelper;

  CityCubit(this._databaseHelper) : super(CityInitialState());

  Future<void> fetchCities() async {
    try {
      emit(CityLoadingState());
      final cities = await _getCities();
      emit(CityLoadedState(cities));
    } catch (e) {
      emit(CityErrorState('Failed to load cities: ${e.toString()}'));
    }
  }

  Future<List<City>> _getCities() async {
    return await _databaseHelper.getAllCities();
  }

  Future<void> addCity(City city) async {
    try {
      await _databaseHelper.insertCity(city);
      await fetchCities();
    } catch (e) {
      emit(CityErrorState('Failed to add city: ${e.toString()}'));
    }
  }

  Future<void> updateCity(City city) async {
    try {
      await _databaseHelper.updateCity(city);
      await fetchCities();
    } catch (e) {
      emit(CityErrorState('Failed to update city: ${e.toString()}'));
    }
  }

  Future<void> deleteCity(int cityId) async {
    try {
      await _databaseHelper.deleteCity(cityId);
      await fetchCities();
    } catch (e) {
      emit(CityErrorState('Failed to delete city: ${e.toString()}'));
    }
  }
}
