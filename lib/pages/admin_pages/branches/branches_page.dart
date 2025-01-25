import 'package:app/cubits/cities_cubit/cities_cubit.dart';
import 'package:app/cubits/cities_cubit/cities_state.dart';
import 'package:app/models/branches_model.dart';
import 'package:app/pages/admin_pages/branches/code_generator.dart';
import 'package:app/widgets/page_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../cubits/brach_cubit/branch_cubit.dart';
import '../../../cubits/brach_cubit/branch_states.dart';
import 'branch_list.dart';

class BranchesPage extends StatefulWidget {
  const BranchesPage({
    super.key,
  });

  static final String id = 'branches_page';
  @override
  State<BranchesPage> createState() => _BranchesPageState();
}

class _BranchesPageState extends State<BranchesPage> {
  String _searchQuery = '';
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _branchNameController = TextEditingController();
  final TextEditingController _contactPersonController =
      TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _phone1Controller = TextEditingController();
  final TextEditingController _phone2Controller = TextEditingController();
  final TextEditingController _charPrefixController = TextEditingController();
  final TextEditingController _yearPrefixController = TextEditingController();
  final TextEditingController _digitsController = TextEditingController();
  final TextEditingController _codeStyleController = TextEditingController();

  String _selectedCity = '';
  Branch? selectedBranch;
  String _selectedLanguage = 'Arabic'; // Default language

  String? _charPrefixError;
  String? _yearPrefixError;
  String? _digitsError;

  @override
  void initState() {
    super.initState();
    _setupControllers();
    _restoreFormData();
  }

  @override
  void deactivate() {
    _saveFormData();
    super.deactivate();
  }

  void _saveFormData() {
    final formData = {
      'branchName': _branchNameController.text,
      'contactPerson': _contactPersonController.text,
      'address': _addressController.text,
      'company': _companyController.text,
      'phone1': _phone1Controller.text,
      'phone2': _phone2Controller.text,
      'charPrefix': _charPrefixController.text,
      'yearPrefix': _yearPrefixController.text,
      'digits': _digitsController.text,
      'selectedCity': _selectedCity,
      'selectedLanguage': _selectedLanguage,
    };
    context.read<BranchFormCubit>().saveFormData(formData);
  }

  void _restoreFormData() {
    final formData = context.read<BranchFormCubit>().state;
    if (formData.isNotEmpty) {
      _branchNameController.text = formData['branchName'] ?? '';
      _contactPersonController.text = formData['contactPerson'] ?? '';
      _addressController.text = formData['address'] ?? '';
      _companyController.text = formData['company'] ?? '';
      _phone1Controller.text = formData['phone1'] ?? '';
      _phone2Controller.text = formData['phone2'] ?? '';
      _charPrefixController.text = formData['charPrefix'] ?? '';
      _yearPrefixController.text = formData['yearPrefix'] ?? '';
      _digitsController.text = formData['digits'] ?? '';
      _selectedCity = formData['selectedCity'] ?? '';
      _selectedLanguage = formData['selectedLanguage'] ?? 'Arabic';
      setState(() {});
    }
  }

 
  void _setupControllers() {
    context.read<BranchCubit>().fetchBranches();
    context.read<CityCubit>().fetchCities();
    _charPrefixController.addListener(_onInputChanged);
    _yearPrefixController.addListener(_onInputChanged);
    _digitsController.addListener(_onInputChanged);
    _yearPrefixController.text = DateTime.now().year.toString();
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  void _disposeControllers() {
    final controllers = [
      _branchNameController,
      _contactPersonController,
      _addressController,
      _companyController,
      _phone1Controller,
      _phone2Controller,
      _charPrefixController,
      _yearPrefixController,
      _digitsController,
      _codeStyleController
    ];

    for (var controller in controllers) {
      controller.dispose();
    }
  }

  void _onInputChanged() {
    if (!mounted) return;
    if (_charPrefixController.text.isNotEmpty &&
        _yearPrefixController.text.isNotEmpty &&
        _digitsController.text.isNotEmpty) {
      validateAndUpdateCode();
    }
  }

  void validateAndUpdateCode() {
    final errors = CodeGenerator.validateFields(
      characterPrefix: _charPrefixController.text,
      yearPrefix: _yearPrefixController.text,
      numberOfDigits: _digitsController.text,
    );

    setState(() {
      _charPrefixError = errors['characterPrefix'];
      _yearPrefixError = errors['yearPrefix'];
      _digitsError = errors['numberOfDigits'];
    });

    if (errors.isEmpty) {
      updateCodeStyle();
    }
  }

  void updateCodeStyle() {
    final code = CodeGenerator.generateCode(
      characterPrefix: _charPrefixController.text,
      yearPrefix: _yearPrefixController.text,
      numberOfDigits: _digitsController.text,
      currentSequence: 1,
    );

    _codeStyleController.text = code;
  }

  void _clearForm() {
    context.read<BranchFormCubit>().clearFormData();
    _branchNameController.clear();
    _contactPersonController.clear();
    _addressController.clear();
    _companyController.clear();
    _phone1Controller.clear();
    _phone2Controller.clear();
    _charPrefixController.clear();
    _yearPrefixController.clear();
    _digitsController.clear();
    _codeStyleController.clear();
    setState(() {
      selectedBranch = null;
      _selectedLanguage = 'Arabic'; // Reset to default language
      _selectedCity = '';
    });
  }

  void _populateForm(Branch branch) {
    setState(() {
      selectedBranch = branch;
      _branchNameController.text = branch.branchName;
      _contactPersonController.text = branch.contactPersonName;
      _addressController.text = branch.address;
      _companyController.text = branch.branchCompany;
      _phone1Controller.text = branch.phoneNo1;
      _phone2Controller.text = branch.phoneNo2;
      _charPrefixController.text = branch.charactersPrefix;
      _yearPrefixController.text = branch.yearPrefix;
      _digitsController.text = branch.numberOfDigits.toString();
      _codeStyleController.text = branch.codeStyle;
      _selectedCity = branch.city;
      _selectedLanguage = branch.invoiceLanguage; // Set selected language
    });
  }

  Branch _createBranchFromForm() {
    return Branch(
      id: selectedBranch?.id,
      branchName: _branchNameController.text,
      contactPersonName: _contactPersonController.text,
      address: _addressController.text,
      branchCompany: _companyController.text,
      phoneNo1: _phone1Controller.text,
      phoneNo2: _phone2Controller.text,
      city: _selectedCity,
      charactersPrefix: _charPrefixController.text,
      yearPrefix: _yearPrefixController.text,
      numberOfDigits: int.tryParse(_digitsController.text) ?? 0,
      codeStyle: _codeStyleController.text,
      invoiceLanguage: _selectedLanguage, // Use selected language
    );
  }

  void _onAdd() {
    if (_formKey.currentState?.validate() ?? false) {
      final branch = _createBranchFromForm();
      context.read<BranchCubit>().addBranch(branch);
      _clearForm();
    }
  }

  void _onUpdate() {
    if (_formKey.currentState?.validate() ?? false) {
      final branch = _createBranchFromForm();
      context.read<BranchCubit>().updateBranch(branch);
      _clearForm();
    }
  }

  void _onDelete() {
    if (selectedBranch?.id != null) {
      context.read<BranchCubit>().deleteBranch(selectedBranch!.id!);
      _clearForm();
    }
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
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
            _buildGridContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildGridContent() {
    return Expanded(
      child: BlocBuilder<BranchCubit, BranchState>(
        builder: (context, state) {
          if (state is BranchLoadingState) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is BranchLoadedState) {
            return BranchDataTableEnhanced(
              branches: state.branches,
              onBranchSelected: _populateForm,
              searchQuery: _searchQuery,
            );
          } else if (state is BranchErrorState) {
            return Center(child: Text(state.errorMessage));
          }
          return Center(
              child: Text(
            'No data available',
            style: TextStyle(fontSize: 32.sp),
          ));
        },
      ),
    );
  }

  Widget _buildFormSection() {
    return Flexible(
      flex: 2,
      child: Card(
        margin: EdgeInsets.all(8.0.r),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.0.r),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildFormFields(),
                _buildLanguageSelection(),
                SizedBox(height: 16.h),
                PageUtils.buildActionButtons(
                  onAddPressed: _onAdd,
                  onUpdatePressed: selectedBranch != null ? _onUpdate : null,
                  onDeletePressed: selectedBranch != null ? _onDelete : null,
                  onCancelPressed: _clearForm,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormFields() {
    return Column(
      children: [
        PageUtils.buildTextField(
          controller: _branchNameController,
          labelText: 'Branch Name',
        ),
        SizedBox(height: 16.h),
        PageUtils.buildTextField(
          controller: _contactPersonController,
          labelText: 'Contact Person Name',
        ),
        SizedBox(height: 16.h),
        PageUtils.buildTextField(
          controller: _addressController,
          labelText: 'Address',
        ),
        SizedBox(height: 16.h),
        Row(
          children: [
            Expanded(
              child: PageUtils.buildTextField(
                controller: _companyController,
                labelText: 'Branch Company',
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: _buildCityDropdown(),
            ),
          ],
        ),
        SizedBox(height: 16.h),
        Row(
          children: [
            Expanded(
              child: PageUtils.buildTextField(
                controller: _phone1Controller,
                labelText: 'Phone No 1',
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: PageUtils.buildTextField(
                controller: _phone2Controller,
                labelText: 'Phone No 2',
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),
        Row(
          children: [
            Expanded(
              child: PageUtils.buildTextField(
                controller: _charPrefixController,
                labelText: 'Characters Prefix',
                validator: (_) => _charPrefixError,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: PageUtils.buildTextField(
                controller: _yearPrefixController,
                labelText: 'Year Prefix',
                validator: (_) => _yearPrefixError,
                keyboardType: TextInputType.number,
                enabled: true,
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),
        Row(
          children: [
            Expanded(
              child: PageUtils.buildTextField(
                controller: _digitsController,
                labelText: 'Number Of Digits',
                validator: (_) => _digitsError,
                keyboardType: TextInputType.number,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: PageUtils.buildTextField(
                controller: _codeStyleController,
                labelText: 'Code Style',
                enabled: false,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLanguageSelection() {
    return Column(
      children: [
        const Divider(),
        SizedBox(height: 16.h),
        Padding(
          padding: EdgeInsets.only(left: 64.w),
          child: Text(
            'Invoice Language',
            style: TextStyle(fontSize: 32.sp, fontWeight: FontWeight.bold),
          ),
        ),
        Column(
          children: [
            RadioListTile<String>(
              title: Text(
                'Arabic Language',
                style: TextStyle(fontSize: 24.sp),
              ),
              value: 'Arabic',
              groupValue: _selectedLanguage,
              onChanged: (value) {
                setState(() {
                  _selectedLanguage = value!;
                });
              },
            ),
            RadioListTile<String>(
              title: Text(
                'Kurdish Language',
                style: TextStyle(fontSize: 24.sp),
              ),
              value: 'Kurdish',
              groupValue: _selectedLanguage,
              onChanged: (value) {
                setState(() {
                  _selectedLanguage = value!;
                });
              },
            ),
            RadioListTile<String>(
              title: Text(
                'English Language',
                style: TextStyle(fontSize: 24.sp),
              ),
              value: 'English',
              groupValue: _selectedLanguage,
              onChanged: (value) {
                setState(() {
                  _selectedLanguage = value!;
                });
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCityDropdown() {
    return BlocBuilder<CityCubit, CityState>(
      builder: (context, state) {
        List<String> cityNames = [];
        if (state is CityLoadedState) {
          cityNames = state.cities.map((city) => city.cityName).toList();
        }

        return DropdownButtonFormField<String>(
          value: _selectedCity.isEmpty ? null : _selectedCity,
          decoration: InputDecoration(
            labelText: 'City *',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
          items: cityNames.map((String cityName) {
            return DropdownMenuItem<String>(
              value: cityName,
              child: Text(cityName),
            );
          }).toList(),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'City is required';
            }
            return null;
          },
          onChanged: (String? newValue) {
            setState(() {
              _selectedCity = newValue ?? '';
            });
          },
        );
      },
    );
  }
}
class BranchFormCubit extends Cubit<Map<String, dynamic>> {
  BranchFormCubit() : super({});

  void saveFormData(Map<String, dynamic> formData) => emit(formData);
  void clearFormData() => emit({});
}
