
import 'package:app/cubits/cities_cubit/cities_cubit.dart';
import 'package:app/cubits/cities_cubit/cities_state.dart';
import 'package:app/cubits/countries_cubit/countries_cubit.dart';
import 'package:app/cubits/countries_cubit/countries_state.dart';
import 'package:app/models/city_model.dart';
import 'package:app/widgets/asset_manager.dart';
import 'package:app/widgets/flag_upload.dart';
import 'package:app/widgets/page_utils.dart';
import 'package:file_picker/file_picker.dart';
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
  String _selectedCircularImage = '';
  String _selectedSquareImage = '';
  bool _isLoadingCircularFlag = false;
  bool _isLoadingSquareFlag = false;
  String _searchQuery = '';
  final _formKey = GlobalKey<FormState>();
  String _selectedCircularFlag = '';
  String _selectedSquareFlag = '';
  final TextEditingController _cityNameController = TextEditingController();
  final TextEditingController _doorToDoorPriceController =
      TextEditingController();
  final TextEditingController _priceKgController = TextEditingController();
  final TextEditingController _minimumPriceController = TextEditingController();
  final TextEditingController _boxPriceController = TextEditingController();
  final TextEditingController _maximumWeightController =
      TextEditingController();

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
      'maximumWeight': _maximumWeightController.text,
      'minimumPrice': _minimumPriceController.text,
      'boxPrice': _boxPriceController.text,
      'hasAgent': _hasAgent,
      'isPost': _isPost,
      'circularImage': _selectedCircularImage,
      'squareImage': _selectedSquareImage,
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
      _maximumWeightController.text = formData['maximumWeight'] ?? '';
      _boxPriceController.text = formData['boxPrice'] ?? '';
      _hasAgent = formData['hasAgent'] ?? false;
      _isPost = formData['isPost'] ?? false;
      _selectedCircularImage = formData['circularImage'] ?? '';
      _selectedSquareImage = formData['squareImage'] ?? '';
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
    _maximumWeightController.clear();
    setState(() {
      selectedCity = null;
      _selectedCountry = '';
      _hasAgent = false;
      _selectedCircularImage = '';
      _selectedSquareImage = '';
      _isPost = false;
    });
  }

  Future<void> _loadExistingFlags() async {
    if (_cityNameController.text.isNotEmpty) {
      final circularFlag = await AssetManager.getFlagByCountry(
        _cityNameController.text,
        isCircular: true,
      );
      final squareFlag = await AssetManager.getFlagByCountry(
        _cityNameController.text,
        isCircular: false,
      );

      setState(() {
        _selectedCircularFlag = circularFlag ?? '';
        _selectedSquareFlag = squareFlag ?? '';
      });
    }
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
      _selectedCircularFlag = city.circularFlag;
      _selectedSquareFlag = city.squareFlag;

      _maximumWeightController.text = city.maxWeightKG.toString();
    });
    _loadExistingFlags();
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
      circularFlag: _selectedCircularFlag,
      squareFlag: _selectedSquareFlag,
      maxWeightKG: double.parse(_maximumWeightController.text),
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
        SizedBox(height: 16.h),
        PageUtils.buildTextField(
          controller: _maximumWeightController,
          labelText: 'Maximum Weight (KG)',
          keyboardType: TextInputType.number,
        ),
        SizedBox(height: 16.h),
        _buildImageSelectors(),
      ],
    );
  }

// In your CitiesPage
  Widget _buildImageSelectors() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Country Flags',
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF6366F1), // Purple color from screenshot
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: FlagUploadWidget(
                  flagPath: _selectedCircularFlag,
                  isCircular: true,
                  isLoading: _isLoadingCircularFlag,
                  onUpload: _pickCircularImage,
                  onDelete: () => _handleImageDeletion(true),
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: FlagUploadWidget(
                  flagPath: _selectedSquareFlag,
                  isCircular: false,
                  isLoading: _isLoadingSquareFlag,
                  onUpload: _pickSquareImage,
                  onDelete: () => _handleImageDeletion(false),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }



  Future<void> _pickCircularImage() async {
    try {
      setState(() => _isLoadingCircularFlag = true);

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );

      if (result != null && result.files.single.path != null) {
        final sourcePath = result.files.single.path!;
        final cityName = _cityNameController.text;

        if (cityName.isEmpty) {
          _showError('Please enter a city name first');
          return;
        }

        // Delete existing flag if it exists
        if (_selectedCircularFlag.isNotEmpty) {
          await AssetManager.deleteImageFromAssets(_selectedCircularFlag);
        }

        final savedPath = await AssetManager.saveImageToAssets(
          sourcePath,
          'circular_${cityName.replaceAll(' ', '_')}',
        );

        setState(() => _selectedCircularFlag = savedPath);
        _showSuccess('Circular flag saved successfully');
      }
    } catch (e) {
      _showError('Error saving circular flag: $e');
    } finally {
      setState(() => _isLoadingCircularFlag = false);
    }
  }

  Future<void> _pickSquareImage() async {
    try {
      setState(() => _isLoadingSquareFlag = true);

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );

      if (result != null && result.files.single.path != null) {
        final sourcePath = result.files.single.path!;
        final cityName = _cityNameController.text;

        if (cityName.isEmpty) {
          _showError('Please enter a city name first');
          return;
        }

        // Delete existing flag if it exists
        if (_selectedSquareFlag.isNotEmpty) {
          await AssetManager.deleteImageFromAssets(_selectedSquareFlag);
        }

        final savedPath = await AssetManager.saveImageToAssets(
          sourcePath,
          'square_${cityName.replaceAll(' ', '_')}',
        );

        setState(() => _selectedSquareFlag = savedPath);
        _showSuccess('Square flag saved successfully');
      }
    } catch (e) {
      _showError('Error saving square flag: $e');
    } finally {
      setState(() => _isLoadingSquareFlag = false);
    }
  }

// Update the image deletion handling
  Future<void> _handleImageDeletion(bool isCircular) async {
    try {
      final imagePath =
          isCircular ? _selectedCircularFlag : _selectedSquareFlag;
      if (imagePath.isNotEmpty) {
        await AssetManager.deleteImageFromAssets(imagePath);
        setState(() {
          if (isCircular) {
            _selectedCircularFlag = '';
          } else {
            _selectedSquareFlag = '';
          }
        });
        _showSuccess('Flag deleted successfully');
      }
    } catch (e) {
      _showError('Error deleting flag: $e');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
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
