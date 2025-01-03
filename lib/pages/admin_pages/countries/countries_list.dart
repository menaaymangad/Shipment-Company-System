import 'package:app/models/country_model.dart';
import 'package:app/widgets/data_grid_list.dart';
import 'package:flutter/material.dart';

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

  static final List<DataGridColumn<Country>> _columns = [
    DataGridColumn<Country>(
      header: 'ID',
      getValue: (country) => '${country.id ?? ''}',
      flex: 1,
    ),
    DataGridColumn<Country>(
      header: 'Country Name',
      getValue: (country) => country.countryName,
      flex: 2,
    ),
    DataGridColumn<Country>(
      header: 'Alpha Code',
      getValue: (country) => country.alpha2Code,
      flex: 2,
    ),
    DataGridColumn<Country>(
      header: 'Zip Code Digit 1',
      getValue: (country) => country.zipCodeDigit1,
      flex: 2,
    ),
    DataGridColumn<Country>(
      header: 'Zip Code Digit 2',
      getValue: (country) => country.zipCodeDigit2,
      flex: 2,
    ),
    DataGridColumn<Country>(
      header: 'Zip Code Text',
      getValue: (country) => country.zipCodeText,
      flex: 2,
    ),
    DataGridColumn<Country>(
      header: 'Max Weight (KG)',
      getValue: (country) => country.maxWeightKG.toString(),
      flex: 2,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return GenericDataGrid<Country>(
      items: countries,
      columns: _columns,
      onItemSelected: onCountrySelected,
      searchQuery: searchQuery,
      searchPredicate: _searchCountry,
    );
  }

  static bool _searchCountry(Country country, String query) {
    final lowercaseQuery = query.toLowerCase();
    return country.countryName.toLowerCase().contains(lowercaseQuery) ||
        country.currency.toLowerCase().contains(lowercaseQuery) ||
        country.alpha2Code.toLowerCase().contains(lowercaseQuery);
  }
}
