// cities_list.dart
import 'package:app/widgets/data_grid_list.dart';
import 'package:flutter/material.dart';
import 'package:app/models/city_model.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CitiesList extends StatelessWidget {
  final List<City> cities;
  final Function(City) onCitySelected;
  final String searchQuery;

  const CitiesList({
    super.key,
    required this.cities,
    required this.onCitySelected,
    this.searchQuery = '',
  });

  static final List<DataGridColumn<City>> columns = [
    DataGridColumn<City>(
      header: 'ID',
      getValue: (city) => city.id?.toString() ?? '',
      flex: 1,
    ),
    DataGridColumn<City>(
      header: 'City Name',
      getValue: (city) => city.cityName,
      flex: 2,
    ),
    DataGridColumn<City>(
      header: 'Country',
      getValue: (city) => city.country,
      flex: 2,
    ),
    DataGridColumn<City>(
      header: 'Has Agent',
      getValue: (city) => city.hasAgent ? '✓' : '✗',
      flex: 1,
    ),
  ];

  bool _searchPredicate(City city, String query) {
    final lowercaseQuery = query.toLowerCase();
    return city.cityName.toLowerCase().contains(lowercaseQuery) ||
        city.country.toLowerCase().contains(lowercaseQuery);
  }

  @override
  Widget build(BuildContext context) {
    return GenericDataGrid<City>(
      items: cities,
      columns: columns,
      onItemSelected: onCitySelected,
      searchQuery: searchQuery,
      searchPredicate: _searchPredicate,
      cellTextStyle: TextStyle(
        fontSize: 34.sp,
        color: Colors.black87,
      ),
      cellPadding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 32.w),
    );
  }
}
