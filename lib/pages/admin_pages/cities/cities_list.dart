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

  List<City> _filterCities(List<City> cities, String query) {
    if (query.isEmpty) return cities;

    return cities.where((city) {
      final searchLower = query.toLowerCase();
      return city.cityName.toLowerCase().contains(searchLower) ||
          city.country.toLowerCase().contains(searchLower);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredCities = _filterCities(cities, searchQuery);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(40),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          showCheckboxColumn: false,
          columnSpacing: 120.w,
          dataRowMinHeight: 56.h,
          headingRowColor: WidgetStateProperty.all(Colors.grey[100]),
          headingTextStyle:
              TextStyle(fontSize: 32.sp, fontWeight: FontWeight.bold),
          dataTextStyle: TextStyle(fontSize: 18.sp),
          columns: [
            DataColumn(label: Text('ID')),
            DataColumn(label: Text('City Name')),
            DataColumn(label: Text('Country')),
            DataColumn(label: Text('Has Agent')),
          ],
          rows: filteredCities.map((city) {
            return DataRow(
              color: WidgetStateProperty.resolveWith<Color?>(
                (Set<WidgetState> states) {
                  return states.contains(WidgetState.selected)
                      ? Colors.grey[300]
                      : null;
                },
              ),
              cells: [
                DataCell(Text('${city.id ?? ""}')),
                DataCell(Text(city.cityName)),
                DataCell(Text(city.country)),
                DataCell(Text(city.hasAgent ? '✓' : '✗')),
              ],
              onSelectChanged: (_) => onCitySelected(city),
            );
          }).toList(),
        ),
      ),
    );
  }
}
