import 'package:app/cubits/cities_cubit/cities_cubit.dart';
import 'package:app/cubits/cities_cubit/cities_state.dart';
import 'package:app/cubits/countries_cubit/countries_cubit.dart';
import 'package:app/cubits/countries_cubit/countries_state.dart';
import 'package:app/models/city_model.dart';
import 'package:app/widgets/page_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'cities_list.dart';

class CitiesPage extends StatefulWidget {
  const CitiesPage({
    super.key,
  });
  static String id = 'cities';

  @override
  State<CitiesPage> createState() => _CitiesPageState();
}

class _CitiesPageState extends State<CitiesPage> with RouteAware {
  String _searchQuery = '';
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _cityNameController = TextEditingController();
  final TextEditingController _doorToDoorPriceController =
      TextEditingController();
  final TextEditingController _priceKgController = TextEditingController();
  final TextEditingController _minimumPriceController = TextEditingController();
  final TextEditingController _boxPriceController = TextEditingController();

  String _selectedCountry = '';
  City? selectedCity;
  bool _hasAgent = false;
  bool _isPost = false;
  @override
  void initState() {
    super.initState();
    context.read<CityCubit>().fetchCities();
    context.read<CountryCubit>().fetchCountries();
    _restoreFormData();
  }

  @override
  void deactivate() {
    _saveFormData(); // Save data when leaving the screen
    super.deactivate();
  }

  void _saveFormData() {
    final formData = {
      'cityName': _cityNameController.text,
      'selectedCountry': _selectedCountry,
      'doorToDoorPrice': _doorToDoorPriceController.text,
      'priceKg': _priceKgController.text,
      'minimumPrice': _minimumPriceController.text,
      'boxPrice': _boxPriceController.text,
      'hasAgent': _hasAgent,
      'isPost': _isPost,
    };
    context.read<CityFormCubit>().saveFormData(formData);
  }

  void _restoreFormData() {
    final formData = context.read<CityFormCubit>().state;
    if (formData.isNotEmpty) {
      _cityNameController.text = formData['cityName'] ?? '';
      _selectedCountry = formData['selectedCountry'] ?? '';
      _doorToDoorPriceController.text = formData['doorToDoorPrice'] ?? '';
      _priceKgController.text = formData['priceKg'] ?? '';
      _minimumPriceController.text = formData['minimumPrice'] ?? '';
      _boxPriceController.text = formData['boxPrice'] ?? '';
      _hasAgent = formData['hasAgent'] ?? false;
      _isPost = formData['isPost'] ?? false;
      setState(() {});
    }
  }

  @override
  void dispose() {
    _cityNameController.dispose();
    _doorToDoorPriceController.dispose();
    _priceKgController.dispose();
    _minimumPriceController.dispose();
    _boxPriceController.dispose();
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  final RouteObserver<ModalRoute> routeObserver = RouteObserver<ModalRoute>();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  void _clearForm() {
    context.read<CityFormCubit>().clearFormData();
    _cityNameController.clear();
    _doorToDoorPriceController.clear();
    _priceKgController.clear();
    _minimumPriceController.clear();
    _boxPriceController.clear();
    setState(() {
      selectedCity = null;
      _selectedCountry = '';
      _hasAgent = false;
      _isPost = false;
    });
  }

  void _populateForm(City city) {
    setState(() {
      selectedCity = city;
      _cityNameController.text = city.cityName;
      _doorToDoorPriceController.text = city.doorToDoorPrice.toString();
      _priceKgController.text = city.priceKg.toString();
      _minimumPriceController.text = city.minimumPrice.toString();
      _boxPriceController.text = city.boxPrice.toString();
      _selectedCountry = city.country;
      _hasAgent = city.hasAgent;
      _isPost = city.isPost;
    });
  }

  City _createCityFromForm() {
    return City(
      id: selectedCity?.id,
      cityName: _cityNameController.text,
      country: _selectedCountry,
      hasAgent: _hasAgent,
      isPost: _isPost,
      doorToDoorPrice: double.parse(_doorToDoorPriceController.text),
      priceKg: double.parse(_priceKgController.text),
      minimumPrice: double.parse(_minimumPriceController.text),
      boxPrice: double.parse(_boxPriceController.text),
    );
  }

  void _onIsPostChanged(bool? value) {
    setState(() {
      _isPost = value ?? false;
    });
  }

  void _onAdd() {
    if (_formKey.currentState?.validate() ?? false) {
      final city = _createCityFromForm();
      context.read<CityCubit>().addCity(city);
      _clearForm();
    }
  }

  void _onUpdate() {
    if (_formKey.currentState?.validate() ?? false) {
      final city = _createCityFromForm();
      context.read<CityCubit>().updateCity(city);
      _clearForm();
    }
  }

  void _onDelete() {
    if (selectedCity?.id != null) {
      context.read<CityCubit>().deleteCity(selectedCity!.id!);
      _clearForm();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(16.0.r),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: PageUtils.buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    PageUtils.buildSearchBar(
                      onChanged: (value) =>
                          setState(() => _searchQuery = value),
                    ),
                    SizedBox(height: 16.h),
                    _buildGridContent(),
                  ],
                ),
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              flex: 2,
              child: PageUtils.buildCard(
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildFormFields(),
                        PageUtils.buildAgentSelection(
                          value: _hasAgent,
                          onChanged: (value) {
                            setState(() {
                              _hasAgent = value ?? false;
                            });
                          },
                        ),
                        PageUtils.buildPostSelection(
                            onChanged: _onIsPostChanged, value: _isPost),
                        SizedBox(height: 16.h),
                        PageUtils.buildActionButtons(
                          onAddPressed: _onAdd,
                          onUpdatePressed:
                              selectedCity != null ? _onUpdate : null,
                          onDeletePressed:
                              selectedCity != null ? _onDelete : null,
                          onCancelPressed: _clearForm,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridContent() {
    return Expanded(
      child: BlocBuilder<CityCubit, CityState>(
        builder: (context, state) {
          if (state is CityLoadingState) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is CityLoadedState) {
            return CitiesList(
              cities: state.cities,
              onCitySelected: _populateForm,
              searchQuery: _searchQuery,
            );
          } else if (state is CityErrorState) {
            return Center(child: Text(state.errorMessage));
          }
          return const Center(child: Text('No data available'));
        },
      ),
    );
  }

  Widget _buildFormFields() {
    return Column(
      children: [
        PageUtils.buildTextField(
          controller: _cityNameController,
          labelText: 'City Name',
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'City Name is required';
            }
            return null;
          },
        ),
        SizedBox(height: 16.h),
        _buildCountryDropdown(),
        SizedBox(height: 16.h),
        PageUtils.buildTextField(
          controller: _doorToDoorPriceController,
          labelText: 'Door To Door Price',
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Door To Door Price is required';
            }
            if (double.tryParse(value) == null) {
              return 'Please enter a valid number';
            }
            return null;
          },
        ),
        SizedBox(height: 16.h),
        PageUtils.buildTextField(
          controller: _priceKgController,
          labelText: 'Price KG',
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Price KG is required';
            }
            if (double.tryParse(value) == null) {
              return 'Please enter a valid number';
            }
            return null;
          },
        ),
        SizedBox(height: 16.h),
        PageUtils.buildTextField(
          controller: _minimumPriceController,
          labelText: 'Minimum Price',
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Minimum Price is required';
            }
            if (double.tryParse(value) == null) {
              return 'Please enter a valid number';
            }
            return null;
          },
        ),
        SizedBox(height: 16.h),
        PageUtils.buildTextField(
          controller: _boxPriceController,
          labelText: 'Box Price',
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Box Price is required';
            }
            if (double.tryParse(value) == null) {
              return 'Please enter a valid number';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildCountryDropdown() {
    return BlocBuilder<CountryCubit, CountryState>(builder: (context, state) {
      final countries = state is CountryLoaded
          ? state.countries.map((country) => country.countryName).toList()
          : <String>[];

      return PageUtils.buildDropdownFormField(
        labelText: 'Country *',
        items: countries,
        value: _selectedCountry.isEmpty ? null : _selectedCountry,
        onChanged: (String? newValue) {
          setState(() {
            _selectedCountry = newValue ?? '';
          });
        },
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Country is required';
          }
          return null;
        },
      );
    });
  }
}

class CityFormCubit extends Cubit<Map<String, dynamic>> {
  CityFormCubit() : super({});

  void saveFormData(Map<String, dynamic> formData) => emit(formData);
  void clearFormData() => emit({});
}
