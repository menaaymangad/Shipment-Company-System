

import '../../models/city_model.dart';

abstract class CityState {}

class CityInitialState extends CityState {}

class CityLoadingState extends CityState {}

class CityLoadedState extends CityState {
  final List<City> cities;
  CityLoadedState(this.cities);
}

class CityErrorState extends CityState {
  final String errorMessage;
  CityErrorState(this.errorMessage);
}
