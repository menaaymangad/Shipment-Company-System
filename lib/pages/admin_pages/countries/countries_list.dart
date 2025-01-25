import 'package:flutter/material.dart';
import 'package:app/models/country_model.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CountriesDataGrid extends StatelessWidget {
  final List<Country> countries;
  final Function(Country) onCountrySelected;
  final String searchQuery;

  const CountriesDataGrid({
    super.key,
    required this.countries,
    required this.onCountrySelected,
    this.searchQuery = '',
  });

  List<Country> _filterCountries(List<Country> countries, String query) {
    if (query.isEmpty) return countries;

    return countries.where((country) {
      final searchLower = query.toLowerCase();
      return country.countryName.toLowerCase().contains(searchLower) ||
          country.currency.toLowerCase().contains(searchLower) ||
          country.alpha2Code.toLowerCase().contains(searchLower);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredCountries = _filterCountries(countries, searchQuery);

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
          columnSpacing: 16.w,
          dataRowMinHeight: 56.h,
          headingRowColor: WidgetStateProperty.all(Colors.grey[100]),
          headingTextStyle: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold),
          dataTextStyle: TextStyle(fontSize: 18.sp),
          columns: [
            DataColumn(label: Text('ID')),
            DataColumn(label: Text('Country Name')),
            DataColumn(label: Text('Alpha Code')),
            DataColumn(label: Text('Zip Code Digit 1')),
            DataColumn(label: Text('Zip Code Digit 2')),
            DataColumn(label: Text('Zip Code Text')),
            DataColumn(label: Text('Max Weight (KG)')),
          ],
          rows: filteredCountries.map((country) {
            return DataRow(
              color: WidgetStateProperty.resolveWith<Color?>(
                (Set<WidgetState> states) {
                  return states.contains(WidgetState.selected)
                      ? Colors.grey[300]
                      : null;
                },
              ),
              cells: [
                DataCell(Text('${country.id ?? ""}')),
                DataCell(Text(country.countryName)),
                DataCell(Text(country.alpha2Code)),
                DataCell(Text(country.zipCodeDigit1)),
                DataCell(Text(country.zipCodeDigit2)),
                DataCell(Text(country.zipCodeText)),
                DataCell(Text(country.maxWeightKG.toString())),
              ],
              onSelectChanged: (_) => onCountrySelected(country),
            );
          }).toList(),
        ),
      ),
    );
  }
}