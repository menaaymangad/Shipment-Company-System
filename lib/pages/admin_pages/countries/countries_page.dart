
import 'package:app/cubits/countries_cubit/countries_cubit.dart';
import 'package:app/cubits/countries_cubit/countries_state.dart';
import 'package:app/cubits/currencies_cubit/currencies_cubit.dart';
import 'package:app/cubits/currencies_cubit/currencies_state.dart';
import 'package:app/models/country_model.dart';
import 'package:app/pages/admin_pages/countries/countries_list.dart';
import 'package:app/widgets/page_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CountriesPage extends StatefulWidget {
  const CountriesPage({
    super.key,
  });

  @override
  State<CountriesPage> createState() => _CountriesPageState();
}

class _CountriesPageState extends State<CountriesPage> {
  final TextEditingController _searchController = TextEditingController();
  final Map<String, TextEditingController> _controllers = {
    'countryId': TextEditingController(),
    'countryName': TextEditingController(),
    'alpha2Code': TextEditingController(),
    'zipCodeDigit1': TextEditingController(),
    'zipCodeDigit2': TextEditingController(),
    'zipCodeText': TextEditingController(),
    'currencyRate': TextEditingController(),
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  
  };

  String _selectedCurrency = '';
  Country? _selectedCountry;
  bool _hasAgent = false;

  @override
  void initState() {
    super.initState();
    context.read<CountryCubit>().fetchCountries();
    context.read<CurrencyCubit>().fetchCurrencies();
    _restoreFormData();
  }

  @override
  void deactivate() {
    _saveFormData();
    super.deactivate();
  }

  void _saveFormData() {
    final formData = {
      'countryName': _controllers['countryName']!.text,
      'alpha2Code': _controllers['alpha2Code']!.text,
      'zipCodeDigit1': _controllers['zipCodeDigit1']!.text,
      'zipCodeDigit2': _controllers['zipCodeDigit2']!.text,
      'zipCodeText': _controllers['zipCodeText']!.text,
      'currencyRate': _controllers['currencyRate']!.text,
      
      'hasAgent': _hasAgent,
    
      'selectedCurrency': _selectedCurrency,
    };
    context.read<CountryFormCubit>().saveFormData(formData);
  }

  void _restoreFormData() {
    final formData = context.read<CountryFormCubit>().state;
    if (formData.isNotEmpty) {
      _controllers['countryName']!.text = formData['countryName'] ?? '';
      _controllers['alpha2Code']!.text = formData['alpha2Code'] ?? '';
      _controllers['zipCodeDigit1']!.text = formData['zipCodeDigit1'] ?? '';
      _controllers['zipCodeDigit2']!.text = formData['zipCodeDigit2'] ?? '';
      _controllers['zipCodeText']!.text = formData['zipCodeText'] ?? '';
      _controllers['currencyRate']!.text = formData['currencyRate'] ?? '';
  
      _hasAgent = formData['hasAgent'] ?? false;

      _selectedCurrency = formData['selectedCurrency'] ?? '';
      setState(() {});
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Data Grid Section using CountriesDataGrid
        Flexible(
          flex: 3,
          child: Card(
            margin: EdgeInsets.all(16.0.r),
            child: Column(
              children: [
                // Search Bar using PageUtils
                PageUtils.buildSearchBar(
                  onChanged: (query) => _filterCountries(query),
                  labelText: 'Search Countries',
                ),

                // Countries Data Grid
                Expanded(
                  child: BlocBuilder<CountryCubit, CountryState>(
                    builder: (context, state) {
                      if (state is CountryLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (state is CountryError) {
                        return Center(child: Text('Error: ${state.message}'));
                      }
                      if (state is CountryLoaded) {
                        return CountriesDataGrid(
                          countries: state.countries,
                          onCountrySelected: _handleCountrySelection,
                          searchQuery: _searchController.text,
                        );
                      }
                      return const Center(child: Text('No countries found'));
                    },
                  ),
                ),
              ],
            ),
          ),
        ),

        // Form Section
        Flexible(
          flex: 2,
          child: Card(
            margin: EdgeInsets.all(8.0.r),
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16.0.r),
              child: Column(
                children: [
                  _buildFormFields(),
               
                  PageUtils.buildActionButtons(
                    onAddPressed: () => _handleAddCountry(),
                    onUpdatePressed: _selectedCountry != null
                        ? () => _handleUpdateCountry()
                        : null,
                    onDeletePressed: _selectedCountry != null
                        ? () => _handleDeleteCountry()
                        : null,
                    onCancelPressed: _clearFields,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Section
        Text(
          'Country Information',
          style: TextStyle(
            fontSize: 32.sp,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
        SizedBox(height: 20.h),

        // Basic Info Section
        Row(
          children: [
            // Country ID and Name
            Expanded(
              child: PageUtils.buildTextField(
                controller: _controllers['countryId']!,
                labelText: 'Country ID',
                enabled: false,
              ),
            ),
            SizedBox(width: 16.w),
            Flexible(
              child: _buildAgentCheckbox(),
            ),
          ],
        ),
        SizedBox(height: 24.h),

        // Name and Code Section
        Row(
          children: [
            Expanded(
              child: PageUtils.buildTextField(
                controller: _controllers['countryName']!,
                labelText: 'Country Name',
                keyboardType: TextInputType.text,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: PageUtils.buildTextField(
                controller: _controllers['alpha2Code']!,
                labelText: 'Alpha-2 Code',
                keyboardType: TextInputType.text,
              ),
            ),
          ],
        ),
        SizedBox(height: 24.h),

        // Postal Code Section
        Container(
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Postal Code Information',
                style: TextStyle(
                  fontSize: 32.sp,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              SizedBox(height: 24.h),
              Row(
                children: [
                  Expanded(
                    child: PageUtils.buildTextField(
                      controller: _controllers['zipCodeDigit1']!,
                      labelText: 'Zip Code Digit 1',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: PageUtils.buildTextField(
                      controller: _controllers['zipCodeDigit2']!,
                      labelText: 'Zip Code Digit 2',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24.h),
              PageUtils.buildTextField(
                controller: _controllers['zipCodeText']!,
                labelText: 'Zip Code Text',
                keyboardType: TextInputType.text,
              ),
            ],
          ),
        ),
        SizedBox(height: 24.h),

        // Currency Section
        Container(
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Currency Information',
                style: TextStyle(
                  fontSize: 32.sp,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              SizedBox(height: 24.h),
              _buildCurrencyDropdown(),
              SizedBox(height: 24.h),
              PageUtils.buildTextField(
                controller: _controllers['currencyRate']!,
                labelText: 'Currency Rate',
                keyboardType: TextInputType.number,
                enabled: false,
              ),
            ],
          ),
        ),

      ],
    );
  }

  // Helper methods implementation...
  void _handleCountrySelection(Country country) {
    setState(() {
      _selectedCountry = country;
      _populateFormFields(country);
    });
  }

  void _clearFields() {
    context.read<CountryFormCubit>().clearFormData();

    _controllers.forEach((_, controller) => controller.clear());
    setState(() {
      _selectedCountry = null;
     
      _selectedCurrency = '';
      _hasAgent = false;
    });
  }
  // Add these methods to your _CountriesPageState class

  void _filterCountries(String query) {
    setState(() {
      _searchController.text = query;
    });
  }


  Future<void> _handleAddCountry() async {
    if (!_validateForm()) return;

    final country = _buildCountryFromForm();
    await context.read<CountryCubit>().addCountry(country);
    _clearFields();
  }

  Future<void> _handleUpdateCountry() async {
    if (_selectedCountry == null || !_validateForm()) return;

    final country = _buildCountryFromForm();
    await context.read<CountryCubit>().updateCountry(country);
    _clearFields();
  }

  Future<void> _handleDeleteCountry() async {
    if (_selectedCountry == null) return;

    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this country?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (mounted) {
        await context.read<CountryCubit>().deleteCountry(_selectedCountry!.id!);
      }
      _clearFields();
    }
  }

  Widget _buildAgentCheckbox() {
    return CheckboxListTile(
      title: const Text('Has Agent'),
      value: _hasAgent,
      onChanged: (bool? value) {
        setState(() {
          _hasAgent = value ?? false;
        });
      },
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildCurrencyDropdown() {
    return BlocBuilder<CurrencyCubit, CurrencyState>(
      builder: (context, state) {
        if (state is CurrencyLoaded) {
          return DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: 'Currency',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
            value: _selectedCurrency.isNotEmpty &&
                    state.currencies
                        .any((c) => c.id.toString() == _selectedCurrency)
                ? _selectedCurrency
                : null,
            items: state.currencies.map((currency) {
              return DropdownMenuItem<String>(
                value: currency.id.toString(),
                child: Text(currency.currencyName),
              );
            }).toList(),
            onChanged: (String? value) {
              if (value != null) {
                setState(() {
                  _selectedCurrency = value;
                  // Find the selected currency and update the rate
                  final selectedCurrency = state.currencies.firstWhere(
                    (currency) => currency.id.toString() == value,
                    orElse: () => state.currencies.first,
                  );
                  _controllers['currencyRate']?.text =
                      selectedCurrency.currencyAgainst1IraqiDinar.toString();
                });
              }
            },
          );
        }
        return const CircularProgressIndicator();
      },
    );
  }

  void _populateFormFields(Country country) {
    _controllers['countryId']?.text = country.id.toString();
    _controllers['countryName']?.text = country.countryName;
    _controllers['alpha2Code']?.text = country.alpha2Code;
    _controllers['zipCodeDigit1']?.text = country.zipCodeDigit1;
    _controllers['zipCodeDigit2']?.text = country.zipCodeDigit2;
    _controllers['zipCodeText']?.text = country.zipCodeText;
    _controllers['currencyRate']?.text = country.currencyAgainstIQD.toString();
   

    setState(() {
      _selectedCurrency = country.currency; // This should be the currency ID
      _hasAgent = country.hasAgent;
     
    });
  }

  bool _validateForm() {
    // Add your validation logic here
    if (_controllers['countryName']!.text.isEmpty ||
        _controllers['alpha2Code']!.text.isEmpty ||
        _selectedCurrency.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return false;
    }
    return true;
  }

  Country _buildCountryFromForm() {
    return Country(
      id: _selectedCountry?.id,
      countryName: _controllers['countryName']!.text,
      alpha2Code: _controllers['alpha2Code']!.text,
      zipCodeDigit1: _controllers['zipCodeDigit1']!.text,
      zipCodeDigit2: _controllers['zipCodeDigit2']!.text,
      zipCodeText: _controllers['zipCodeText']!.text,
      currency: _selectedCurrency,
      currencyAgainstIQD:
          double.tryParse(_controllers['currencyRate']!.text) ?? 0.0,
      
      hasAgent: _hasAgent,
    
    );
  }
}

class CountryFormCubit extends Cubit<Map<String, dynamic>> {
  CountryFormCubit() : super({});

  void saveFormData(Map<String, dynamic> formData) => emit(formData);
  void clearFormData() => emit({});
}
