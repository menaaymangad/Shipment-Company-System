import 'package:flutter/material.dart';
import 'package:app/models/currency_model.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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

  List<Currency> _filterCurrencies(List<Currency> currencies, String query) {
    if (query.isEmpty) return currencies;

    return currencies.where((currency) {
      final searchLower = query.toLowerCase();
      return currency.currencyName.toLowerCase().contains(searchLower) ||
          currency.currencyAgainst1IraqiDinar.toString().contains(searchLower);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredCurrencies = _filterCurrencies(currencies, searchQuery);

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
          columnSpacing: 100.w,
          dataRowMinHeight: 56.h,
          headingRowColor: WidgetStateProperty.all(Colors.grey[100]),
          headingTextStyle:
              TextStyle(fontSize: 32.sp, fontWeight: FontWeight.bold),
          dataTextStyle: TextStyle(fontSize: 18.sp),
          columns: [
            DataColumn(label: Text('ID')),
            DataColumn(label: Text('Currency Name')),
            DataColumn(label: Text('Rate Against 1 Iraqi Dinar')),
          ],
          rows: filteredCurrencies.map((currency) {
            return DataRow(
              color: WidgetStateProperty.resolveWith<Color?>(
                (Set<WidgetState> states) {
                  return states.contains(WidgetState.selected)
                      ? Colors.grey[300]
                      : null;
                },
              ),
              cells: [
                DataCell(Text('${currency.id ?? ""}')),
                DataCell(Text(currency.currencyName)),
                DataCell(Text(currency.currencyAgainst1IraqiDinar.toString())),
              ],
              onSelectChanged: (_) => onCurrencySelected(currency),
            );
          }).toList(),
        ),
      ),
    );
  }
}
