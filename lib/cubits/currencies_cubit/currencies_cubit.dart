import 'package:flutter_bloc/flutter_bloc.dart';

import '../../helper/sql_helper.dart';
import '../../models/currency_model.dart';
import 'currencies_state.dart';

class CurrencyCubit extends Cubit<CurrencyState> {
  final DatabaseHelper _databaseHelper;

  CurrencyCubit(this._databaseHelper) : super(CurrencyInitial());

  Future<void> fetchCurrencies() async {
    try {
      emit(CurrencyLoading());
      final currencies = await _getAllCurrencies();
      emit(CurrencyLoaded(currencies));
    } catch (e) {
      emit(CurrencyError('Failed to load currencies: ${e.toString()}'));
    }
  }

  Future<List<Currency>> _getAllCurrencies() async {
    final db = await _databaseHelper.database;
    final result = await db.query('currencies');
    return result.map((map) => Currency.fromMap(map)).toList();
  }

  Future<void> addCurrency(Currency currency) async {
    try {
      final db = await _databaseHelper.database;
      await db.insert('currencies', currency.toMap());
      await fetchCurrencies();
    } catch (e) {
      emit(CurrencyError('Failed to add currency: ${e.toString()}'));
    }
  }

  Future<void> updateCurrency(Currency currency) async {
    try {
      final db = await _databaseHelper.database;
      await db.update('currencies', currency.toMap(),
          where: 'id = ?', whereArgs: [currency.id]);
      await fetchCurrencies();
    } catch (e) {
      emit(CurrencyError('Failed to update currency: ${e.toString()}'));
    }
  }

  Future<void> deleteCurrency(int id) async {
    try {
      final db = await _databaseHelper.database;
      await db.delete('currencies', where: 'id = ?', whereArgs: [id]);
      await fetchCurrencies();
    } catch (e) {
      emit(CurrencyError('Failed to delete currency: ${e.toString()}'));
    }
  }
}
