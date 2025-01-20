import 'dart:io';

import 'package:app/cubits/brach_cubit/branch_cubit.dart';
import 'package:app/cubits/brach_cubit/branch_states.dart';
import 'package:app/cubits/cities_cubit/cities_cubit.dart';
import 'package:app/cubits/cities_cubit/cities_state.dart';
import 'package:app/cubits/countries_cubit/countries_cubit.dart';
import 'package:app/cubits/countries_cubit/countries_state.dart';
import 'package:app/cubits/currencies_cubit/currencies_cubit.dart';
import 'package:app/cubits/login_cubit/login_cubit_cubit.dart';
import 'package:app/cubits/send_cubit/send_cubit.dart';
import 'package:app/cubits/send_cubit/send_state.dart';
import 'package:app/helper/sql_helper.dart';
import 'package:app/models/branches_model.dart';
import 'package:app/models/city_model.dart';
import 'package:app/models/country_model.dart';
import 'package:app/models/good_description_model.dart';
import 'package:app/models/send_model.dart';
import 'package:app/pages/main_pages/invoice_pdf/invoice_pdf.dart';
import 'package:app/pages/main_pages/invoice_pdf/pdf_preview_dialog.dart';
import 'package:app/pages/main_pages/label_pdf/label_pdf.dart';
import 'package:app/pages/main_pages/label_pdf/pdf_dialog.dart';
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
  double _selectedCurrencyAgainstIQD = 1.0;
  File? _selectedIdentificationPhoto;
  String? selectedValue; // Add this to your State class
  final Map<String, TextEditingController> _controllers = {
    ControllerKeys.dateController: TextEditingController(),
    ControllerKeys.resultController: TextEditingController(),
    ControllerKeys.euroRateController: TextEditingController(),
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

  bool areDimensionsEnabled = false;
  bool isInsuranceEnabled = false;
  bool isPostCostPaid = false;

  IdType? _selectedIdType;
  String? _lastTruckNumber;
  String? _selectedLanguage = '';
  double _boxPrice = 0.0;
  // Add this method to fetch currencies
  void _fetchCurrencies() {
    try {
      context.read<CurrencyCubit>().fetchCurrencies();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load currencies: $e')),
      );
    }
  }

  // Add this method to update costs based on the selected currency

  // Add this method to handle currency selection

  @override
  void initState() {
    super.initState();
    _restoreFormData();
    // Set the initial date
    _controllers[ControllerKeys.dateController]?.text =
        DateFormat('yyyy-MM-dd').format(DateTime.now());

    // Add listeners for automatic calculations
    for (var controller in _controllers.values) {
      controller.addListener(() => SendPageLogic.updateCalculations(
            controllers: _controllers,
            isInsuranceEnabled: isInsuranceEnabled,
            euroRate: _selectedCurrencyAgainstIQD,
          ));
    }

    // Retrieve the selected branch from AuthCubit
    final authCubit = context.read<AuthCubit>();
    _selectedBranch = authCubit.selectedBranch;
    if (kDebugMode) {
      print('Selected Branch: $_selectedBranch');
    }
    // Fetch the branch details and set the Agent and Code Number fields
    if (_selectedBranch != null) {
      _fetchBranchAndSetAgentAndCode(_selectedBranch!);
    }
    _fetchCurrencies();
    // Fetch countries and cities
    context.read<CountryCubit>().fetchCountries();
    context.read<CityCubit>().fetchCities();
    context.read<SendRecordCubit>().fetchAllSendRecords();
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  void deactivate() {
    _saveFormData(); // Save form data before the widget is disposed
    super.deactivate();
  }

  void _saveFormData() {
    final formData = {
      'controllers':
          _controllers.map((key, controller) => MapEntry(key, controller.text)),
      'isInsuranceEnabled': isInsuranceEnabled,
      'areDimensionsEnabled': areDimensionsEnabled,
      'selectedCountry': _selectedCountry,
      'selectedCity': _selectedCity,
    };

    context.read<SendRecordCubit>().saveFormData(formData);
  }

  void _restoreFormData() {
    final formData = context.read<SendRecordCubit>().getFormData();

    if (formData.isNotEmpty) {
      // Restore field values
      for (var key in _controllers.keys) {
        _controllers[key]?.text = formData['controllers'][key] ?? '';
      }

      // Restore checkbox states
      setState(() {
        isInsuranceEnabled = formData['isInsuranceEnabled'] ?? false;
        areDimensionsEnabled = formData['areDimensionsEnabled'] ?? false;
      });

      // Restore selected country and city
      setState(() {
        _selectedCountry = formData['selectedCountry'] ?? '';
        _selectedCity = formData['selectedCity'] ?? '';
      });
    }
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

      // Set the agent field to the contact person name of the selected branch
      setState(() {
        _selectedAgent = selectedBranch.contactPersonName;
      });
      setState(() {
        _selectedLanguage = selectedBranch.invoiceLanguage;
      });
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

    // Filter records for the same truck and branch
    final sameTruckRecords = records
        .where((record) =>
            record.truckNumber == truckNumber &&
            record.branchName == branchName)
        .toList();

    if (sameTruckRecords.isEmpty) {
      // If no records exist for this truck and branch, use the initial code number from the branch
      return _initialCodeNumber;
    }

    // Find the latest code number for this truck and branch
    final latestCode = sameTruckRecords
        .map((record) => record.codeNumber ?? 'BA-2400000')
        .reduce((a, b) => a.compareTo(b) > 0 ? a : b);

    // Split the code into prefix and sequence parts
    final codeParts = latestCode.split('-');
    if (codeParts.length == 2) {
      final prefix = codeParts[0]; // "BA"
      final numericPart = codeParts[1]; // "2400001"

      // Extract the year prefix (first two digits of the numeric part)
      final yearPrefix = numericPart.substring(0, 2); // "24"

      // Extract the sequence number (remaining digits)
      final sequenceNumber = numericPart.substring(2); // "0001"

      // Increment the sequence number
      final incrementedNumber = (int.tryParse(sequenceNumber) ?? 0) + 1;

      // Pad the sequence number with leading zeros to match the original length
      final newSequenceNumber =
          incrementedNumber.toString().padLeft(sequenceNumber.length, '0');

      // Combine the prefix, year prefix, and new sequence number
      return '$prefix-$yearPrefix$newSequenceNumber';
    }

    // Fallback if the code format is invalid
    return 'BA-2400001';
  }

  Future<void> _saveRecordWithCode() async {
    // Validate the form
    if (_formKey.currentState?.validate() == true) {
      // Proceed only if the form is valid
      try {
        // Validate required fields explicitly
        if (_controllers[ControllerKeys.truckNumberController]?.text == null ||
            _controllers[ControllerKeys.truckNumberController]!.text.isEmpty) {
          throw Exception('Truck Number is required');
        }

        if (_selectedBranch == null || _selectedBranch!.isEmpty) {
          throw Exception('Branch is required');
        }

        if (_controllers[ControllerKeys.senderNameController]?.text == null ||
            _controllers[ControllerKeys.senderNameController]!.text.isEmpty) {
          throw Exception('Sender Name is required');
        }

        if (_controllers[ControllerKeys.senderPhoneController]?.text == null ||
            _controllers[ControllerKeys.senderPhoneController]!.text.isEmpty) {
          throw Exception('Sender Phone is required');
        }

        if (_controllers[ControllerKeys.receiverNameController]?.text == null ||
            _controllers[ControllerKeys.receiverNameController]!.text.isEmpty) {
          throw Exception('Receiver Name is required');
        }

        if (_controllers[ControllerKeys.receiverPhoneController]?.text ==
                null ||
            _controllers[ControllerKeys.receiverPhoneController]!
                .text
                .isEmpty) {
          throw Exception('Receiver Phone is required');
        }

        if (_selectedCountry.isEmpty) {
          throw Exception('Country is required');
        }

        if (_selectedCity.isEmpty) {
          throw Exception('City is required');
        }

        if (_controllers[ControllerKeys.weightController]?.text == null ||
            _controllers[ControllerKeys.weightController]!.text.isEmpty) {
          throw Exception('Weight is required');
        }
        if (_controllers[ControllerKeys.boxNumberController]?.text == null ||
            _controllers[ControllerKeys.boxNumberController]!.text.isEmpty) {
          throw Exception('Box Number is required');
        }
        if (_controllers[ControllerKeys.weightController]?.text == null ||
            _controllers[ControllerKeys.weightController]!.text.isEmpty) {
          throw Exception('Weight is required');
        }

        if (areDimensionsEnabled) {
          if (_controllers[ControllerKeys.lengthController]?.text == null ||
              _controllers[ControllerKeys.lengthController]!.text.isEmpty) {
            throw Exception('Length is required');
          }

          if (_controllers[ControllerKeys.widthController]?.text == null ||
              _controllers[ControllerKeys.widthController]!.text.isEmpty) {
            throw Exception('Width is required');
          }

          if (_controllers[ControllerKeys.heightController]?.text == null ||
              _controllers[ControllerKeys.heightController]!.text.isEmpty) {
            throw Exception('Height is required');
          }
        }
        if (isInsuranceEnabled) {
          if (_controllers[ControllerKeys.insuranceAmountController]?.text ==
                  null ||
              _controllers[ControllerKeys.insuranceAmountController]!
                  .text
                  .isEmpty) {
            throw Exception('Insurance Amount is required');
          }
        }

        // Generate the next code number for this truck and branch
        final nextCodeNumber = await _getNextCodeNumber(
          _controllers[ControllerKeys.truckNumberController]!.text,
          _selectedBranch!,
        );

        // Update the Code Number field in the UI
        setState(() {
          _controllers[ControllerKeys.codeNumberController]?.text =
              nextCodeNumber;
        });

        // Create a new SendRecord
        final record = SendRecord(
          // Shipment Info
          date: _controllers[ControllerKeys.dateController]?.text,
          truckNumber: _controllers[ControllerKeys.truckNumberController]?.text,
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
          receiverName:
              _controllers[ControllerKeys.receiverNameController]?.text,
          receiverPhone:
              _controllers[ControllerKeys.receiverPhoneController]?.text,
          receiverCountry: _selectedCountry,
          receiverCity: _selectedCity,

          // All other fields as per your model...
          streetName: _controllers[ControllerKeys.streetController]?.text,
          apartmentNumber:
              _controllers[ControllerKeys.apartmentController]?.text,
          zipCode: _controllers[ControllerKeys.zipCodeController]?.text,
          insurancePercent: double.tryParse(
              _controllers[ControllerKeys.insurancePercentController]?.text ??
                  ''),
          goodsValue: double.tryParse(
              _controllers[ControllerKeys.goodsValueController]?.text ?? ''),

          // Costs
          doorToDoorPrice: double.tryParse(
              _controllers[ControllerKeys.doorToDoorPriceController]?.text ??
                  ''),
          pricePerKg: double.tryParse(
              _controllers[ControllerKeys.pricePerKgController]?.text ?? ''),
          minimumPrice: double.tryParse(
              _controllers[ControllerKeys.minimumPriceController]?.text ?? ''),
          insuranceAmount: double.tryParse(
              _controllers[ControllerKeys.insuranceAmountController]?.text ??
                  ''),
          customsCost: double.tryParse(
              _controllers[ControllerKeys.customsCostController]?.text ?? ''),
          exportDocCost: double.tryParse(
              _controllers[ControllerKeys.exportDocCostController]?.text ?? ''),
          boxPackingCost: double.tryParse(
              _controllers[ControllerKeys.boxPackingCostController]?.text ??
                  ''),
          doorToDoorCost: double.tryParse(
              _controllers[ControllerKeys.doorToDoorCostController]?.text ??
                  ''),
          postSubCost: double.tryParse(
              _controllers[ControllerKeys.postSubCostController]?.text ?? ''),
          discountAmount: double.tryParse(
              _controllers[ControllerKeys.discountAmountController]?.text ??
                  ''),
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Record saved successfully')),
          );
        }

        // Clear the form (except date, truck number, code number, agent, and branch)
        _clearForm();
      } catch (e) {
        // Ensure the widget is still mounted before showing the error
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving record: ${e.toString()}')),
          );
        }
      }
    } else {
      // Show an error message if the form is invalid
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fix validation errors before saving'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updateRecord() async {
    // Validate the form
    if (_formKey.currentState?.validate() == true) {
      // Proceed only if the form is valid
      try {
        // Validate required fields explicitly
        if (_controllers[ControllerKeys.truckNumberController]?.text == null ||
            _controllers[ControllerKeys.truckNumberController]!.text.isEmpty) {
          throw Exception('Truck Number is required');
        }

        if (_selectedBranch == null || _selectedBranch!.isEmpty) {
          throw Exception('Branch is required');
        }

        if (_controllers[ControllerKeys.senderNameController]?.text == null ||
            _controllers[ControllerKeys.senderNameController]!.text.isEmpty) {
          throw Exception('Sender Name is required');
        }

        if (_controllers[ControllerKeys.senderPhoneController]?.text == null ||
            _controllers[ControllerKeys.senderPhoneController]!.text.isEmpty) {
          throw Exception('Sender Phone is required');
        }

        if (_controllers[ControllerKeys.receiverNameController]?.text == null ||
            _controllers[ControllerKeys.receiverNameController]!.text.isEmpty) {
          throw Exception('Receiver Name is required');
        }

        if (_controllers[ControllerKeys.receiverPhoneController]?.text ==
                null ||
            _controllers[ControllerKeys.receiverPhoneController]!
                .text
                .isEmpty) {
          throw Exception('Receiver Phone is required');
        }

        if (_selectedCountry.isEmpty) {
          throw Exception('Country is required');
        }

        if (_selectedCity.isEmpty) {
          throw Exception('City is required');
        }

        if (_controllers[ControllerKeys.weightController]?.text == null ||
            _controllers[ControllerKeys.weightController]!.text.isEmpty) {
          throw Exception('Weight is required');
        }

        if (_controllers[ControllerKeys.boxNumberController]?.text == null ||
            _controllers[ControllerKeys.boxNumberController]!.text.isEmpty) {
          throw Exception('Box Number is required');
        }

        if (areDimensionsEnabled) {
          if (_controllers[ControllerKeys.lengthController]?.text == null ||
              _controllers[ControllerKeys.lengthController]!.text.isEmpty) {
            throw Exception('Length is required');
          }

          if (_controllers[ControllerKeys.widthController]?.text == null ||
              _controllers[ControllerKeys.widthController]!.text.isEmpty) {
            throw Exception('Width is required');
          }

          if (_controllers[ControllerKeys.heightController]?.text == null ||
              _controllers[ControllerKeys.heightController]!.text.isEmpty) {
            throw Exception('Height is required');
          }
        }

        if (isInsuranceEnabled) {
          if (_controllers[ControllerKeys.insuranceAmountController]?.text ==
                  null ||
              _controllers[ControllerKeys.insuranceAmountController]!
                  .text
                  .isEmpty) {
            throw Exception('Insurance Amount is required');
          }
        }

        // Create a new SendRecord with updated values
        final record = SendRecord(
          id: currentRecordId, // Use the existing record ID
          // Shipment Info
          date: _controllers[ControllerKeys.dateController]?.text,
          truckNumber: _controllers[ControllerKeys.truckNumberController]?.text,
          codeNumber: _controllers[ControllerKeys.codeNumberController]?.text,
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
          receiverName:
              _controllers[ControllerKeys.receiverNameController]?.text,
          receiverPhone:
              _controllers[ControllerKeys.receiverPhoneController]?.text,
          receiverCountry: _selectedCountry,
          receiverCity: _selectedCity,

          // All other fields as per your model...
          streetName: _controllers[ControllerKeys.streetController]?.text,
          apartmentNumber:
              _controllers[ControllerKeys.apartmentController]?.text,
          zipCode: _controllers[ControllerKeys.zipCodeController]?.text,
          insurancePercent: double.tryParse(
              _controllers[ControllerKeys.insurancePercentController]?.text ??
                  ''),
          goodsValue: double.tryParse(
              _controllers[ControllerKeys.goodsValueController]?.text ?? ''),

          // Costs
          doorToDoorPrice: double.tryParse(
              _controllers[ControllerKeys.doorToDoorPriceController]?.text ??
                  ''),
          pricePerKg: double.tryParse(
              _controllers[ControllerKeys.pricePerKgController]?.text ?? ''),
          minimumPrice: double.tryParse(
              _controllers[ControllerKeys.minimumPriceController]?.text ?? ''),
          insuranceAmount: double.tryParse(
              _controllers[ControllerKeys.insuranceAmountController]?.text ??
                  ''),
          customsCost: double.tryParse(
              _controllers[ControllerKeys.customsCostController]?.text ?? ''),
          exportDocCost: double.tryParse(
              _controllers[ControllerKeys.exportDocCostController]?.text ?? ''),
          boxPackingCost: double.tryParse(
              _controllers[ControllerKeys.boxPackingCostController]?.text ??
                  ''),
          doorToDoorCost: double.tryParse(
              _controllers[ControllerKeys.doorToDoorCostController]?.text ??
                  ''),
          postSubCost: double.tryParse(
              _controllers[ControllerKeys.postSubCostController]?.text ?? ''),
          discountAmount: double.tryParse(
              _controllers[ControllerKeys.discountAmountController]?.text ??
                  ''),
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

        // Update the record
        if (mounted) {
          await context.read<SendRecordCubit>().updateSendRecord(record);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Record updated successfully')),
          );
        }

        // Clear the form (except date, truck number, code number, agent, and branch)
        _clearForm();
      } catch (e) {
        // Ensure the widget is still mounted before showing the error
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating record: ${e.toString()}')),
          );
        }
      }
    } else {
      // Show an error message if the form is invalid
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fix validation errors before updating'),
          backgroundColor: Colors.red,
        ),
      );
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

  String? conditionalValidator(
      bool condition, String? value, String errorMessage) {
    if (condition && (value == null || value.isEmpty)) {
      return errorMessage; // Return the error message if the field is required and empty
    }
    return null; // Return null if the field is valid or not required
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
    final authCubit = context.read<AuthCubit>();
    if (!authCubit.isUser() && !authCubit.isManager()) {
      return const Center(
        child: Text('You are not authorized to access the Send page.'),
      );
    }
    return Shortcuts(
      shortcuts: {
        // Define the shortcut (Ctrl + F)
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyF):
            const ActivateIntent(),
      },
      child: Actions(
        actions: {
          // Map the ActivateIntent to the openDialog function
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (ActivateIntent intent) {
              if (kDebugMode) {
                print('Shortcut triggered: Ctrl + F');
              }
              _openCodeListDialog(); // Call the function to open the dialog
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: BlocListener<SendRecordCubit, SendRecordState>(
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
                  child: Column(
                    children: [
                      // First Row (Three Cards with Same Height)
                      IntrinsicHeight(
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildCard(child: buildMainCard()),
                            ),
                            // SizedBox(width: 5.w), // Add spacing between cards
                            Expanded(
                              child: _buildCard(child: agentCard()),
                            ),
                            // SizedBox(width: 5.w), // Add spacing between cards
                            Expanded(
                              child: _buildCard(child: doorToDoorPriceCard()),
                            ),
                          ],
                        ),
                      ),
                      // SizedBox(height: 5.h), // Add spacing between rows
                      // Second Row (Three Columns with Same Height)
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // First Column
                            Flexible(
                              child: Column(
                                children: [
                                  _buildCard(child: buildSenderCard()),
                                  // SizedBox(
                                  //     height:
                                  //         5.h), // Add spacing between cards
                                  Expanded(
                                    child: _buildCard(child: buildItemsCard()),
                                  ),
                                ],
                              ),
                            ),
                            // SizedBox(
                            //     width: 5.w), // Add spacing between columns
                            // Second Column
                            Flexible(
                              child: Column(
                                children: [
                                  _buildCard(child: receiverCard()),
                                  // SizedBox(
                                  //     height:
                                  //         5.h), // Add spacing between cards
                                  _buildCard(child: ifPostCard()),
                                  // SizedBox(
                                  //     height:
                                  //         5.h), // Add spacing between cards
                                  Expanded(
                                    child:
                                        _buildCard(child: insuranceInfoCard()),
                                  ),
                                ],
                              ),
                            ),
                            // SizedBox(
                            //     width: 5.w), // Add spacing between columns
                            // Third Column
                            Flexible(
                              child: Column(
                                children: [
                                  Expanded(
                                    child: _buildCard(child: costsCard()),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // SizedBox(height: 5.h), // Add spacing between rows
                      // Action Buttons Row
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
              context: context,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Truck Number is required';
                }
                return null;
              },
            ),
          ),
          SizedBox(height: 10.h),
          SendUtils.buildInputRow(
            icon: Icons.code,
            child: Row(
              children: [
                Expanded(
                  child: SendUtils.buildTextField(
                    controller:
                        _controllers[ControllerKeys.codeNumberController] ??
                            TextEditingController(),
                    hint: 'Code Number',
                    enabled: false,
                    context: context, // Make the field non-editable
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Code Number is required';
                      }
                      return null;
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete,
                  ), // Delete icon
                  onPressed: _deleteRecordByCodeNumber, // Delete function
                  tooltip: 'Delete Record', // Tooltip for better UX
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteRecordByCodeNumber() async {
    final codeNumber = _controllers[ControllerKeys.codeNumberController]?.text;

    if (codeNumber == null || codeNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid code number')),
      );
      return;
    }

    try {
      // Fetch all records
      final records =
          await context.read<SendRecordCubit>().fetchAllSendRecords();

      // Find the record with the matching code number
      final recordToUpdate = records.firstWhere(
        (record) => record.codeNumber == codeNumber,
        orElse: () => SendRecord(), // Fallback if not found
      );

      // Check if the record was found
      if (recordToUpdate.id == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Record not found')),
        );
        return;
      }

      // Show confirmation dialog
      final shouldClear = await _showDeleteConfirmationDialog();
      if (!shouldClear) {
        return; // User canceled the operation
      }

      // Use the new method to clear all fields except codeNumber
      await context
          .read<SendRecordCubit>()
          .databaseHelper
          .updateSendRecordFields(
            recordToUpdate.id!, // Pass the record ID
            codeNumber, // Pass the codeNumber to ensure it's not cleared
          );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Record cleared successfully (except Code Number)')),
      );

      // Clear the form after successful deletion
      _clearForm();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error clearing record: $e')),
      );
    }
  }

  Future<bool> _showDeleteConfirmationDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Confirm Delete'),
              content:
                  const Text('Are you sure you want to delete this record?'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context)
                        .pop(false); // Return false (do not delete)
                  },
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context)
                        .pop(true); // Return true (confirm delete)
                  },
                  child:
                      const Text('Delete', style: TextStyle(color: Colors.red)),
                ),
              ],
            );
          },
        ) ??
        false; // Return false if the dialog is dismissed
  }

  Widget buildSenderCard() {
    return SendUtils.buildCard(
      title: 'Sender',
      child: Column(
        // mainAxisSize: MainAxisSize.max,
        children: [
          SendUtils.buildInputRow(
            icon: Icons.person_outline,
            child: SendUtils.buildTextField(
              controller: _controllers[ControllerKeys.senderNameController] ??
                  TextEditingController(),
              hint: 'Sender Name',

              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Sender Name is required';
                }

                return null;
              },
              context: context, // Pass the context here
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
              context: context, // Pass the context here
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
                      if (!RegExp(r'^[0-9]+$').hasMatch(value ?? '')) {
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
                            ? const Icon(
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
              child: TextFormField(
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18.sp,
                ),
                controller:
                    _controllers[ControllerKeys.goodsDescriptionController] ??
                        TextEditingController(),
                enabled: false,

                decoration: InputDecoration(
                  hintText: 'Goods Description',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey[200],
                ),

                maxLines: 3, // Allow multiple lines for notes
                onChanged: (value) {
                  // Handle the note input if needed
                },
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
                  onChanged: (value) {
                    final boxNumber = int.tryParse(value) ?? 0;
                    final boxPackingCost =
                        boxNumber * _boxPrice; // Use the stored box price
                    _controllers[ControllerKeys.boxPackingCostController]
                        ?.text = boxPackingCost.toStringAsFixed(2);
                    SendPageLogic.updateCalculations(
                      controllers: _controllers,
                      isInsuranceEnabled: isInsuranceEnabled,
                      euroRate: _selectedCurrencyAgainstIQD,
                    );
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Box number is required';
                    }
                    return null;
                  },
                  context: context,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: SendUtils.buildTextField(
                  controller:
                      _controllers[ControllerKeys.palletNumberController] ??
                          TextEditingController(),
                  hint: 'Pallet No.',
                  optional: true,
                  // Pallet field is optional, so no validator
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          SendUtils.buildTextField(
            controller: _controllers[ControllerKeys.weightController] ??
                TextEditingController(),
            hint: 'Real Weight KG',
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Real Weight is required';
              }
              final weight = double.tryParse(value);
              if (weight == null || weight <= 0) {
                return 'Please enter a valid positive number';
              }
              return null;
            },
            context: context,
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
                  validator: (value) {
                    if (areDimensionsEnabled &&
                        (value == null || value.isEmpty)) {
                      return 'Length is required';
                    }
                    return null;
                  },
                  context: context,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: SendUtils.buildTextField(
                  controller: _controllers[ControllerKeys.widthController] ??
                      TextEditingController(),
                  hint: 'W',
                  enabled: areDimensionsEnabled,
                  validator: (value) {
                    if (areDimensionsEnabled &&
                        (value == null || value.isEmpty)) {
                      return 'Width is required';
                    }
                    return null;
                  },
                  context: context,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: SendUtils.buildTextField(
                  controller: _controllers[ControllerKeys.heightController] ??
                      TextEditingController(),
                  hint: 'H',
                  enabled: areDimensionsEnabled,
                  validator: (value) {
                    if (areDimensionsEnabled &&
                        (value == null || value.isEmpty)) {
                      return 'Height is required';
                    }
                    return null;
                  },
                  context: context,
                ),
              ),
              SizedBox(width: 8.w),
              Checkbox(
                value: areDimensionsEnabled,
                onChanged: (value) {
                  setState(() {
                    areDimensionsEnabled = value ?? true;
                    // Clear fields when checkbox is unchecked
                    if (!areDimensionsEnabled) {
                      _controllers[ControllerKeys.lengthController]?.clear();
                      _controllers[ControllerKeys.widthController]?.clear();
                      _controllers[ControllerKeys.heightController]?.clear();
                      _controllers[ControllerKeys.additionalKGController]
                          ?.clear();
                      selectedValue = null;
                      _controllers[ControllerKeys.resultController]?.clear();
                    }
                  });
                },
              ),
            ],
          ),
          SizedBox(height: 8.h),
          SendUtils.buildDropdownField(
            label: 'Select Amount',
            items: areDimensionsEnabled ? ['5000', '6000'] : [],
            value: selectedValue,
            onChanged: (String? newValue) {
              setState(() {
                selectedValue = newValue;
                _calculateResult(); // Recalculate result when select amount changes
              });
            },
            validator: (value) {
              if (areDimensionsEnabled && (value == null || value.isEmpty)) {
                return 'Select Amount is required';
              }
              return null;
            },
            context: context,
          ),
          SizedBox(height: 8.h),
          SendUtils.buildTextField(
            controller: _controllers[ControllerKeys.resultController] ??
                TextEditingController(),
            hint: 'Result (L*H*W / Select Amount)',
            enabled: false, // Make the field read-only
          ),
          SizedBox(height: 8.h),
          SendUtils.buildTextField(
            controller: _controllers[ControllerKeys.additionalKGController] ??
                TextEditingController(),
            hint: 'Additional KG',
            enabled: areDimensionsEnabled,
            optional: true,
            onChanged: (value) {
              _calculateResult(); // Recalculate result when additional weight changes
            },
          ),
          SizedBox(height: 8.h),
          SendUtils.buildTextField(
            controller: _controllers[ControllerKeys.totalWeightController] ??
                TextEditingController(),
            hint: 'Total Weight KG',
            enabled: false, // Make the field read-only
          ),
        ],
      ),
    );
  }

  void _calculateResult() {
    final length = double.tryParse(
            _controllers[ControllerKeys.lengthController]?.text ?? '0') ??
        0;
    final width = double.tryParse(
            _controllers[ControllerKeys.widthController]?.text ?? '0') ??
        0;
    final height = double.tryParse(
            _controllers[ControllerKeys.heightController]?.text ?? '0') ??
        0;
    final selectAmount = double.tryParse(selectedValue ?? '0') ?? 0;

    if (selectAmount > 0) {
      final result = (length * width * height) / selectAmount;
      _controllers[ControllerKeys.resultController]?.text =
          result.toStringAsFixed(2);
    } else {
      _controllers[ControllerKeys.resultController]?.text = '';
    }
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
                  controller:
                      _controllers[ControllerKeys.insurancePercentController] ??
                          TextEditingController(),
                  hint: 'Insurance Amount',
                  enabled:
                      isInsuranceEnabled, // Enable/disable based on checkbox
                  validator: (value) {
                    return conditionalValidator(
                      isInsuranceEnabled, // Condition: Is insurance enabled?
                      value, // Field value
                      'Insurance Amount is required', // Error message
                    );
                  },
                  context: context,
                ),
              ),
              Checkbox(
                value: isInsuranceEnabled,
                onChanged: (value) {
                  setState(() {
                    isInsuranceEnabled = value ?? true;
                    // Clear the field when checkbox is unchecked
                    if (!isInsuranceEnabled) {
                      _controllers[ControllerKeys.insurancePercentController]
                          ?.clear();
                    }
                  });
                },
              ),
            ],
          ),
          SizedBox(height: 8.h),
          SendUtils.buildTextField(
            hint: 'Goods Value',
            enabled: true,
            controller: _controllers[ControllerKeys.goodsValueController] ??
                TextEditingController(),
            optional: true, // This field is optional
          ),
          SizedBox(height: 12.h),
          // Replace the static container with a TextField for notes
          TextFormField(
            decoration: InputDecoration(
              hintText: 'Write notes here...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.grey[200],
            ),
            maxLines: 4, // Allow multiple lines for notes
            onChanged: (value) {
              // Handle the note input if needed
            },
          ),
        ],
      ),
    );
  }

  bool _isPostCitySelected() {
    final cityState = context.read<CityCubit>().state;
    if (cityState is CityLoadedState) {
      final selectedCity = cityState.cities.firstWhere(
        (city) => city.cityName == _selectedCity,
        orElse: () => City(
          cityName: '',
          country: '',
          hasAgent: false,
          isPost: false,
          doorToDoorPrice: 0,
          priceKg: 0,
          minimumPrice: 0,
          boxPrice: 0,
        ),
      );
      return selectedCity
          .isPost; // Return true if the city supports postal services
    }
    return false; // Default to false if no city is selected
  }

  Widget ifPostCard() {
    // Check if the selected city supports postal services
    final isPostCity = _selectedCity.isNotEmpty && _isPostCitySelected();

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
              enabled: isPostCity, // Disable if not a post city
            ),
          ),
          SendUtils.buildInputRow(
            icon: Icons.markunread_mailbox,
            child: SendUtils.buildTextField(
              hint: 'ZIP Code',
              controller: _controllers[ControllerKeys.zipCodeController] ??
                  TextEditingController(),
              enabled: isPostCity, // Disable if not a post city
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
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Receiver Name is required';
                }
                return null;
              },
              context: context,
            ),
          ),
          SendUtils.buildInputRow(
            icon: Icons.phone_outlined,
            child: SendUtils.buildTextField(
              hint: 'Receiver Phone',
              controller:
                  _controllers[ControllerKeys.receiverPhoneController] ??
                      TextEditingController(),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Receiver Phone is required';
                }
                return null;
              },
              context: context,
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

  Widget _buildCountryDropdown() {
    return BlocConsumer<CountryCubit, CountryState>(
      listener: (context, state) {
        if (state is CountryError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      builder: (context, state) {
        final countries = state is CountryLoaded
            ? state.countries
                .where((country) => country.hasAgent)
                .map((country) => country.countryName)
                .toList()
            : <String>[];

        if (state is CountryLoaded) {
          return SendUtils.buildInputRow(
            icon: Icons.flag,
            child: SendUtils.buildDropdownField(
              context: context,
              label: 'Country',
              items: countries,
              value: _selectedCountry,
              height: 65.h,
              onChanged: (String? newValue) {
                // First update the state synchronously
                setState(() {
                  _selectedCountry = newValue ?? '';
                  _selectedCity = '';

                  final selectedCountry = state.countries.firstWhere(
                    (country) => country.countryName == _selectedCountry,
                    orElse: () => Country(
                      id: null,
                      countryName: '',
                      alpha2Code: '',
                      zipCodeDigit1: '',
                      zipCodeDigit2: '',
                      zipCodeText: '',
                      currency: '',
                      currencyAgainstIQD: 1.0,
                      hasAgent: false,
                      maxWeightKG: 0,
                      flagBoxLabel: '',
                      postBoxLabel: '',
                    ),
                  );
                  _selectedCurrencyAgainstIQD =
                      selectedCountry.currencyAgainstIQD;
                });

                // Then perform async operations outside setState
                _handleCountryChange(context);
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Country is required';
                }
                return null;
              },
            ),
          );
        } else {
          return const CircularProgressIndicator();
        }
      },
    );
  }

// Separate method to handle async operations
  Future<void> _handleCountryChange(BuildContext context) async {
    await context.read<CityCubit>().fetchCities();

    final cityState = context.read<CityCubit>().state;
    if (cityState is CityLoadedState) {
      final cities = cityState.cities
          .where((city) => city.country == _selectedCountry)
          .toList();

      if (cities.isEmpty) {
        _resetCityDependentFields();
      }
    }
  }

  void _resetCityDependentFields() {
    setState(() {
      _controllers[ControllerKeys.doorToDoorPriceController]?.clear();
      _controllers[ControllerKeys.pricePerKgController]?.clear();
      _controllers[ControllerKeys.minimumPriceController]?.clear();
      _controllers[ControllerKeys.boxPackingCostController]?.clear();
      _controllers[ControllerKeys.streetController]?.clear();
      _controllers[ControllerKeys.zipCodeController]?.clear();
    });
  }

  void _openCodeListDialog() {
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

  Widget _buildCityDropdown() {
    return BlocConsumer<CityCubit, CityState>(
      listener: (context, state) {
        if (state is CityErrorState) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage)),
          );
        }
      },
      builder: (context, state) {
        List<String> cityNames = [];

        // Check if the state is CityLoadedState
        if (state is CityLoadedState) {
          // Filter cities to include only those with hasAgent = true and matching the selected country
          final citiesWithAgent = state.cities
              .where((city) =>
                  city.country == _selectedCountry &&
                  city.hasAgent) // Filter by country and hasAgent
              .toList();

          cityNames = citiesWithAgent.map((city) => city.cityName).toList();
        }

        return SendUtils.buildInputRow(
          icon: Icons.location_on,
          child: SendUtils.buildDropdownField(
            context: context,
            label: 'City',
            items: cityNames,
            value: _selectedCity,
            height: 65.h,
            onChanged: (String? newValue) async {
              if (newValue != null) {
                setState(() {
                  _selectedCity = newValue;
                });

                // Fetch the city details based on the selected city name
                if (state is CityLoadedState) {
                  final city = state.cities.firstWhere(
                    (city) => city.cityName == newValue,
                    orElse: () => City(
                      cityName: '',
                      country: '',
                      hasAgent: false,
                      isPost: false,
                      doorToDoorPrice: 0,
                      priceKg: 0,
                      minimumPrice: 0,
                      boxPrice: 0,
                    ),
                  );

                  // Update the fields with the city's prices
                  _controllers[ControllerKeys.doorToDoorPriceController]?.text =
                      city.doorToDoorPrice.toString();
                  _controllers[ControllerKeys.pricePerKgController]?.text =
                      city.priceKg.toString();
                  _controllers[ControllerKeys.minimumPriceController]?.text =
                      city.minimumPrice.toString();

                  // Set the box price from the selected city
                  setState(() {
                    _boxPrice =
                        city.boxPrice; // Store the box price in the variable
                  });

                  // Calculate and update the Box Packing Cost
                  final boxNumber = int.tryParse(
                          _controllers[ControllerKeys.boxNumberController]
                                  ?.text ??
                              '0') ??
                      0;
                  final boxPackingCost =
                      boxNumber * _boxPrice; // Use the stored box price
                  _controllers[ControllerKeys.boxPackingCostController]?.text =
                      boxPackingCost.toStringAsFixed(2);

                  // Trigger calculations
                  SendPageLogic.updateCalculations(
                      controllers: _controllers,
                      isInsuranceEnabled: isInsuranceEnabled,
                      euroRate: _selectedCurrencyAgainstIQD);

                  // Check if the selected city supports postal services
                  if (!city.isPost) {
                    // Clear the postal fields if the city does not support postal services
                    _controllers[ControllerKeys.streetController]?.clear();
                    _controllers[ControllerKeys.zipCodeController]?.clear();
                  }
                }
              }
              // Update city-dependent fields
              _updateCityDependentFields(newValue!);
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'City is required';
              }
              return null;
            },
          ),
        );
      },
    );
  }

  void _updateCityDependentFields(String cityName) {
    final cityState = context.read<CityCubit>().state;
    if (cityState is CityLoadedState) {
      final city = cityState.cities.firstWhere(
        (city) => city.cityName == cityName,
        orElse: () => City(
          cityName: '',
          country: '',
          hasAgent: false,
          isPost: false,
          doorToDoorPrice: 0,
          priceKg: 0,
          minimumPrice: 0,
          boxPrice: 0,
        ),
      );

      setState(() {
        _controllers[ControllerKeys.doorToDoorPriceController]?.text =
            city.doorToDoorPrice.toString();
        _controllers[ControllerKeys.pricePerKgController]?.text =
            city.priceKg.toString();
        _controllers[ControllerKeys.minimumPriceController]?.text =
            city.minimumPrice.toString();
      });
    }
  }

  Widget _buildBranchDropdown() {
    return BlocConsumer<BranchCubit, BranchState>(
      listener: (context, state) {
        if (state is BranchErrorState) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage)),
          );
        }
      },
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
    return BlocBuilder<SendRecordCubit, SendRecordState>(
      builder: (context, state) {
        List<String> codeNumbers = [];
        List<SendRecord> records = [];

        // Check if the state is SendRecordListLoaded
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

        return SendUtils.buildDropdownField(
          context: context,
          label: hint,
          items: codeNumbers,
          value: selectedValue,
          height: 65.h,
          onChanged: (String? value) {
            setState(() {
              selectedValue = value;
              if (kDebugMode) {
                print('Selected Value: $selectedValue');
              }
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
            onPressed: _openCodeListDialog, // Use the same function here
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
            enabled: false, // Make the field read-only
          ),
          SizedBox(height: 8.h),
          SendUtils.buildTextField(
            controller: _controllers[ControllerKeys.pricePerKgController] ??
                TextEditingController(),
            hint: 'Price For Each 1 KG',
            enabled: false, // Make the field read-only
          ),
          SizedBox(height: 8.h),
          SendUtils.buildTextField(
            controller: _controllers[ControllerKeys.minimumPriceController] ??
                TextEditingController(),
            hint: 'Minimum Price',
            enabled: false, // Make the field read-only
          ),
          SizedBox(height: 8.h),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              'Exchange Currency: 1 EUR = $_selectedCurrencyAgainstIQD IQD', // Dynamic exchange rate
              style: TextStyle(
                color: Colors.blue,
                fontSize: 22.sp,
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
            optional: true,
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
            optional: true,
          ),
          SizedBox(height: 16.h),
          SendUtils.buildTextField(
            controller: _controllers[ControllerKeys.totalPostCostController] ??
                TextEditingController(),
            hint: 'Total Post Cost',
          ),
          SizedBox(height: 16.h),
          // In the costsCard method, update the checkbox logic
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
                    if (isPostCostPaid) {
                      _controllers[ControllerKeys.totalPostCostPaidController]
                              ?.text =
                          _controllers[ControllerKeys.totalPostCostController]
                                  ?.text ??
                              '0.00';
                    }
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
              // Validate first before doing anything
              if ((_formKey.currentState!.validate())) {
                await _saveRecordWithCode();
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

              // Call the update method
              await _updateRecord();
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

      if (kDebugMode) {
        print('Shipment Details: $shipment');
        print('Sender Info: $sender');
        print('Receiver Info: $receiver');
        print('Cost Summary: $costs');
      }

      final regularFont = await PDFGenerator.loadCairoFont(isBold: false);
      final boldFont = await PDFGenerator.loadCairoFont(isBold: true);

      InvoiceLanguage invoiceLanguage;
      switch (_selectedLanguage?.toLowerCase()) {
        case 'arabic':
          invoiceLanguage = InvoiceLanguage.arabic;
          break;
        case 'kurdish':
          invoiceLanguage = InvoiceLanguage.kurdish;
          break;
        default:
          invoiceLanguage = InvoiceLanguage.english;
          break;
      }

      final invoice = await PDFGenerator.generateInvoice(
        shipment: shipment,
        sender: sender,
        receiver: receiver,
        costs: costs,
        regularFont: regularFont,
        boldFont: boldFont,
        language: invoiceLanguage,
      );

      if (mounted) {
        final result = await showDialog(
          context: context,
          builder: (context) => InvoicePDFPreviewDialog(
            pdfFile: invoice,
            title: 'Invoice Preview',
          ),
        );

        if (mounted && result == 'save') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Invoice saved: ${invoice.path}')),
          );
        }
      }
    } catch (e) {
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

  void generateLabelPdf() async {
    final palletNumber = int.tryParse(
            _controllers[ControllerKeys.palletNumberController]?.text ?? '1') ??
        1;

    // Loop through each pallet and generate a label
    for (int currentLabelIndex = 1;
        currentLabelIndex <= palletNumber;
        currentLabelIndex++) {
      // Debug log
      if (kDebugMode) {
        print('Generating label $currentLabelIndex of $palletNumber');
      }
      var regularFont = await PDFGenerator.loadCairoFont(isBold: false);
      var boldFont = await PDFGenerator.loadCairoFont(isBold: true);

      // Generate the label for the current pallet
      await ShippingLabelGenerator.generateShippingLabel(
        regularFont: regularFont,
        boldFont: boldFont,
        sender: SenderDetails(
          name: _controllers[ControllerKeys.senderNameController]?.text ?? '',
        ),
        receiver: ReceiverDetails(
          name: _controllers[ControllerKeys.receiverNameController]?.text ?? '',
          phone:
              _controllers[ControllerKeys.receiverPhoneController]?.text ?? '',
          city: _selectedCity,
          country: _selectedCountry,
        ),
        shipment: ShipmentInfo(
          date: DateTime.now().toString(),
          time: TimeOfDay.now().toString(),
          itemDetails:
              _controllers[ControllerKeys.goodsDescriptionController]?.text ??
                  '',
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
          final file = await File(
                  '${tempDir.path}/shipping_label_$currentLabelIndex.pdf')
              .create();
          await file.writeAsBytes(pdfData);

          if (mounted) {
            if (kDebugMode) {
              print('PDF saved: ${file.path}');
            } // Debug log

            // Show the preview dialog for the current label
            final result = await showDialog(
              context: context,
              builder: (context) => LabelPDFPreviewDialog(pdfFile: file),
            );

            // Wait for the user to take action (Save or Print)
            if (result == 'save' || result == 'print') {
              if (kDebugMode) {
                print('User action taken for label $currentLabelIndex');
              }
            }
          }
        },
      );
    }
  }
}

// Enums and Models
enum LabelLanguage { arabic, english, kurdish }
