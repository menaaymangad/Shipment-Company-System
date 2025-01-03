import 'package:app/cubits/cities_cubit/cities_cubit.dart';
import 'package:app/cubits/cities_cubit/cities_state.dart';
import 'package:app/cubits/countries_cubit/countries_cubit.dart';
import 'package:app/cubits/countries_cubit/countries_state.dart';
import 'package:app/widgets/page_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../cubits/agent_cubit/agent_cubit.dart';
import '../../../cubits/agent_cubit/agent_state.dart';
import '../../../models/agent_model.dart';
import 'agent_list.dart';

class AgentPage extends StatefulWidget {
  const AgentPage({super.key});

  @override
  State<AgentPage> createState() => _AgentPageState();
}

class _AgentPageState extends State<AgentPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for form fields
  final _nameController = TextEditingController();
  final _contactPersonController = TextEditingController();
  final _companyController = TextEditingController();
  final _addressController = TextEditingController();
  final _priceKgController = TextEditingController();
  final _doorToDoorPriceController = TextEditingController();
  final _phoneNo1Controller = TextEditingController();
  final _phoneNo2Controller = TextEditingController();
  final _minimumPriceController = TextEditingController();

  // State variables
  String? _selectedCountry;
  String? _selectedCity;
  Agent? _selectedAgent;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _initializeCubits();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactPersonController.dispose();
    _companyController.dispose();
    _addressController.dispose();
    _priceKgController.dispose();
    _doorToDoorPriceController.dispose();
    _phoneNo1Controller.dispose();
    _phoneNo2Controller.dispose();
    _minimumPriceController.dispose();
    super.dispose();
  }

  void _initializeCubits() {
    context.read<AgentCubit>().loadAgents();
    context.read<CountryCubit>().fetchCountries();
    context.read<CityCubit>().fetchCities();
  }

  void _populateForm(Agent agent) {
    setState(() {
      _nameController.text = agent.agentName;
      _contactPersonController.text = agent.contactPersonName;
      _companyController.text = agent.companyName;
      _addressController.text = agent.address;
      _priceKgController.text = agent.priceKG.toString();
      _doorToDoorPriceController.text = agent.doorToDoorPrice.toString();

      _phoneNo1Controller.text = agent.phoneNo1;
      _phoneNo2Controller.text = agent.phoneNo2;
      _minimumPriceController.text = agent.minimumPrice.toString();

      _selectedCountry = agent.countryName;
      _selectedCity = agent.cityName;
      _selectedAgent = agent;
    });
  }

  Agent _buildAgentFromForm() {
    return Agent(
      id: _selectedAgent?.id,
      agentName: _nameController.text,
      countryName: _selectedCountry ?? '',
      contactPersonName: _contactPersonController.text,
      companyName: _companyController.text,
      cityName: _selectedCity ?? '',
      address: _addressController.text,
      phoneNo1: _phoneNo1Controller.text,
      phoneNo2: _phoneNo2Controller.text,
      priceKG: double.tryParse(_priceKgController.text) ?? 0,
      minimumPrice: double.tryParse(_minimumPriceController.text) ?? 0,
      doorToDoorPrice: double.tryParse(_doorToDoorPriceController.text) ?? 0,
    );
  }

  void _clearForm() {
    _formKey.currentState?.reset();
    _nameController.clear();
    _contactPersonController.clear();
    _companyController.clear();
    _addressController.clear();
    _priceKgController.clear();
    _doorToDoorPriceController.clear();
    _phoneNo1Controller.clear();
    _phoneNo2Controller.clear();
    _minimumPriceController.clear();
    setState(() {
      _selectedCountry = null;
      _selectedCity = null;
      _selectedAgent = null;
    });
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 150.h,
              child: PageUtils.buildSearchBar(
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
            ),
            _buildDataGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildDataGrid() {
    return Flexible(
      child: BlocBuilder<AgentCubit, AgentState>(
        builder: (context, state) {
          if (state is AgentLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is AgentLoaded) {
            return AgentDataGrid(
              agents: state.agents,
              onAgentSelected: _populateForm,
              searchQuery: _searchQuery,
            );
          } else if (state is AgentError) {
            return Center(child: Text(state.message));
          }
          return const SizedBox();
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
                _buildFormRows(),
                SizedBox(height: 16.h),
                PageUtils.buildActionButtons(
                
                  onAddPressed: _handleAdd,
                  onUpdatePressed:
                      _selectedAgent != null ? _handleUpdate : null,
                  onDeletePressed:
                      _selectedAgent != null ? _handleDelete : null,
                  onCancelPressed: _clearForm,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  Widget _buildFormRows() {
    return Column(
      children: [
        _buildFormRow(
          PageUtils.buildTextField(
            controller: _nameController,
            labelText: 'Agent Name',
          ),
          _buildDropdownField('Country'),
        ),
        _buildFormRow(
          PageUtils.buildTextField(
            controller: _contactPersonController,
            labelText: 'Contact Person Name',
          ),
          _buildDropdownField('City'),
        ),
        _buildFormRow(
          PageUtils.buildTextField(
            controller: _companyController,
            labelText: 'Company Name',
          ),
          PageUtils.buildTextField(
            controller: _phoneNo1Controller,
            labelText: 'Phone No 1',
          ),
        ),
        _buildFormRow(
          PageUtils.buildTextField(
            controller: _addressController,
            labelText: 'Address',
          ),
          PageUtils.buildTextField(
            controller: _phoneNo2Controller,
            labelText: 'Phone No 2',
          ),
        ),
        const Divider(),
        _buildFormRow(
          PageUtils.buildTextField(
            controller: _priceKgController,
            labelText: 'Price KG',
            keyboardType: TextInputType.number,
          ),
          PageUtils.buildTextField(
            controller: _minimumPriceController,
            labelText: 'Minimum Price',
            keyboardType: TextInputType.number,
          ),
        ),
        _buildFormRow(
          PageUtils.buildTextField(
            controller: _doorToDoorPriceController,
            labelText: 'Door To Door Price',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(),
        ),
      ],
    );
  }

  Widget _buildFormRow(Widget leftWidget, Widget rightWidget) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        children: [
          Expanded(child: leftWidget),
          SizedBox(width: 16.w),
          Expanded(child: rightWidget),
        ],
      ),
    );
  }

  Widget _buildDropdownField(String label) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: label == 'Country'
          ? BlocBuilder<CountryCubit, CountryState>(
              builder: (context, state) {
                List<String> countries = [];
                if (state is CountryLoaded) {
                  countries = state.countries
                      .map((country) => country.countryName)
                      .toList();
                }

                return DropdownButtonFormField<String>(
                  value: _selectedCountry,
                  decoration: InputDecoration(
                    labelText: label,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  items: countries.map((String countryName) {
                    return DropdownMenuItem<String>(
                      value: countryName,
                      child: Text(countryName),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCountry = value;
                      _selectedCity = null; // Reset city when country changes
                    });
                  },
                );
              },
            )
          : BlocBuilder<CityCubit, CityState>(
              builder: (context, state) {
                List<String> cities = [];
                if (state is CityLoadedState) {
                  cities = state.cities
                      .where((city) => city.country == _selectedCountry)
                      .map((city) => city.cityName)
                      .toList();
                }

                return DropdownButtonFormField<String>(
                  value: _selectedCity,
                  decoration: InputDecoration(
                    labelText: label,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  items: cities.map((String cityName) {
                    return DropdownMenuItem<String>(
                      value: cityName,
                      child: Text(cityName),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCity = value;
                    });
                  },
                );
              },
            ),
    );
  }

  void _handleAdd() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AgentCubit>().addAgent(_buildAgentFromForm());
      _clearForm();
    }
  }

  void _handleUpdate() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AgentCubit>().updateAgent(_buildAgentFromForm());
      _clearForm();
    }
  }

  void _handleDelete() {
    if (_selectedAgent?.id != null) {
      context.read<AgentCubit>().deleteAgent(_selectedAgent!.id!);
      _clearForm();
    }
  }
}
