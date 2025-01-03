import 'dart:io';

import 'package:app/cubits/agent_cubit/agent_cubit.dart';
import 'package:app/cubits/brach_cubit/branch_cubit.dart';
import 'package:app/cubits/brach_cubit/branch_states.dart';
import 'package:app/cubits/cities_cubit/cities_cubit.dart';
import 'package:app/cubits/cities_cubit/cities_state.dart';
import 'package:app/cubits/countries_cubit/countries_cubit.dart';
import 'package:app/cubits/countries_cubit/countries_state.dart';
import 'package:app/cubits/login_cubit/login_cubit_cubit.dart';
import 'package:app/cubits/send_cubit/send_cubit.dart';
import 'package:app/cubits/send_cubit/send_state.dart';
import 'package:app/helper/sql_helper.dart';
import 'package:app/models/branches_model.dart';
import 'package:app/models/good_description_model.dart';
import 'package:app/models/send_model.dart';
import 'package:app/pages/main_pages/invoice_pdf/invoice_pdf.dart';
import 'package:app/pages/main_pages/invoice_pdf/pdf_preview_dialog.dart';
import 'package:app/pages/main_pages/label_pdf/label_pdf.dart';
import 'package:app/pages/main_pages/send_page/good_description.dart';
import 'package:app/pages/main_pages/send_page/id_type_selector.dart';
import 'package:app/pages/main_pages/send_page/send_page_logic.dart';
import 'package:app/pages/main_pages/send_page/send_record_dialog.dart';
import 'package:app/widgets/consts.dart';
import 'package:app/widgets/custom_button.dart';
import 'package:app/widgets/send_utils.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

class SendScreen extends StatefulWidget {
  const SendScreen({super.key});
  static String id = 'SendPage';
  @override
  State<SendScreen> createState() => _SendScreenState();
}

class _SendScreenState extends State<SendScreen> {
  final _formKey = GlobalKey<FormState>();
  final double euroRate = 1.309;
  File? _selectedIdentificationPhoto;
  String? selectedValue; // Add this to your State class
  final Map<String, TextEditingController> _controllers = {
    ControllerKeys.dateController: TextEditingController(),
    ControllerKeys.truckNumberController: TextEditingController(),
    ControllerKeys.codeNumberController: TextEditingController(),
    ControllerKeys.boxNumberController: TextEditingController(),
    ControllerKeys.palletNumberController: TextEditingController(),
    ControllerKeys.weightController: TextEditingController(),
    ControllerKeys.lengthController: TextEditingController(),
    ControllerKeys.widthController: TextEditingController(),
    ControllerKeys.heightController: TextEditingController(),
    ControllerKeys.additionalKGController: TextEditingController(),
    ControllerKeys.totalWeightController: TextEditingController(),
    ControllerKeys.senderNameController: TextEditingController(),
    ControllerKeys.senderPhoneController: TextEditingController(),
    ControllerKeys.senderIdController: TextEditingController(),
    ControllerKeys.goodsDescriptionController: TextEditingController(),
    ControllerKeys.receiverNameController: TextEditingController(),
    ControllerKeys.receiverPhoneController: TextEditingController(),
    ControllerKeys.streetController: TextEditingController(),
    ControllerKeys.apartmentController: TextEditingController(),
    ControllerKeys.zipCodeController: TextEditingController(),
    ControllerKeys.insurancePercentController: TextEditingController(),
    ControllerKeys.goodsValueController: TextEditingController(),
    ControllerKeys.doorToDoorPriceController: TextEditingController(),
    ControllerKeys.pricePerKgController: TextEditingController(),
    ControllerKeys.minimumPriceController: TextEditingController(),
    ControllerKeys.insuranceAmountController: TextEditingController(),
    ControllerKeys.customsCostController: TextEditingController(),
    ControllerKeys.exportDocCostController: TextEditingController(),
    ControllerKeys.boxPackingCostController: TextEditingController(),
    ControllerKeys.doorToDoorCostController: TextEditingController(),
    ControllerKeys.postSubCostController: TextEditingController(),
    ControllerKeys.discountAmountController: TextEditingController(),
    ControllerKeys.totalPostCostController: TextEditingController(),
    ControllerKeys.totalPostCostPaidController: TextEditingController(),
    ControllerKeys.unpaidAmountController: TextEditingController(),
    ControllerKeys.totalCostEurController: TextEditingController(),
    ControllerKeys.unpaidEurCostController: TextEditingController(),
  };

  String _selectedAgent = '';
  String? _selectedBranch;
  TextEditingController branchController = TextEditingController();
  String _selectedCountry = '';
  String _selectedCity = '';

  bool areDimensionsEnabled = true;
  bool isInsuranceEnabled = true;
  bool isPostCostPaid = false;

  IdType? _selectedIdType;
  String? _lastTruckNumber;

  @override
  void initState() {
    super.initState();

    // Set the initial date
    _controllers[ControllerKeys.dateController]?.text =
        DateFormat('yyyy-MM-dd').format(DateTime.now());

    // Add listeners for automatic calculations
    for (var controller in _controllers.values) {
      controller.addListener(
          () => SendPageLogic.updateCalculations(controllers: _controllers));
    }

    // Fetch cities, countries, branches, and agents
    try {
      context.read<CityCubit>().fetchCities();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load cities: $e')),
      );
    }
    try {
      context.read<CountryCubit>().fetchCountries();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load countries: $e')),
      );
    }
    try {
      context.read<BranchCubit>().fetchBranches();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load branches: $e')),
      );
    }
    try {
      context.read<AgentCubit>().loadAgents();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load agents: $e')),
      );
    }

    // Retrieve the selected branch from AuthCubit
    final authCubit = context.read<AuthCubit>();
    _selectedBranch = authCubit.selectedBranch;

    // Fetch the branch details and set the Agent and Code Number fields
    if (_selectedBranch != null) {
      _fetchBranchAndSetAgentAndCode(_selectedBranch!);
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }

    super.dispose();
  }

void _onTruckNumberChanged(String truckNumber) async {
    if (truckNumber.isEmpty) return;

    if (truckNumber == _lastTruckNumber) {
      // Increment the code number for the same truck
      final nextCodeNumber =
          await _getNextCodeNumber(truckNumber, _selectedBranch!);
      setState(() {
        _controllers[ControllerKeys.codeNumberController]?.text =
            nextCodeNumber;
      });
    } else {
      // Reset the code number for a new truck
      setState(() {
        _controllers[ControllerKeys.codeNumberController]?.text =
            _initialCodeNumber;
      });
    }

    // Update the last truck number
    _lastTruckNumber = truckNumber;
  }
// Helper method to fetch branch details and set the Agent field
  String _initialCodeNumber = 'BA-2400001'; // Default initial code number

  void _fetchBranchAndSetAgentAndCode(String branchName) async {
    try {
      final branches = await context.read<BranchCubit>().getBranches();
      final selectedBranch = branches.firstWhere(
        (branch) => branch.branchName == branchName,
        orElse: () => Branch(
          branchName: '',
          contactPersonName: '',
          branchCompany: '',
          phoneNo1: '',
          phoneNo2: '',
          address: '',
          city: '',
          charactersPrefix: '',
          yearPrefix: '',
          numberOfDigits: 0,
          codeStyle: '',
          invoiceLanguage: '',
        ),
      );

      // Set the initial code number from the branch's codeStyle
      setState(() {
        _initialCodeNumber = selectedBranch.codeStyle;
        _controllers[ControllerKeys.codeNumberController]?.text =
            _initialCodeNumber;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch branch details: $e')),
        );
      }
    }
  }

  Future<String> _getNextCodeNumber(
      String truckNumber, String branchName) async {
    final records = await context.read<SendRecordCubit>().fetchAllSendRecords();
    final sameTruckRecords = records
        .where((record) =>
            record.truckNumber == truckNumber &&
            record.branchName == branchName)
        .toList();

    if (sameTruckRecords.isEmpty) {
      return _initialCodeNumber; // Use the initial code number from the branch
    }

    // Find the latest code number for this truck and branch
    final latestCode = sameTruckRecords
        .map((record) => record.codeNumber ?? 'BA-2400000')
        .reduce((a, b) => a.compareTo(b) > 0 ? a : b);

    final codeParts = latestCode.split('-');
    if (codeParts.length == 2) {
      final prefix = codeParts[0]; // "BA"
      final numericPart = codeParts[1]; // "2400001"

      final lastFiveDigits = numericPart.length >= 5
          ? numericPart.substring(numericPart.length - 5)
          : '00000';

      final incrementedNumber = (int.tryParse(lastFiveDigits) ?? 0) + 1;
      final newNumericPart = incrementedNumber.toString().padLeft(5, '0');

      return '$prefix-24$newNumericPart';
    }

    return 'BA-2400001'; // Fallback
  }

  Future<void> _saveRecordWithCode() async {
    try {
      final currentTruckNumber =
          _controllers[ControllerKeys.truckNumberController]?.text;

      if (currentTruckNumber == null || currentTruckNumber.isEmpty) {
        throw Exception('Truck number is required');
      }

      if (_selectedBranch == null || _selectedBranch!.isEmpty) {
        throw Exception('Branch is required');
      }

      // Generate the next code number for this truck and branch
      final nextCodeNumber =
          await _getNextCodeNumber(currentTruckNumber, _selectedBranch!);

      // Update the Code Number field in the UI
      setState(() {
        _controllers[ControllerKeys.codeNumberController]?.text =
            nextCodeNumber;
      });
      // Create a new SendRecord
      final record = SendRecord(
        // Shipment Info
        date: _controllers[ControllerKeys.dateController]?.text,
        truckNumber: currentTruckNumber,
        codeNumber: nextCodeNumber,
        boxNumber: int.tryParse(
            _controllers[ControllerKeys.boxNumberController]?.text ?? ''),
        palletNumber: int.tryParse(
            _controllers[ControllerKeys.palletNumberController]?.text ?? ''),
        realWeightKg: double.tryParse(
            _controllers[ControllerKeys.weightController]?.text ?? ''),
        length: double.tryParse(
            _controllers[ControllerKeys.lengthController]?.text ?? ''),
        width: double.tryParse(
            _controllers[ControllerKeys.widthController]?.text ?? ''),
        height: double.tryParse(
            _controllers[ControllerKeys.heightController]?.text ?? ''),
        isDimensionCalculated: areDimensionsEnabled,
        additionalKg: double.tryParse(
            _controllers[ControllerKeys.additionalKGController]?.text ?? ''),
        totalWeightKg: double.tryParse(
            _controllers[ControllerKeys.totalWeightController]?.text ?? ''),

        // Sender Info
        senderName: _controllers[ControllerKeys.senderNameController]?.text,
        senderPhone: _controllers[ControllerKeys.senderPhoneController]?.text,
        senderIdNumber: _controllers[ControllerKeys.senderIdController]?.text,
        goodsDescription:
            _controllers[ControllerKeys.goodsDescriptionController]?.text,

        // Agent Info
        agentName: _selectedAgent,
        branchName: _selectedBranch,

        // Receiver Info
        receiverName: _controllers[ControllerKeys.receiverNameController]?.text,
        receiverPhone:
            _controllers[ControllerKeys.receiverPhoneController]?.text,
        receiverCountry: _selectedCountry,
        receiverCity: _selectedCity,

        // All other fields as per your model...
        streetName: _controllers[ControllerKeys.streetController]?.text,
        apartmentNumber: _controllers[ControllerKeys.apartmentController]?.text,
        zipCode: _controllers[ControllerKeys.zipCodeController]?.text,
        insurancePercent: double.tryParse(
            _controllers[ControllerKeys.insurancePercentController]?.text ??
                ''),
        goodsValue: double.tryParse(
            _controllers[ControllerKeys.goodsValueController]?.text ?? ''),

        // Costs
        doorToDoorPrice: double.tryParse(
            _controllers[ControllerKeys.doorToDoorPriceController]?.text ?? ''),
        pricePerKg: double.tryParse(
            _controllers[ControllerKeys.pricePerKgController]?.text ?? ''),
        minimumPrice: double.tryParse(
            _controllers[ControllerKeys.minimumPriceController]?.text ?? ''),
        insuranceAmount: double.tryParse(
            _controllers[ControllerKeys.insuranceAmountController]?.text ?? ''),
        customsCost: double.tryParse(
            _controllers[ControllerKeys.customsCostController]?.text ?? ''),
        exportDocCost: double.tryParse(
            _controllers[ControllerKeys.exportDocCostController]?.text ?? ''),
        boxPackingCost: double.tryParse(
            _controllers[ControllerKeys.boxPackingCostController]?.text ?? ''),
        doorToDoorCost: double.tryParse(
            _controllers[ControllerKeys.doorToDoorCostController]?.text ?? ''),
        postSubCost: double.tryParse(
            _controllers[ControllerKeys.postSubCostController]?.text ?? ''),
        discountAmount: double.tryParse(
            _controllers[ControllerKeys.discountAmountController]?.text ?? ''),
        totalPostCost: double.tryParse(
            _controllers[ControllerKeys.totalPostCostController]?.text ?? ''),
        totalPostCostPaid: double.tryParse(
            _controllers[ControllerKeys.totalPostCostPaidController]?.text ??
                ''),
        unpaidAmount: double.tryParse(
            _controllers[ControllerKeys.unpaidAmountController]?.text ?? ''),
        totalCostEuroCurrency: double.tryParse(
            _controllers[ControllerKeys.totalCostEurController]?.text ?? ''),
        unpaidAmountEuro: double.tryParse(
            _controllers[ControllerKeys.unpaidEurCostController]?.text ?? ''),
      );

      // Save the record
      if (mounted) {
        await context.read<SendRecordCubit>().createSendRecord(record);
      }
      // Clear the form (except date, truck number, code number, agent, and branch)
      _clearForm();
      // Ensure the widget is still mounted before showing the SnackBar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Record saved successfully')),
        );
      }
    } catch (e) {
      // Ensure the widget is still mounted before showing the error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving record: ${e.toString()}')),
        );
      }
    }
  }

  void _clearForm() {
    setState(() {
      // Clear all fields except date, truck number, code number, agent, and branch
      _controllers[ControllerKeys.boxNumberController]?.clear();
      _controllers[ControllerKeys.palletNumberController]?.clear();
      _controllers[ControllerKeys.weightController]?.clear();
      _controllers[ControllerKeys.lengthController]?.clear();
      _controllers[ControllerKeys.widthController]?.clear();
      _controllers[ControllerKeys.heightController]?.clear();
      _controllers[ControllerKeys.additionalKGController]?.clear();
      _controllers[ControllerKeys.totalWeightController]?.clear();
      _controllers[ControllerKeys.senderNameController]?.clear();
      _controllers[ControllerKeys.senderPhoneController]?.clear();
      _controllers[ControllerKeys.senderIdController]?.clear();
      _controllers[ControllerKeys.goodsDescriptionController]?.clear();
      _controllers[ControllerKeys.receiverNameController]?.clear();
      _controllers[ControllerKeys.receiverPhoneController]?.clear();
      _controllers[ControllerKeys.streetController]?.clear();
      _controllers[ControllerKeys.apartmentController]?.clear();
      _controllers[ControllerKeys.zipCodeController]?.clear();
      _controllers[ControllerKeys.insurancePercentController]?.clear();
      _controllers[ControllerKeys.goodsValueController]?.clear();
      _controllers[ControllerKeys.doorToDoorPriceController]?.clear();
      _controllers[ControllerKeys.pricePerKgController]?.clear();
      _controllers[ControllerKeys.minimumPriceController]?.clear();
      _controllers[ControllerKeys.insuranceAmountController]?.clear();
      _controllers[ControllerKeys.customsCostController]?.clear();
      _controllers[ControllerKeys.exportDocCostController]?.clear();
      _controllers[ControllerKeys.boxPackingCostController]?.clear();
      _controllers[ControllerKeys.doorToDoorCostController]?.clear();
      _controllers[ControllerKeys.postSubCostController]?.clear();
      _controllers[ControllerKeys.discountAmountController]?.clear();
      _controllers[ControllerKeys.totalPostCostController]?.clear();
      _controllers[ControllerKeys.totalPostCostPaidController]?.clear();
      _controllers[ControllerKeys.unpaidAmountController]?.clear();
      _controllers[ControllerKeys.totalCostEurController]?.clear();
      _controllers[ControllerKeys.unpaidEurCostController]?.clear();

      // Reset other state variables
      _selectedCountry = '';
      _selectedCity = '';
      areDimensionsEnabled = true;
      isInsuranceEnabled = true;
      isPostCostPaid = false;
      _selectedIdType = null;
      _selectedIdentificationPhoto = null;
    });
  }

  int? currentRecordId;

  void _populateFormWithRecord(SendRecord record) {
    setState(() {
      currentRecordId = record.id;

      // Shipment Info
      _controllers[ControllerKeys.dateController]?.text = record.date ?? '';
      _controllers[ControllerKeys.truckNumberController]?.text =
          record.truckNumber ?? '';
      _controllers[ControllerKeys.codeNumberController]?.text =
          record.codeNumber ?? '';
      _controllers[ControllerKeys.boxNumberController]?.text =
          record.boxNumber?.toString() ?? '';
      _controllers[ControllerKeys.palletNumberController]?.text =
          record.palletNumber?.toString() ?? '';
      _controllers[ControllerKeys.weightController]?.text =
          record.realWeightKg?.toString() ?? '';
      _controllers[ControllerKeys.lengthController]?.text =
          record.length?.toString() ?? '';
      _controllers[ControllerKeys.widthController]?.text =
          record.width?.toString() ?? '';
      _controllers[ControllerKeys.heightController]?.text =
          record.height?.toString() ?? '';
      _controllers[ControllerKeys.additionalKGController]?.text =
          record.additionalKg?.toString() ?? '';
      _controllers[ControllerKeys.totalWeightController]?.text =
          record.totalWeightKg?.toString() ?? '';

      // Sender Info
      _controllers[ControllerKeys.senderNameController]?.text =
          record.senderName ?? '';
      _controllers[ControllerKeys.senderPhoneController]?.text =
          record.senderPhone ?? '';
      _controllers[ControllerKeys.senderIdController]?.text =
          record.senderIdNumber ?? '';
      _controllers[ControllerKeys.goodsDescriptionController]?.text =
          record.goodsDescription ?? '';

      // Agent Info
      _selectedAgent = record.agentName ?? '';
      _selectedBranch = record.branchName ?? '';

      // Receiver Info
      _controllers[ControllerKeys.receiverNameController]?.text =
          record.receiverName ?? '';
      _controllers[ControllerKeys.receiverPhoneController]?.text =
          record.receiverPhone ?? '';
      _selectedCountry = record.receiverCountry ?? '';
      _selectedCity = record.receiverCity ?? '';

      // Postal Info
      _controllers[ControllerKeys.streetController]?.text =
          record.streetName ?? '';
      _controllers[ControllerKeys.apartmentController]?.text =
          record.apartmentNumber ?? '';
      _controllers[ControllerKeys.zipCodeController]?.text =
          record.zipCode ?? '';

      // Insurance Info
      _controllers[ControllerKeys.insurancePercentController]?.text =
          record.insurancePercent?.toString() ?? '';
      _controllers[ControllerKeys.goodsValueController]?.text =
          record.goodsValue?.toString() ?? '';

      // Costs Info
      _controllers[ControllerKeys.doorToDoorPriceController]?.text =
          record.doorToDoorPrice?.toString() ?? '';
      _controllers[ControllerKeys.pricePerKgController]?.text =
          record.pricePerKg?.toString() ?? '';
      _controllers[ControllerKeys.minimumPriceController]?.text =
          record.minimumPrice?.toString() ?? '';
      _controllers[ControllerKeys.insuranceAmountController]?.text =
          record.insuranceAmount?.toString() ?? '';
      _controllers[ControllerKeys.customsCostController]?.text =
          record.customsCost?.toString() ?? '';
      _controllers[ControllerKeys.exportDocCostController]?.text =
          record.exportDocCost?.toString() ?? '';
      _controllers[ControllerKeys.boxPackingCostController]?.text =
          record.boxPackingCost?.toString() ?? '';
      _controllers[ControllerKeys.doorToDoorCostController]?.text =
          record.doorToDoorCost?.toString() ?? '';
      _controllers[ControllerKeys.postSubCostController]?.text =
          record.postSubCost?.toString() ?? '';
      _controllers[ControllerKeys.discountAmountController]?.text =
          record.discountAmount?.toString() ?? '';
      _controllers[ControllerKeys.totalPostCostController]?.text =
          record.totalPostCost?.toString() ?? '';
      _controllers[ControllerKeys.totalPostCostPaidController]?.text =
          record.totalPostCostPaid?.toString() ?? '';
      _controllers[ControllerKeys.unpaidAmountController]?.text =
          record.unpaidAmount?.toString() ?? '';
      _controllers[ControllerKeys.totalCostEurController]?.text =
          record.totalCostEuroCurrency?.toString() ?? '';
      _controllers[ControllerKeys.unpaidEurCostController]?.text =
          record.unpaidAmountEuro?.toString() ?? '';

      // Update checkboxes
      areDimensionsEnabled = record.isDimensionCalculated ?? true;
    });
  }

  // Custom card wrapper for consistent styling
  Widget _buildCard({required Widget child}) {
    return SizedBox(
      width: double.infinity,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SendRecordCubit, SendRecordState>(
      listener: (context, state) {
        if (state is SendRecordError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        } else if (state is SendRecordLoaded) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Record saved successfully')),
          );
        }
      },
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Container(
          color: Colors.grey,
          child: Form(
            key: _formKey,
            child: Padding(
              padding: EdgeInsets.all(10.r),
              child: Column(
                children: [
                  IntrinsicHeight(
                    child: Row(
                      children: [
                        Expanded(child: _buildCard(child: buildMainCard())),
                        Expanded(child: _buildCard(child: agentCard())),
                        Expanded(
                            child: _buildCard(child: doorToDoorPriceCard())),
                      ],
                    ),
                  ),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // First Column
                        Flexible(
                          child: Column(
                            children: [
                              Expanded(
                                  child: _buildCard(child: buildSenderCard())),
                              _buildCard(child: buildItemsCard()),
                            ],
                          ),
                        ),

                        // Second Column
                        Flexible(
                          child: Column(
                            children: [
                              _buildCard(child: receiverCard()),
                              _buildCard(child: ifPostCard()),
                              Flexible(
                                  child:
                                      _buildCard(child: insuranceInfoCard())),
                            ],
                          ),
                        ),

                        // Third Column
                        Flexible(
                          child: Column(
                            children: [
                              _buildCard(child: costsCard()),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Flexible(flex: 2, child: actionButton()),
                      Flexible(flex: 1, child: clearButton()),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildMainCard() {
    return SendUtils.buildCard(
      child: Column(
        children: [
          SendUtils.buildInputRow(
            icon: Icons.calendar_today_outlined,
            child: SendUtils.buildTextField(
              controller: _controllers[ControllerKeys.dateController] ??
                  TextEditingController(),
              hint: 'Date',
              enabled: false,
            ),
          ),
          SizedBox(height: 10.h),
          SendUtils.buildInputRow(
            icon: Icons.local_shipping_outlined,
            child: SendUtils.buildTextField(
              controller: _controllers[ControllerKeys.truckNumberController] ??
                  TextEditingController(),
              onChanged: (value) => _onTruckNumberChanged(value),
              hint: 'Truck Number',
            ),
          ),
          SizedBox(height: 10.h),
          SendUtils.buildInputRow(
            icon: Icons.code,
            child: SendUtils.buildTextField(
              controller: _controllers[ControllerKeys.codeNumberController] ??
                  TextEditingController(),
              hint: 'Code Number',
              enabled: false, // Make the field non-editable
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Code Number is required';
                }
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSenderCard() {
    return SendUtils.buildCard(
      title: 'Sender',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SendUtils.buildInputRow(
            icon: Icons.person_outline,
            child: SendUtils.buildTextField(
              controller: _controllers[ControllerKeys.senderNameController] ??
                  TextEditingController(),
              hint: 'Sender Name',
            ),
          ),
          SendUtils.buildInputRow(
            icon: Icons.phone_outlined,
            child: SendUtils.buildTextField(
              controller: _controllers[ControllerKeys.senderPhoneController] ??
                  TextEditingController(),
              hint: 'Sender Phone',
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Phone number is required';
                }
                if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                  return 'Phone number must contain only numbers';
                }
                if (value.length < 11) {
                  return 'Phone number must be at least 11 digits';
                }
                return null;
              },
            ),
          ),
          Row(
            children: [
              Expanded(
                child: SendUtils.buildIdInputRow(
                  onTypeSelected: (type) {
                    setState(() {
                      _selectedIdType = type;
                    });
                  },
                  currentType: _selectedIdType,
                  child: SendUtils.buildTextField(
                    controller:
                        _controllers[ControllerKeys.senderIdController]!,
                    keyboardType: TextInputType.number,
                    hint: 'Sender ID',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'ID number is required';
                      }
                      if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                        return 'ID number must contain only numbers';
                      }
                      return null;
                    },
                  ),
                ),
              ),
              StatefulBuilder(
                builder: (context, setState) {
                  return GestureDetector(
                    onTap: () async {
                      if (_selectedIdentificationPhoto == null) {
                        // Pick image
                        FilePickerResult? result =
                            await FilePicker.platform.pickFiles(
                          type: FileType.image,
                          allowMultiple: false,
                        );

                        if (result != null &&
                            result.files.single.path != null) {
                          setState(() {
                            _selectedIdentificationPhoto =
                                File(result.files.single.path!);
                          });
                        } else {
                          if (mounted) {
                            setState(() {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('No file selected')),
                              );
                            });
                          }
                        }
                      } else {
                        // Show options dialog
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return Dialog(
                              child: Container(
                                padding: const EdgeInsets.all(16.0),
                                constraints: const BoxConstraints(
                                  maxWidth: 500.0,
                                  maxHeight: 600.0,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      'ID Photo',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Flexible(
                                      child: Image.file(
                                        _selectedIdentificationPhoto!,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        ElevatedButton(
                                          onPressed: () {
                                            setState(() {
                                              _selectedIdentificationPhoto =
                                                  null;
                                            });
                                            Navigator.of(context).pop();
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 24,
                                              vertical: 12,
                                            ),
                                          ),
                                          child: const Text('Delete Photo'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                          style: ElevatedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 24,
                                              vertical: 12,
                                            ),
                                          ),
                                          child: const Text('Cancel'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      }
                    },
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Container(
                        width: 100.w,
                        height: 60.h,
                        decoration: BoxDecoration(
                          color: _selectedIdentificationPhoto == null
                              ? Colors.white
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: _selectedIdentificationPhoto == null
                            ? Icon(
                                Icons.camera_alt_outlined,
                                color: SendUtils.secondaryColor,
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  _selectedIdentificationPhoto!,
                                  fit: BoxFit.cover,
                                ),
                              ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          SendUtils.buildInputRow(
            icon: Icons.description_outlined,
            child: InkWell(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => GoodsDescriptionPopup(
                    controller: _controllers[
                        ControllerKeys.goodsDescriptionController]!,
                    onDescriptionsSelected:
                        (List<GoodsDescription> selectedDescriptions) {
                      // Handle the selected descriptions
                      String descriptions = selectedDescriptions
                          .map((desc) => '${desc.id} - ${desc.descriptionEn}')
                          .join('\n');
                      _controllers[ControllerKeys.goodsDescriptionController]!
                          .text = descriptions;
                      if (kDebugMode) {
                        print('Selected descriptions: $descriptions');
                      }
                    },
                    dbHelper:
                        DatabaseHelper(), // Your existing database helper instance
                  ),
                );
              },
              child: SendUtils.buildTextField(
                height: 150.h,
                controller:
                    _controllers[ControllerKeys.goodsDescriptionController] ??
                        TextEditingController(),
                hint: 'Goods Description',
                enabled: false,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildItemsCard() {
    return SendUtils.buildCard(
      title: 'Items',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: SendUtils.buildTextField(
                  controller:
                      _controllers[ControllerKeys.boxNumberController] ??
                          TextEditingController(),
                  hint: 'Box No.',
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: SendUtils.buildTextField(
                  controller:
                      _controllers[ControllerKeys.palletNumberController] ??
                          TextEditingController(),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Pallet number is required';
                    }
                    if (int.tryParse(value) == null || int.parse(value) <= 0) {
                      return 'Please enter a valid positive number';
                    }
                    return null;
                  },
                  hint: 'Pallet No.',
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          SendUtils.buildTextField(
            controller: _controllers[ControllerKeys.weightController] ??
                TextEditingController(),
            hint: 'Real Weight KG',
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Expanded(
                child: SendUtils.buildTextField(
                  controller: _controllers[ControllerKeys.lengthController] ??
                      TextEditingController(),
                  hint: 'L',
                  enabled: areDimensionsEnabled,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: SendUtils.buildTextField(
                  controller: _controllers[ControllerKeys.widthController] ??
                      TextEditingController(),
                  hint: 'W',
                  enabled: areDimensionsEnabled,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: SendUtils.buildTextField(
                  controller: _controllers[ControllerKeys.heightController] ??
                      TextEditingController(),
                  hint: 'H',
                  enabled: areDimensionsEnabled,
                ),
              ),
              SizedBox(width: 8.w),
              Checkbox(
                value: areDimensionsEnabled,
                onChanged: (value) {
                  setState(() {
                    areDimensionsEnabled = value ?? true;
                  });
                },
              ),
            ],
          ),
          SizedBox(height: 8.h),
          SendUtils.buildDropdownField(
            label: 'Select Amount',
            items: ['5000', '6000'], // Convert integers to strings for dropdown
            value:
                selectedValue, // This should be a String? variable in your state
            onChanged: (String? newValue) {
              setState(() {
                selectedValue = newValue;
              });
            },
          ),
          SizedBox(height: 8.h),
          SendUtils.buildTextField(
            controller: _controllers[ControllerKeys.additionalKGController] ??
                TextEditingController(),
            hint: 'Additional KG',
          ),
          SizedBox(height: 8.h),
          SendUtils.buildTextField(
            controller: _controllers[ControllerKeys.totalWeightController] ??
                TextEditingController(),
            hint: 'Total Weight KG',
          ),
        ],
      ),
    );
  }

  Widget insuranceInfoCard() {
    return SendUtils.buildCard(
      title: 'Insurance Percent % Of Value',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: SendUtils.buildTextField(
                  hint: '6%',
                  controller:
                      _controllers[ControllerKeys.insurancePercentController] ??
                          TextEditingController(),
                  enabled: true,
                ),
              ),
              Checkbox(value: true, onChanged: (value) {}),
            ],
          ),
          SizedBox(height: 8.h),
          SendUtils.buildTextField(
            hint: 'Goods Value',
            enabled: true,
            controller: _controllers[ControllerKeys.goodsValueController] ??
                TextEditingController(),
          ),
          SizedBox(height: 8.h),
          Container(
            height: 140.h,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[200],
                border: Border.all(color: Colors.black)),
          )
        ],
      ),
    );
  }

  Widget ifPostCard() {
    return SendUtils.buildCard(
      title: 'Send Via Post',
      child: Column(
        children: [
          SendUtils.buildInputRow(
            icon: Icons.home_outlined,
            child: SendUtils.buildTextField(
              hint: 'Street Name & No.',
              controller: _controllers[ControllerKeys.streetController] ??
                  TextEditingController(),
            ),
          ),
          SendUtils.buildInputRow(
            icon: Icons.markunread_mailbox,
            child: SendUtils.buildTextField(
              hint: 'ZIP Code',
              controller: _controllers[ControllerKeys.zipCodeController] ??
                  TextEditingController(),
            ),
          ),
        ],
      ),
    );
  }

  Widget receiverCard() {
    return SendUtils.buildCard(
      title: 'Receiver',
      child: Column(
        children: [
          SendUtils.buildInputRow(
            icon: Icons.person_outline,
            child: SendUtils.buildTextField(
              hint: 'Receiver Name',
              controller: _controllers[ControllerKeys.receiverNameController] ??
                  TextEditingController(),
            ),
          ),
          SendUtils.buildInputRow(
            icon: Icons.phone_outlined,
            child: SendUtils.buildTextField(
              hint: 'Receiver Phone',
              controller:
                  _controllers[ControllerKeys.receiverPhoneController] ??
                      TextEditingController(),
            ),
          ),
          SizedBox(
            height: 16.h,
          ),
          _buildCountryDropdown(),
          SizedBox(
            height: 16.h,
          ),
          _buildCityDropdown(),
        ],
      ),
    );
  }

  Widget agentCard() {
    return SendUtils.buildCard(
      child: Column(
        children: [
          _buildAgentDropdown(),
          SizedBox(
            height: 16.h,
          ),
          _buildBranchDropdown(),
          SizedBox(
            height: 16.h,
          ),
          _buildCodeListDropdown(
            hint: 'Code List Items/ press ctrl + F to search',
            context: context, // Add actual items as needed
          ),
        ],
      ),
    );
  }

  // Replace the current _buildCountryDropdown with this implementation
  Widget _buildCountryDropdown() {
    return BlocBuilder<CountryCubit, CountryState>(builder: (context, state) {
      final countries = state is CountryLoaded
          ? state.countries.map((country) => country.countryName).toList()
          : <String>[];

      return SendUtils.buildDropdownField(
        label: 'Country',
        items: countries,
        value: _selectedCountry,
        height: 65.h,
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

// Replace the current _buildCityDropdown with this implementation
  Widget _buildCityDropdown() {
    return BlocBuilder<CityCubit, CityState>(builder: (context, state) {
      List<String> cityNames = [];
      if (state is CityLoadedState) {
        cityNames = state.cities.map((city) => city.cityName).toList();
      }

      return SendUtils.buildDropdownField(
        label: 'City',
        items: cityNames,
        value: _selectedCity,
        height: 65.h,
        onChanged: (String? newValue) {
          setState(() {
            _selectedCity = newValue ?? '';
          });
        },
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'City is required';
          }
          return null;
        },
      );
    });
  }

  Widget _buildBranchDropdown() {
    return BlocBuilder<BranchCubit, BranchState>(
      builder: (context, state) {
        if (state is BranchLoadedState) {
          // Use the non-editable text field for the branch
          return SendUtils.buildTextField(
            hint: 'Branch',
            controller: TextEditingController(
                text: _selectedBranch ?? ''), // Set the branch value
            enabled: false, // Make the field non-editable
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Branch is required';
              }
              return null;
            },
          );
        } else if (state is BranchErrorState) {
          return Text(state.errorMessage,
              style: const TextStyle(color: Colors.red));
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget _buildAgentDropdown() {
    return SendUtils.buildTextField(
      hint: 'Agent',
      controller: TextEditingController(text: _selectedAgent),
      enabled: false, // Make the field non-editable
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Agent is required';
        }
        return null;
      },
    );
  }

  Widget _buildCodeListDropdown({
    required String hint,
    required BuildContext context,
  }) {
    void openDialog() {
      context.read<SendRecordCubit>().fetchAllSendRecords();
      showDialog(
        context: context,
        builder: (context) => RecordsTableDialog(
          onRecordSelected: (record) {
            _populateFormWithRecord(record);
          },
        ),
      );
    }

    return BlocBuilder<SendRecordCubit, SendRecordState>(
      builder: (context, state) {
        List<String> codeNumbers = [];
        List<SendRecord> records = [];
        if (state is SendRecordListLoaded) {
          // Extract code numbers and records
          records = state.sendRecords;
          codeNumbers = records
              .map((record) => record.codeNumber ?? '')
              .where((code) => code.isNotEmpty) // Filter out empty codes
              .toSet() // Ensure unique values
              .toList();
          if (kDebugMode) {
            print(codeNumbers);
          }
        }

        if (selectedValue != null && !codeNumbers.contains(selectedValue)) {
          selectedValue = null; // Reset the value if it's not in the list
        }

        return Shortcuts(
          shortcuts: {
            LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyF):
                const ActivateIntent(),
          },
          child: Actions(
            actions: {
              ActivateIntent: CallbackAction<ActivateIntent>(
                onInvoke: (ActivateIntent intent) {
                  openDialog();
                  return null;
                },
              ),
            },
            child: Focus(
              autofocus: true,
              child: SendUtils.buildDropdownField(
                label: hint,
                items: codeNumbers, // Pass the unique code numbers as items
                value: selectedValue, // Pass the selected value
                height: 65.h,
                onChanged: (String? value) {
                  setState(() {
                    selectedValue = value;
                    if (kDebugMode) {
                      print('Selected Value: $selectedValue');
                    } // Update the selected value
                    // Find the record with the selected code number
                    if (value != null) {
                      final selectedRecord = records.firstWhere(
                        (record) => record.codeNumber == value,
                        orElse: () => SendRecord(), // Fallback if not found
                      );
                      if (selectedRecord.codeNumber != null) {
                        _populateFormWithRecord(selectedRecord);
                      }
                    }
                  });
                },
                isRequired: false,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: openDialog,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget doorToDoorPriceCard() {
    return SendUtils.buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SendUtils.buildTextField(
            controller:
                _controllers[ControllerKeys.doorToDoorPriceController] ??
                    TextEditingController(),
            hint: 'Door To Door Price',
            enabled: false,
          ),
          SizedBox(height: 8.h),
          SendUtils.buildTextField(
            controller: _controllers[ControllerKeys.pricePerKgController] ??
                TextEditingController(),
            hint: 'Price For Each 1 KG',
          ),
          SizedBox(height: 8.h),
          SendUtils.buildTextField(
            controller: _controllers[ControllerKeys.minimumPriceController] ??
                TextEditingController(),
            hint: 'Minimum Price',
          ),
          SizedBox(height: 16.h),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              'Exchange Currency: 1 EUR = 1.309 IQD',
              style: TextStyle(
                color: Colors.blue,
                fontSize: 24.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget costsCard() {
    return SendUtils.buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SendUtils.buildTextField(
            controller:
                _controllers[ControllerKeys.insuranceAmountController] ??
                    TextEditingController(),
            hint: 'Insurance Amount',
          ),
          SizedBox(height: 16.h),
          SendUtils.buildTextField(
            controller: _controllers[ControllerKeys.customsCostController] ??
                TextEditingController(),
            hint: 'Customs Cost',
          ),
          SizedBox(height: 16.h),
          SendUtils.buildTextField(
            controller: _controllers[ControllerKeys.boxPackingCostController] ??
                TextEditingController(),
            hint: 'Box Packing Cost',
          ),
          SizedBox(height: 16.h),
          SendUtils.buildTextField(
            controller: _controllers[ControllerKeys.doorToDoorCostController] ??
                TextEditingController(),
            hint: 'Door To Door Cost',
          ),
          SizedBox(height: 16.h),
          SendUtils.buildTextField(
            controller: _controllers[ControllerKeys.postSubCostController] ??
                TextEditingController(),
            hint: 'Post Sub Cost',
          ),
          SizedBox(height: 16.h),
          SendUtils.buildTextField(
            controller: _controllers[ControllerKeys.discountAmountController] ??
                TextEditingController(),
            hint: 'Discount Amount',
          ),
          SizedBox(height: 16.h),
          SendUtils.buildTextField(
            controller: _controllers[ControllerKeys.totalPostCostController] ??
                TextEditingController(),
            hint: 'Total Post Cost',
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: SendUtils.buildTextField(
                  controller: _controllers[
                          ControllerKeys.totalPostCostPaidController] ??
                      TextEditingController(),
                  hint: 'Total Post Cost Paid',
                ),
              ),
              Checkbox(
                value: isPostCostPaid,
                onChanged: (value) {
                  setState(() {
                    isPostCostPaid = value ?? false;
                  });
                },
              ),
            ],
          ),
          SizedBox(height: 16.h),
          SendUtils.buildTextField(
            controller: _controllers[ControllerKeys.unpaidAmountController] ??
                TextEditingController(),
            hint: 'Unpaid Amount',
          ),
          SizedBox(height: 16.h),
          SendUtils.buildTextField(
            controller: _controllers[ControllerKeys.totalCostEurController] ??
                TextEditingController(),
            hint: 'Total Cost By Europe Currency',
          ),
          SizedBox(height: 16.h),
          SendUtils.buildTextField(
            controller: _controllers[ControllerKeys.unpaidEurCostController] ??
                TextEditingController(),
            hint: 'Unpaid and Will Paid In Europe',
          ),
        ],
      ),
    );
  }

  Widget actionButton() {
    return SendUtils.buildCard(
      title: 'Actions',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionButton(
            'Add Code',
            Colors.blue,
            () async {
              if (_formKey.currentState?.validate() ?? false) {
                try {
                  await _saveRecordWithCode();
                  _clearForm();
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: ${e.toString()}')),
                    );
                  }
                }
              }
            },
          ),
          _buildActionButton(
            'Update Code',
            Colors.pink,
            () async {
              if (currentRecordId == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Please select a record to update')),
                );
                return;
              }

              if (_formKey.currentState?.validate() ?? false) {
                try {
                  final record = SendRecord(
                    id: currentRecordId,
                    // Same fields as in _saveRecordWithCode...
                    date: _controllers[ControllerKeys.dateController]?.text,
                    truckNumber:
                        _controllers[ControllerKeys.truckNumberController]
                            ?.text,
                    codeNumber:
                        _controllers[ControllerKeys.codeNumberController]?.text,
                    // ... (copy all fields from _saveRecordWithCode)
                  );

                  await context
                      .read<SendRecordCubit>()
                      .updateSendRecord(record);
                  _clearForm();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Record updated successfully')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content:
                              Text('Error updating record: ${e.toString()}')),
                    );
                  }
                }
              }
            },
          ),
          _buildActionButton('Make Label', Colors.green, () {
            generateLabelPdf();
          }),
          _buildActionButton('Make Invoice', Colors.purple, () {
            generateInvoicePdf();
          }),
        ],
      ),
    );
  }

  Widget clearButton() {
    return SendUtils.buildCard(
      title: 'Actions',
      child: CustomButton(
        color: Colors.red,
        text: 'Clear',
        function: _clearForm,
        width: 500.w,
      ),
    );
  }

  Widget _buildActionButton(
    String text,
    Color color,
    VoidCallback onPressed,
  ) {
    return CustomButton(
      color: color,
      text: text,
      function: onPressed,
    );
  }

// Enhanced invoice generation
  Future<void> generateInvoicePdf() async {
    try {
      final shipment = ShipmentDetails(
        date: _controllers[ControllerKeys.dateController]?.text ?? '',
        truckNumber:
            _controllers[ControllerKeys.truckNumberController]?.text ?? '',
        codeNumber:
            _controllers[ControllerKeys.codeNumberController]?.text ?? '',
        boxNumber: _controllers[ControllerKeys.boxNumberController]?.text ?? '',
        totalWeight:
            _controllers[ControllerKeys.totalWeightController]?.text ?? '',
        description:
            _controllers[ControllerKeys.goodsDescriptionController]?.text ?? '',
      );

      final sender = SenderInfo(
        name: _controllers[ControllerKeys.senderNameController]?.text ?? '',
        phone: _controllers[ControllerKeys.senderPhoneController]?.text ?? '',
        id: _controllers[ControllerKeys.senderIdController]?.text ?? '',
      );

      final receiver = ReceiverInfo(
        name: _controllers[ControllerKeys.receiverNameController]?.text ?? '',
        phone: _controllers[ControllerKeys.receiverPhoneController]?.text ?? '',
        street: _controllers[ControllerKeys.streetController]?.text ?? '',
        apartment: _controllers[ControllerKeys.apartmentController]?.text ?? '',
        city: _selectedCity,
        country: _selectedCountry,
        zipCode: _controllers[ControllerKeys.zipCodeController]?.text ?? '',
        branch: _selectedBranch ?? '',
      );

      final costs = CostSummary(
        shippingCost:
            _controllers[ControllerKeys.doorToDoorCostController]?.text ?? '',
        insuranceAmount:
            _controllers[ControllerKeys.insuranceAmountController]?.text ?? '',
        totalCost:
            _controllers[ControllerKeys.totalPostCostController]?.text ?? '',
        amountPaid:
            _controllers[ControllerKeys.totalPostCostPaidController]?.text ??
                '',
        amountDue:
            _controllers[ControllerKeys.unpaidAmountController]?.text ?? '',
        totalCostEur:
            _controllers[ControllerKeys.totalCostEurController]?.text ?? '',
        amountDueEur:
            _controllers[ControllerKeys.unpaidEurCostController]?.text ?? '',
      );

      final regularFont = await PDFGenerator.loadCairoFont(isBold: false);
      final boldFont = await PDFGenerator.loadCairoFont(isBold: true);

      final invoice = await PDFGenerator.generateInvoice(
        shipment: shipment,
        sender: sender,
        receiver: receiver,
        costs: costs,
        regularFont: regularFont,
        boldFont: boldFont,
      );
      if (mounted) {
        final result = await showDialog(
          context: context,
          builder: (context) => PDFPreviewDialog(
            pdfFile: invoice,
            title: 'Invoice Preview',
          ),
        );

        // Check if the widget is still mounted before using the context
        if (mounted && result == 'save') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Invoice saved: ${invoice.path}')),
          );
        }
      }
      // Show the PDF preview dialog
    } catch (e) {
      // Check if the widget is still mounted before showing the error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating invoice: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void generateLabelPdf({int currentLabelIndex = 1}) async {
    final palletNumber = int.tryParse(
            _controllers[ControllerKeys.palletNumberController]?.text ?? '1') ??
        1;

    if (currentLabelIndex > palletNumber) {
      return; // Stop when all labels are processed
    }

    await ShippingLabelGenerator.generateShippingLabel(
      sender: SenderDetails(
        name: _controllers[ControllerKeys.senderNameController]?.text ?? '',
      ),
      receiver: ReceiverDetails(
        name: _controllers[ControllerKeys.receiverNameController]?.text ?? '',
        phone: _controllers[ControllerKeys.receiverPhoneController]?.text ?? '',
        city: _selectedCity,
        country: _selectedCountry,
      ),
      shipment: ShipmentInfo(
        date: DateTime.now().toString(),
        time: TimeOfDay.now().toString(),
        itemDetails:
            _controllers[ControllerKeys.goodsDescriptionController]?.text ?? '',
        itemNumber:
            '$currentLabelIndex of $palletNumber', // Dynamic item number
        weight: _controllers[ControllerKeys.weightController]?.text ?? '',
        volumeDifference:
            _controllers[ControllerKeys.additionalKGController]?.text ?? '',
        code: _controllers[ControllerKeys.codeNumberController]?.text ?? '',
        branch: _selectedBranch ?? '',
      ),
      onGenerated: (Uint8List pdfData) async {
        final tempDir = await getTemporaryDirectory();
        final file =
            await File('${tempDir.path}/shipping_label_$currentLabelIndex.pdf')
                .create();
        await file.writeAsBytes(pdfData);

        if (mounted) {
          final result = await showDialog(
            context: context,
            builder: (context) => PDFPreviewDialog(pdfFile: file),
          );

          // Check if the user printed or downloaded the current label
          if (result == 'save' || result == 'print') {
            // Show the next label
            generateLabelPdf(currentLabelIndex: currentLabelIndex + 1);
          }
        }
      },
    );
  }
}
