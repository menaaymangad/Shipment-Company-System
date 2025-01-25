import 'package:app/cubits/currencies_cubit/currencies_cubit.dart';
import 'package:app/cubits/currencies_cubit/currencies_state.dart';
import 'package:app/models/currency_model.dart';
import 'package:app/pages/admin_pages/currencies/currencies_list.dart';
import 'package:app/widgets/page_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CurrenciesPage extends StatefulWidget {
  const CurrenciesPage({super.key,});


  @override
  State<CurrenciesPage> createState() => _CurrenciesPageState();
}

class _CurrenciesPageState extends State<CurrenciesPage>  {
  final _idController = TextEditingController();
  final _nameController = TextEditingController();
  final _rateController = TextEditingController();
  Currency? _selectedCurrency;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
    _restoreFormData();
  }

  @override
  void deactivate() {
    _saveFormData();
    super.deactivate();
  }

  void _saveFormData() {
    final formData = {
      'currencyName': _nameController.text,
      'currencyRate': _rateController.text,
    };
    context.read<CurrencyFormCubit>().saveFormData(formData);
  }

  void _restoreFormData() {
    final formData = context.read<CurrencyFormCubit>().state;
    if (formData.isNotEmpty) {
      _nameController.text = formData['currencyName'] ?? '';
      _rateController.text = formData['currencyRate'] ?? '';
    }
  }

 
  void _fetchInitialData() {
    context.read<CurrencyCubit>().fetchCurrencies();
  }

  void _resetForm() {
    context.read<CurrencyFormCubit>().clearFormData();
    setState(() {
      _idController.clear();
      _nameController.clear();
      _rateController.clear();
      _selectedCurrency = null;
    });
  }

  void _populateForm(Currency currency) {
    setState(() {
      _selectedCurrency = currency;
      _idController.text = currency.id.toString();
      _nameController.text = currency.currencyName;
      _rateController.text = currency.currencyAgainst1IraqiDinar.toString();
    });
  }

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildDataGridSection(),
        _buildFormSection(),
      ],
    );
  }

  Widget _buildDataGridSection() {
    return Flexible(
      flex: 3,
      child: Card(
        margin: EdgeInsets.all(16.0.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageUtils.buildSearchBar(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
            Expanded(
              child: BlocBuilder<CurrencyCubit, CurrencyState>(
                builder: (context, state) {
                  if (state is CurrencyLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is CurrencyError) {
                    return Center(child: Text('Error: ${state.message}'));
                  }
                  if (state is CurrencyLoaded) {
                    return CurrencyDataGrid(
                      currencies: state.currencies,
                      onCurrencySelected: _populateForm,
                      searchQuery: _searchQuery,
                    );
                  }
                  return const Center(child: Text('No currencies found'));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormSection() {
    return Flexible(
      flex: 2,
      child: Card(
        margin: const EdgeInsets.all(8.0),
        child: Padding(
          padding: EdgeInsets.all(16.r),
          child: Column(
            children: [
              PageUtils.buildTextField(
                controller: _idController,
                labelText: 'Currency ID',
                enabled: false,
              ),
              PageUtils.buildTextField(
                controller: _nameController,
                labelText: 'Currency Name',
              ),
              PageUtils.buildTextField(
                controller: _rateController,
                labelText: 'Currency against 1 Iraqi Dinar',
                keyboardType: TextInputType.number,
              ),
              const Spacer(),
              PageUtils.buildActionButtons(
               
                onAddPressed: () {
                  final currency = Currency(
                    currencyName: _nameController.text,
                    currencyAgainst1IraqiDinar:
                        double.parse(_rateController.text),
                  );
                  context.read<CurrencyCubit>().addCurrency(currency);
                  _resetForm();
                },
                onUpdatePressed: _selectedCurrency != null
                    ? () {
                        final updatedCurrency = Currency(
                          id: _selectedCurrency!.id,
                          currencyName: _nameController.text,
                          currencyAgainst1IraqiDinar:
                              double.parse(_rateController.text),
                        );
                        context
                            .read<CurrencyCubit>()
                            .updateCurrency(updatedCurrency);
                        _resetForm();
                      }
                    : null,
                onDeletePressed: _selectedCurrency != null
                    ? () {
                        context
                            .read<CurrencyCubit>()
                            .deleteCurrency(_selectedCurrency!.id!);
                        _resetForm();
                      }
                    : null,
                onCancelPressed: _resetForm,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
class CurrencyFormCubit extends Cubit<Map<String, dynamic>> {
  CurrencyFormCubit() : super({});

  void saveFormData(Map<String, dynamic> formData) => emit(formData);
  void clearFormData() => emit({});
}
