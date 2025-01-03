// currency_data_grid.dart
import 'package:app/widgets/data_grid_list.dart';
import 'package:flutter/material.dart';
import '../../../models/currency_model.dart';

class CurrencyDataGrid extends StatelessWidget {
  final List<Currency> currencies;
  final Function(Currency) onCurrencySelected;
  final String searchQuery;

  const CurrencyDataGrid({
    super.key,
    required this.currencies,
    required this.onCurrencySelected,
    this.searchQuery = '',
  });

  @override
  Widget build(BuildContext context) {
    return GenericDataGrid<Currency>(
      items: currencies,
      onItemSelected: onCurrencySelected,
      searchQuery: searchQuery,
      searchPredicate: (currency, query) {
        final lowercaseQuery = query.toLowerCase();
        return currency.currencyName.toLowerCase().contains(lowercaseQuery) ||
            currency.currencyAgainst1IraqiDinar
                .toString()
                .contains(lowercaseQuery);
      },
      columns: [
        DataGridColumn<Currency>(
          header: 'ID',
          getValue: (currency) => '${currency.id ?? ''}',
          flex: 1,
        ),
        DataGridColumn<Currency>(
          header: 'Currency Name',
          getValue: (currency) => currency.currencyName,
          flex: 2,
        ),
        DataGridColumn<Currency>(
          header: 'Rate Against 1 Iraqi Dinar',
          getValue: (currency) =>
              currency.currencyAgainst1IraqiDinar.toString(),
          flex: 2,
        ),
      ],
    );
  }
}
