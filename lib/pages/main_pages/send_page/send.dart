import 'dart:convert';
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
import 'package:app/cubits/theme_cubit/theme_cubit_cubit.dart';
import 'package:app/helper/good_description_db_helper.dart';

import 'package:app/helper/sql_helper.dart';
import 'package:app/models/branches_model.dart';
import 'package:app/models/city_model.dart';
import 'package:app/models/country_model.dart';
import 'package:app/models/good_description_model.dart';
import 'package:app/models/send_model.dart';
import 'package:app/pages/main_pages/invoice_pdf/invoice_pdf.dart';
import 'package:app/pages/main_pages/invoice_pdf/pdf_preview_dialog.dart';
import 'package:app/pages/main_pages/label_pdf/label_pdf.dart' hide City;
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
  const SendScreen({
    super.key,
  });
  static String id = 'SendPage';

  @override
  State<SendScreen> createState() => _SendScreenState();
}

class _SendScreenState extends State<SendScreen> {
  List<GoodsDescription> selectedGoodsDescriptions = [];
  List<GoodsDescription> goodsList = [];
  bool _isViewMode = false;
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
    ControllerKeys.notesController: TextEditingController(),
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
  final Map<String, String> _truckCodeMap = {};
  String? _pendingCodeNumber;

  double? _maxCityWeight; // Store the maximum weight of the selected city
  String _selectedAgent = '';
  String? _selectedBranch;
  TextEditingController branchController = TextEditingController();
  String _selectedCountry = '';
  String _selectedCity = '';

  bool areDimensionsEnabled = false;
  bool isInsuranceEnabled = false;
  bool isPostCostPaid = false;

  IdType? _selectedIdType;
  String? _selectedLanguage = '';
  double _boxPrice = 0.0;
  bool _isModifying = false;
  String? _selectedBranchPhoneNo1;
  String? _selectedBranchPhoneNo2;
  // Add this method to fetch currencies
  void _fetchCurrencies() {
    try {
      context.read<CurrencyCubit>().fetchCurrencies();
    } catch (e) {
      _showCustomSnackBar(context, 'Failed to load currencies', isError: true);
    }
  }

  @override
  void initState() {
    super.initState();
    _restoreFormData();
    _loadGoodsDescriptions();
    // Set the initial date
    _controllers[ControllerKeys.dateController]?.text =
        DateFormat('yyyy-MM-dd').format(DateTime.now());

    // Add listeners for automatic calculations
    for (var controller in _controllers.values) {
      controller.addListener(() => SendPageLogic.updateCalculations(
            controllers: _controllers,
            isInsuranceEnabled: isInsuranceEnabled,
            euroRate: _selectedCurrencyAgainstIQD,
            maxCityWeight: _maxCityWeight, // Add this
            context: context, // Add this
          ));
    }
    // Retrieve the selected branch from AuthCubit
    final authCubit = context.read<AuthCubit>();
    _selectedBranch = authCubit.selectedBranch;

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
    // Convert the selected identification photo to a base64 string if it exists
    String? identificationPhotoBase64;
    if (_selectedIdentificationPhoto != null) {
      final bytes = _selectedIdentificationPhoto!.readAsBytesSync();
      identificationPhotoBase64 = base64Encode(bytes);
    }

    final formData = {
      'controllers':
          _controllers.map((key, controller) => MapEntry(key, controller.text)),
      ' notes': _controllers[ControllerKeys.notesController]?.text ?? '',
      'isInsuranceEnabled': isInsuranceEnabled,
      'areDimensionsEnabled': areDimensionsEnabled,
      'selectedCountry': _selectedCountry,
      'selectedCity': _selectedCity,
      'goodsDescription':
          jsonEncode(selectedGoodsDescriptions.map((d) => d.toJson()).toList()),
      'identificationPhoto':
          identificationPhotoBase64, // Save the base64 encoded photo
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

      // Restore goods description
      setState(() {
        _controllers[ControllerKeys.notesController]?.text =
            formData['notes'] ?? '';
        final goodsJson = formData['goodsDescription'] ?? '[]';
        selectedGoodsDescriptions = _parseSelectedDescriptions(goodsJson);
        _controllers[ControllerKeys.goodsDescriptionController]?.text =
            selectedGoodsDescriptions
                .map((desc) =>
                    '${desc.id} - ${desc.descriptionEn} (${desc.quantity}x${desc.weight?.toStringAsFixed(1) ?? '0.0'}kg)')
                .join('\n');
      });

      // Restore the identification photo if it exists
      final identificationPhotoBase64 = formData['identificationPhoto'];
      if (identificationPhotoBase64 != null) {
        final bytes = base64Decode(identificationPhotoBase64);
        final tempDir = Directory.systemTemp;
        final file = File('${tempDir.path}/temp_identification_photo.png');
        file.writeAsBytesSync(bytes);
        setState(() {
          _selectedIdentificationPhoto = file;
        });
      }
    }
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

        _selectedLanguage = selectedBranch.invoiceLanguage;
        _selectedBranchPhoneNo1 =
            selectedBranch.phoneNo1; // Set branch phone numbers
        _selectedBranchPhoneNo2 = selectedBranch.phoneNo2;
      });
      // Set the initial code number from the branch's codeStyle
      setState(() {
        _initialCodeNumber = selectedBranch.codeStyle;
        _controllers[ControllerKeys.codeNumberController]?.text =
            _initialCodeNumber;
      });
    } catch (e) {
      if (mounted) {
        _showCustomSnackBar(context, 'Failed to fetch branch details',
            isError: true);
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

  void _showCustomSnackBar(BuildContext context, String message,
      {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
            ),
            SizedBox(width: 8), // Add some spacing between the icon and text
            Expanded(
              child: Text(
                message,
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? Colors.red : Colors.green,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        behavior: SnackBarBehavior
            .floating, // Makes the SnackBar float above the content
        elevation: 6, // Adds a shadow to the SnackBar
        duration: Duration(seconds: 2), // Adjust the duration as needed
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  Future<void> _saveRecordWithCode() async {
    // Trigger validation manually
    if (!_formKey.currentState!.validate()) {
      _showCustomSnackBar(context, 'Please fix validation errors before saving',
          isError: true);
      return; // Exit the function if validation fails
    }
    try {
      final phoneNumber =
          _controllers[ControllerKeys.senderPhoneController]?.text ?? '';
      if (phoneNumber.length != 11) {
        _showCustomSnackBar(context, 'Phone number must be exactly 11 digits',
            isError: true);
        return; // Exit the function if the 11-digit rule is not met
      }
      final totalWeight = double.tryParse(
              _controllers[ControllerKeys.totalWeightController]?.text ??
                  '0') ??
          0;
      if (_maxCityWeight != null && totalWeight > _maxCityWeight!) {
        _showCustomSnackBar(context,
            'Total weight ($totalWeight kg) exceeds the maximum allowed weight for the selected city ($_maxCityWeight kg)',
            isError: true);
        return;
      }
      final nextCodeNumber = await _getNextCodeNumber(
        _controllers[ControllerKeys.truckNumberController]!.text,
        _selectedBranch!,
      );
      final truckNumber =
          _controllers[ControllerKeys.truckNumberController]!.text;
      final pendingCode = _pendingCodeNumber ?? _initialCodeNumber;
      // Update the Code Number field in the UI
      setState(() {
        _controllers[ControllerKeys.codeNumberController]?.text =
            nextCodeNumber;
      });
      List<GoodsDescription> selectedDescriptions = _parseSelectedDescriptions(
          _controllers[ControllerKeys.goodsDescriptionController]?.text ?? '');
      selectedDescriptions
          .map((desc) => {
                'id': desc.id,
                'descriptionEn': desc.descriptionEn,
                'descriptionAr': desc.descriptionAr,
                'weight': desc.weight,
                'quantity': desc.quantity,
              })
          .toList();

      // Create a new SendRecord
      final record = SendRecord(
        // Shipment Info
        codeNumber: pendingCode,
        date: _controllers[ControllerKeys.dateController]?.text,
        truckNumber: _controllers[ControllerKeys.truckNumberController]?.text,
        notes: _controllers[ControllerKeys.notesController]?.text,
        // codeNumber: nextCodeNumber,
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
        goodsDescription: jsonEncode(
            selectedGoodsDescriptions.map((d) => d.toJson()).toList()),

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
      // After successful save:
      // 1. Update the truck-code map with the saved code
      _truckCodeMap[truckNumber] = pendingCode;
      // 2. Generate the next pending code
      final nextCode = _incrementCodeNumber(pendingCode);
      setState(() {
        _pendingCodeNumber = nextCode;
        _controllers[ControllerKeys.codeNumberController]!.text = nextCode;
      });
      // Refresh the code number after saving
      _onTruckNumberChanged(truckNumber);
      if (!mounted) return;
      _showCustomSnackBar(context, 'Record saved successfully');
      // Your existing logic for saving the record...
    } catch (e) {
      if (mounted) {
        _showCustomSnackBar(context, 'Error saving record', isError: true);
      }
    }
  }

  Future<void> _updateRecord() async {
    // Trigger validation manually
    if (!_formKey.currentState!.validate()) {
      // Show an error message if the form is invalid

      _showCustomSnackBar(
          context, 'Please fix validation errors before updating',
          isError: true);
      return; // Exit the function if validation fails
    }

    // Manually check the 11-digit rule for the phone number

    // Proceed with updating the record if validation passes
    try {
      final phoneNumber =
          _controllers[ControllerKeys.senderPhoneController]?.text ?? '';
      if (phoneNumber.length != 11) {
        _showCustomSnackBar(context, 'Phone number must be exactly 11 digits',
            isError: true);
        return; // Exit the function if the 11-digit rule is not met
      }
      final record = SendRecord(
        id: currentRecordId, // Use the existing record ID
        // Shipment Info
        notes: _controllers[ControllerKeys.notesController]?.text,
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
        receiverName: _controllers[ControllerKeys.receiverNameController]?.text,
        receiverPhone:
            _controllers[ControllerKeys.receiverPhoneController]?.text,
        receiverCountry: _selectedCountry,
        receiverCity: _selectedCity,

        // All other fields as per your model...
        streetName: _controllers[ControllerKeys.streetController]?.text,

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

      // Update the record
      if (mounted) {
        await context.read<SendRecordCubit>().updateSendRecord(record);
        if (!mounted) return;

        _showCustomSnackBar(context, 'Record updated successfully');
      }
    } catch (e) {
      if (mounted) {
        _showCustomSnackBar(context, 'Error updating record', isError: true);
      }
    }
  }

  void _onTruckNumberChanged(String truckNumber) async {
    if (truckNumber.isEmpty) {
      // If the truck number is empty, reset to the initial code number
      setState(() {
        _controllers[ControllerKeys.codeNumberController]!.text =
            _initialCodeNumber;
      });
      return;
    }

    try {
      // Fetch all records for this truck
      final records =
          await context.read<SendRecordCubit>().fetchAllSendRecords();
      final truckRecords =
          records.where((r) => r.truckNumber == truckNumber).toList();

      // Determine the latest code or use initial
      String latestCode = truckRecords.isNotEmpty
          ? truckRecords
              .map((r) => r.codeNumber ?? '')
              .reduce((a, b) => a.compareTo(b) > 0 ? a : b)
          : _initialCodeNumber;

      // Generate next code (only increment if records exist)
      String nextCode = truckRecords.isNotEmpty
          ? _incrementCodeNumber(latestCode)
          : _initialCodeNumber; // Use initial code for new trucks

      setState(() {
        _controllers[ControllerKeys.codeNumberController]!.text = nextCode;
      });
    } catch (e) {
      if (mounted) {
        _showCustomSnackBar(context, 'Error fetching records: $e',
            isError: true);
      }
    }
  }

  void _clearForm() async {
    final truckNumber =
        _controllers[ControllerKeys.truckNumberController]?.text ?? '';
    final currentBranch = _selectedBranch; // Get current branch

    // If no truck or branch, reset to initial code
    if (truckNumber.isEmpty || currentBranch == null) {
      setState(() {
        _controllers[ControllerKeys.codeNumberController]!.text =
            _initialCodeNumber;
      });
      return;
    }

    try {
      // Fetch all records
      final records =
          await context.read<SendRecordCubit>().fetchAllSendRecords();

      // Filter records for THIS truck + THIS branch
      final truckBranchRecords = records
          .where((r) =>
                  r.truckNumber == truckNumber &&
                  r.branchName == currentBranch // Critical: Filter by branch
              )
          .toList();

      // Get latest code for this truck/branch
      String latestCode = truckBranchRecords.isNotEmpty
          ? truckBranchRecords
              .map((r) => r.codeNumber ?? '')
              .reduce((a, b) => a.compareTo(b) > 0 ? a : b)
          : _initialCodeNumber; // Fallback to branch's initial code

      // Generate next code (even if no records)
      String nextCode = _incrementCodeNumber(latestCode);

      setState(() {
        // Clear all fields except truck number and code
        _controllers[ControllerKeys.notesController]?.clear();
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
        _controllers[ControllerKeys.zipCodeController]?.clear();
        _controllers[ControllerKeys.insurancePercentController]?.clear();
        _controllers[ControllerKeys.goodsValueController]?.clear();
        _controllers[ControllerKeys.doorToDoorPriceController]?.clear();
        _controllers[ControllerKeys.pricePerKgController]?.clear();
        _controllers[ControllerKeys.minimumPriceController]?.clear();
        _controllers[ControllerKeys.insuranceAmountController]?.clear();
        _controllers[ControllerKeys.customsCostController]?.clear();
        _controllers[ControllerKeys.boxPackingCostController]?.clear();
        _controllers[ControllerKeys.doorToDoorCostController]?.clear();
        _controllers[ControllerKeys.postSubCostController]?.clear();
        _controllers[ControllerKeys.discountAmountController]?.clear();
        _controllers[ControllerKeys.totalPostCostController]?.clear();
        _controllers[ControllerKeys.totalPostCostPaidController]?.clear();
        _controllers[ControllerKeys.unpaidAmountController]?.clear();
        _controllers[ControllerKeys.totalCostEurController]?.clear();
        _controllers[ControllerKeys.unpaidEurCostController]?.clear();

        // Set the code number to the next increment
        _controllers[ControllerKeys.codeNumberController]!.text = nextCode;

        // Reset other state variables
        _selectedCountry = '';
        _selectedCity = '';
        areDimensionsEnabled = false;
        isInsuranceEnabled = false;
        isPostCostPaid = false;
        _selectedIdType = null;
        _selectedIdentificationPhoto = null;
      });
    } catch (e) {
      if (mounted) {
        _showCustomSnackBar(context, 'Error fetching records: $e',
            isError: true);
      }
    }
  }

  String _incrementCodeNumber(String codeNumber) {
    // If code is empty (no existing records), use initial code
    if (codeNumber.isEmpty) return _initialCodeNumber;

    final parts = codeNumber.split('-');
    if (parts.length != 2) return _initialCodeNumber; // Invalid format

    final prefix = parts[0];
    final numericPart = parts[1];
    final yearPrefix = numericPart.substring(0, 2);
    final sequence = numericPart.substring(2);

    final incremented = (int.tryParse(sequence) ?? 0) + 1;
    final newSequence = incremented.toString().padLeft(sequence.length, '0');

    return '$prefix-$yearPrefix$newSequence'; // BA-2400001 → BA-2400002
  }

  int? currentRecordId;

  void _populateFormWithRecord(SendRecord record, {bool isNewRecord = false}) {
    setState(() {
      _isModifying = !isNewRecord; // Set to false for new records
      currentRecordId = record.id;
      // Always preserve truck number for new records
      _controllers[ControllerKeys.truckNumberController]?.text =
          record.truckNumber ?? '';

      // Preserve code number
      _controllers[ControllerKeys.codeNumberController]?.text =
          record.codeNumber ?? '';
      // Shipment Info
      _controllers[ControllerKeys.dateController]?.text = record.date ?? '';
      //
      _controllers[ControllerKeys.notesController]?.text = record.notes ?? '';
      _controllers[ControllerKeys.boxNumberController]?.text =
          isNewRecord ? '' : record.boxNumber?.toString() ?? '';
      _controllers[ControllerKeys.palletNumberController]?.text =
          isNewRecord ? '' : record.palletNumber?.toString() ?? '';
      _controllers[ControllerKeys.weightController]?.text =
          isNewRecord ? '' : record.realWeightKg?.toString() ?? '';
      _controllers[ControllerKeys.lengthController]?.text =
          isNewRecord ? '' : record.length?.toString() ?? '';
      _controllers[ControllerKeys.widthController]?.text =
          isNewRecord ? '' : record.width?.toString() ?? '';
      _controllers[ControllerKeys.heightController]?.text =
          isNewRecord ? '' : record.height?.toString() ?? '';
      _controllers[ControllerKeys.additionalKGController]?.text =
          isNewRecord ? '' : record.additionalKg?.toString() ?? '';
      _controllers[ControllerKeys.totalWeightController]?.text =
          isNewRecord ? '' : record.totalWeightKg?.toString() ?? '';

      // Sender Info
      _controllers[ControllerKeys.senderNameController]?.text =
          record.senderName ?? '';
      _controllers[ControllerKeys.senderPhoneController]?.text =
          record.senderPhone ?? '';
      _controllers[ControllerKeys.senderIdController]?.text =
          record.senderIdNumber ?? '';
      // Handle goods description
      final goodsJson = record.goodsDescription ?? '';
      final descriptions = _parseSelectedDescriptions(goodsJson);

      // Convert to formatted string
      final formattedDescriptions = descriptions.map((desc) {
        return '${desc.descriptionEn} - ${desc.quantity} x ${desc.weight} kg';
      }).join('\n');

      _controllers[ControllerKeys.goodsDescriptionController]?.text =
          formattedDescriptions;

      // Store full objects for later use
      selectedGoodsDescriptions = descriptions;

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

      _controllers[ControllerKeys.zipCodeController]?.text =
          record.zipCode ?? '';

      // Reset all other fields for new records
      if (isNewRecord) {
        _controllers[ControllerKeys.boxNumberController]?.clear();
        _controllers[ControllerKeys.palletNumberController]?.clear();
        _controllers[ControllerKeys.weightController]?.clear();
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
      }
    });
    if (isNewRecord && record.truckNumber != null) {
      _onTruckNumberChanged(record.truckNumber!);
    }
  }

  String? conditionalValidator(
      bool condition, String? value, String errorMessage) {
    if (condition && (value == null || value.isEmpty)) {
      return errorMessage; // Return the error message if the field is required and empty
    }
    return null; // Return null if the field is valid or not required
  }

  Future<void> _loadGoodsDescriptions() async {
    try {
      final dbHelper = DatabaseHelper();
      final descriptions = await dbHelper.getAllGoodsDescriptions();
      setState(() {
        goodsList = descriptions;
      });
    } catch (e) {
      if (!mounted) return;
      _showCustomSnackBar(context, 'Failed to load goods descriptions',
          isError: true);
    }
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
    return BlocBuilder<SendThemeCubit, bool>(
      builder: (context, isDark) {
        return Theme(
          data: isDark
              ? ThemeData.dark().copyWith(
                  colorScheme: const ColorScheme.dark(
                    surface: Colors.black,
                    primary: Color(0xFF3498DB),
                  ),
                  textTheme: ThemeData.dark().textTheme.copyWith(
                        bodyLarge: TextStyle(fontWeight: FontWeight.bold),
                        bodyMedium: TextStyle(fontWeight: FontWeight.bold),
                        bodySmall: TextStyle(fontWeight: FontWeight.bold),
                        titleLarge: TextStyle(fontWeight: FontWeight.bold),
                        titleMedium: TextStyle(fontWeight: FontWeight.bold),
                        titleSmall: TextStyle(fontWeight: FontWeight.bold),
                        labelLarge: TextStyle(fontWeight: FontWeight.bold),
                        labelMedium: TextStyle(fontWeight: FontWeight.bold),
                        labelSmall: TextStyle(fontWeight: FontWeight.bold),
                        headlineLarge: TextStyle(fontWeight: FontWeight.bold),
                        headlineMedium: TextStyle(fontWeight: FontWeight.bold),
                        headlineSmall: TextStyle(fontWeight: FontWeight.bold),
                        displayLarge: TextStyle(fontWeight: FontWeight.bold),
                        displayMedium: TextStyle(fontWeight: FontWeight.bold),
                        displaySmall: TextStyle(fontWeight: FontWeight.bold),
                      ),
                  cardTheme: CardTheme(
                    color: Colors.grey[850],
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  cardColor: Colors.black,
                )
              : ThemeData.light().copyWith(
                  colorScheme: const ColorScheme.light(
                    primary: Color(0xFF3498DB),
                    surface: Colors.white,
                  ),
                  textTheme: ThemeData.light().textTheme.copyWith(
                        bodyLarge: TextStyle(fontWeight: FontWeight.bold),
                        bodyMedium: TextStyle(fontWeight: FontWeight.bold),
                        bodySmall: TextStyle(fontWeight: FontWeight.bold),
                        titleLarge: TextStyle(fontWeight: FontWeight.bold),
                        titleMedium: TextStyle(fontWeight: FontWeight.bold),
                        titleSmall: TextStyle(fontWeight: FontWeight.bold),
                        labelLarge: TextStyle(fontWeight: FontWeight.bold),
                        labelMedium: TextStyle(fontWeight: FontWeight.bold),
                        labelSmall: TextStyle(fontWeight: FontWeight.bold),
                        headlineLarge: TextStyle(fontWeight: FontWeight.bold),
                        headlineMedium: TextStyle(fontWeight: FontWeight.bold),
                        headlineSmall: TextStyle(fontWeight: FontWeight.bold),
                        displayLarge: TextStyle(fontWeight: FontWeight.bold),
                        displayMedium: TextStyle(fontWeight: FontWeight.bold),
                        displaySmall: TextStyle(fontWeight: FontWeight.bold),
                      ),
                ),
          child: Builder(
            builder: (BuildContext context) {
              return Shortcuts(
                shortcuts: {
                  // Define the shortcut (Ctrl + F)
                  LogicalKeySet(
                          LogicalKeyboardKey.control, LogicalKeyboardKey.keyF):
                      const ActivateIntent(),
                },
                child: Actions(
                  actions: {
                    // Map the ActivateIntent to the openDialog function
                    ActivateIntent: CallbackAction<ActivateIntent>(
                      onInvoke: (ActivateIntent intent) {
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
                          _showCustomSnackBar(context, state.message,
                              isError: true);
                        } else if (state is SendRecordLoaded) {
                          _showCustomSnackBar(
                              context, 'Record saved successfully');
                        }
                      },
                      child: SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: Container(
                          color: Colors.grey,
                          child: Form(
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            key: _formKey,
                            child: Column(
                              children: [
                                IntrinsicHeight(
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child:
                                            _buildCard(child: buildMainCard()),
                                      ),
                                      Expanded(
                                        child: _buildCard(child: agentCard()),
                                      ),
                                      Expanded(
                                        child: _buildCard(
                                            child: doorToDoorPriceCard()),
                                      ),
                                    ],
                                  ),
                                ),
                                IntrinsicHeight(
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // First Column
                                      Flexible(
                                        child: Column(
                                          children: [
                                            _buildCard(
                                                child: buildSenderCard()),
                                            Expanded(
                                              child: _buildCard(
                                                  child: buildItemsCard()),
                                            ),
                                          ],
                                        ),
                                      ),

                                      Flexible(
                                        child: Column(
                                          children: [
                                            _buildCard(child: receiverCard()),
                                            _buildCard(child: ifPostCard()),
                                            Expanded(
                                              child: _buildCard(
                                                  child: insuranceInfoCard()),
                                            ),
                                          ],
                                        ),
                                      ),

                                      Flexible(
                                        child: Column(
                                          children: [
                                            Expanded(
                                              child: _buildCard(
                                                  child: costsCard()),
                                            ),
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
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget buildMainCard() {
    return SendUtils.buildCard(
      context: context,
      backgroundColor: Colors.blue,
      child: Column(
        spacing: 8.h,
        children: [
          SendUtils.buildInputRow(
            context: context,
            icon: Icon(
              Icons.calendar_today_outlined,
              size: 24.sp,
              color: Colors.white,
            ),
            child: SendUtils.buildTextField(
              context: context,
              controller: _controllers[ControllerKeys.dateController] ??
                  TextEditingController(),
              hint: 'Date',
              enabled: false || !_isViewMode,
            ),
          ),
          SendUtils.buildInputRow(
            context: context,
            icon: Icon(
              Icons.local_shipping_outlined,
              size: 24.sp,
              color: Colors.white,
            ),
            child: SendUtils.buildTextField(
              controller: _controllers[ControllerKeys.truckNumberController] ??
                  TextEditingController(),
              onChanged: (value) => _onTruckNumberChanged(value),
              hint: 'Truck Number',
              context: context,
              enabled: !_isViewMode,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Truck Number is required';
                }
                return null;
              },
            ),
          ),
          SendUtils.buildInputRow(
            context: context,
            icon: Icon(
              Icons.code,
              size: 24.sp,
              color: Colors.white,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(left: 48.0.w),
                    child: SendUtils.buildTextField(
                      padding: 0.w,
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
                ),
                IconButton(
                  icon: Icon(
                    Icons.delete,
                    size: 30.sp,
                    color: Colors.white,
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
      _showCustomSnackBar(context, 'Please enter a valid code number',
          isError: true);
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
        if (!mounted) return;
        _showCustomSnackBar(context, 'Record not found', isError: true);
        return;
      }

      // Show confirmation dialog
      final shouldClear = await _showDeleteConfirmationDialog();
      if (!shouldClear) {
        return; // User canceled the operation
      }

      // Use the new method to clear all fields except codeNumber
      if (!mounted) return;
      await context
          .read<SendRecordCubit>()
          .databaseHelper
          .updateSendRecordFields(
            recordToUpdate.id!, // Pass the record ID
            codeNumber, // Pass the codeNumber to ensure it's not cleared
          );

      if (!mounted) return;
      _showCustomSnackBar(
          context, 'Record cleared successfully (except Code Number)');

      // Clear the form after successful deletion
      _clearForm();
    } catch (e) {
      _showCustomSnackBar(context, 'Error clearing record', isError: true);
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

  List<GoodsDescription> _parseSelectedDescriptions(String descriptionsJson) {
    if (descriptionsJson.isEmpty) return [];

    try {
      final List<dynamic> jsonList = jsonDecode(descriptionsJson);
      return jsonList
          .map((item) => GoodsDescription(
                id: item['id'],
                descriptionEn: item['descriptionEn'],
                descriptionAr: item['descriptionAr'],
                weight: item['weight']?.toDouble() ?? 0.0,
                quantity: item['quantity']?.toInt() ?? 1,
              ))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Widget buildSenderCard() {
    return BlocBuilder<SendThemeCubit, bool>(
      builder: (context, isDark) {
        return SendUtils.buildCard(
          context: context,
          title: 'Sender',
          child: Column(
            spacing: 8.h,
            children: [
              SendUtils.buildInputRow(
                context: context,
                icon: Icon(
                  Icons.person_outline,
                  size: 24.sp,
                ),
                child: SendUtils.buildTextField(
                  context: context,
                  controller:
                      _controllers[ControllerKeys.senderNameController] ??
                          TextEditingController(),
                  hint: 'Sender Name',
                  enabled: !_isViewMode,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Sender Name is required';
                    }
                    return null;
                  },
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [UpperCaseTextFormatter()],
                  height: 50, // Consistent height
                  padding: 48, // Consistent padding
                ),
              ),
              SendUtils.buildInputRow(
                context: context,
                icon: Icon(
                  Icons.phone_outlined,
                  size: 24.sp,
                ),
                child: SendUtils.buildTextField(
                  context: context,
                  controller:
                      _controllers[ControllerKeys.senderPhoneController] ??
                          TextEditingController(),
                  hint: 'Sender Phone',
                  keyboardType: TextInputType.phone,
                  enabled: !_isViewMode,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Phone number is required';
                    }
                    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                      return 'Phone number must contain only numbers';
                    }
                    return null;
                  },
                  height: 50, // Consistent height
                  padding: 48, // Consistent padding
                ),
              ),
              SendUtils.buildInputRow(
                context: context,
                icon: SizedBox(
                  height: 24.h,
                  width: 24.w,
                  child: IdTypeSelector(
                    iconColor: isDark ? Colors.white : Colors.grey[700],
                    onTypeSelected: (type) {
                      setState(() {
                        _selectedIdType = type;
                      });
                    },
                    currentType: _selectedIdType,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                            left: 38.0.w), // Keep this for alignment
                        child: SendUtils.buildTextField(
                          context: context,
                          controller:
                              _controllers[ControllerKeys.senderIdController]!,
                          hint: 'Sender ID',
                          keyboardType: TextInputType.number,
                          enabled: !_isViewMode,
                          validator: (value) {
                            if (!RegExp(r'^[0-9]+$').hasMatch(value ?? '')) {
                              return 'ID number must contain only numbers';
                            }
                            return null;
                          },
                          height: 50, // Consistent height
                          padding: 0, // Adjust padding to fit within the Row
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
                                    _showCustomSnackBar(
                                        context, 'No file selected',
                                        isError: true);
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
                                      padding: EdgeInsets.all(8.0.r),
                                      constraints: BoxConstraints(
                                        maxWidth: 500.0.w,
                                        maxHeight: 600.0.h,
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'ID Photo',
                                            style: TextStyle(
                                              fontSize: 20.sp,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(height: 16.h),
                                          Flexible(
                                            child: Image.file(
                                              _selectedIdentificationPhoto!,
                                              fit: BoxFit.contain,
                                            ),
                                          ),
                                          SizedBox(height: 16.h),
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
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    horizontal: 24,
                                                    vertical: 12,
                                                  ),
                                                ),
                                                child:
                                                    const Text('Delete Photo'),
                                              ),
                                              ElevatedButton(
                                                onPressed: () {
                                                  Navigator.of(context).pop();
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  padding: const EdgeInsets
                                                      .symmetric(
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
                            color: isDark ? Colors.grey[800] : Colors.white,
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Container(
                              width:
                                  70.w, // Keep fixed width for the icon button
                              height: 40.h,
                              decoration: BoxDecoration(
                                color: _selectedIdentificationPhoto == null
                                    ? Colors.white
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: _selectedIdentificationPhoto == null
                                  ? Icon(
                                      Icons.camera_alt_outlined,
                                      color:
                                          isDark ? Colors.black : Colors.black,
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
              ),
              SendUtils.buildInputRow(
                context: context,
                icon: Icon(
                  Icons.description_outlined,
                  size: 24.sp,
                ),
                child: InkWell(
                  onTap: () {
                    if (!_isViewMode) {
                      showDialog(
                        context: context,
                        builder: (context) => GoodsDescriptionPopup(
                          controller: _controllers[
                              ControllerKeys.goodsDescriptionController]!,
                          onDescriptionsSelected:
                              (List<GoodsDescription> newSelected) {
                            setState(() {
                              selectedGoodsDescriptions = newSelected;
                              _controllers[ControllerKeys
                                          .goodsDescriptionController]
                                      ?.text =
                                  newSelected
                                      .map((desc) =>
                                          '${desc.quantity} - ${desc.descriptionEn} (${desc.quantity}x${desc.weight?.toStringAsFixed(1) ?? '0.0'}kg)')
                                      .join('\n');
                            });
                          },
                          dbHelper: DatabaseHelper(),
                          initialSelectedDescriptions:
                              selectedGoodsDescriptions, // Pass the current list with updated values
                          hasExistingValue:
                              selectedGoodsDescriptions.isNotEmpty,
                        ),
                      );
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 48.w),
                    child: TextFormField(
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poppins',
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      controller: _controllers[
                              ControllerKeys.goodsDescriptionController] ??
                          TextEditingController(),
                      enabled: false,
                      decoration: InputDecoration(
                        hintText: 'Goods Description',
                        hintStyle: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                          color: isDark ? Colors.white70 : Colors.grey[600],
                        ),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        filled: true,
                        fillColor: isDark ? Colors.grey[800] : Colors.grey[200],
                      ),
                      maxLines: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget buildItemsCard() {
    return SendUtils.buildCard(
      context: context,
      title: 'Items',
      child: Column(
        children: [
          SendUtils.buildInputRow(
            context: context,
            icon: Icon(
              Icons.format_list_numbered,
              size: 24.sp,
            ),
            child: Row(
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
                        maxCityWeight: _maxCityWeight, // Add this
                        context: context,
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
                    enabled: !_isViewMode,
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: SendUtils.buildTextField(
                    context: context,
                    controller:
                        _controllers[ControllerKeys.palletNumberController] ??
                            TextEditingController(),
                    hint: 'Pallet No.',
                    optional: true, enabled: !_isViewMode,
                    // Pallet field is optional, so no validator
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 8.h),
          SendUtils.buildInputRow(
            context: context,
            icon: Icon(Icons.scale_sharp, size: 24.sp),
            child: SendUtils.buildTextField(
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
              enabled: !_isViewMode,
            ),
          ),
          SizedBox(height: 8.h),
          SendUtils.buildInputRow(
            context: context,
            label: 'Weight (KG)',
            child: Row(
              children: [
                Expanded(
                  child: SendUtils.buildTextField(
                    padding: 8.w,
                    controller: _controllers[ControllerKeys.lengthController] ??
                        TextEditingController(),
                    hint: 'L',
                    enabled: areDimensionsEnabled && !_isViewMode,
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
                // SizedBox(width: 8.w),
                Expanded(
                  child: SendUtils.buildTextField(
                    padding: 8.w,
                    controller: _controllers[ControllerKeys.widthController] ??
                        TextEditingController(),
                    hint: 'W',
                    enabled: areDimensionsEnabled && !_isViewMode,
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
                // SizedBox(width: 8.w),
                Expanded(
                  child: SendUtils.buildTextField(
                    padding: 8.w,
                    controller: _controllers[ControllerKeys.heightController] ??
                        TextEditingController(),
                    hint: 'H',
                    enabled: areDimensionsEnabled && !_isViewMode,
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
          ),
          SizedBox(height: 8.h),
          SendUtils.buildInputRow(
            context: context,
            label: '/',
            child: SendUtils.buildDropdownField(
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
              enabled: !_isViewMode,
            ),
          ),
          SizedBox(height: 8.h),
          SendUtils.buildInputRow(
            context: context,
            icon: Icon(Icons.scale_sharp, size: 24.sp),
            child: SendUtils.buildTextField(
              context: context,
              controller: _controllers[ControllerKeys.resultController] ??
                  TextEditingController(),
              hint: 'Result (L*H*W / Select Amount)',
              enabled: false, // Make the field read-only
            ),
          ),
          SizedBox(height: 8.h),
          SendUtils.buildInputRow(
            context: context,
            icon: Icon(Icons.add_box, size: 24.sp),
            child: SendUtils.buildTextField(
              context: context,
              controller: _controllers[ControllerKeys.additionalKGController] ??
                  TextEditingController(),
              hint: 'Additional KG',
              enabled: areDimensionsEnabled && !_isViewMode,
              optional: true,
              onChanged: (value) {
                _calculateResult(); // Recalculate result when additional weight changes
              },
            ),
          ),
          SizedBox(height: 8.h),
          SendUtils.buildInputRow(
            context: context,
            icon: Icon(Icons.sort_sharp, size: 24.sp),
            child: SendUtils.buildTextField(
              context: context,
              controller: _controllers[ControllerKeys.totalWeightController] ??
                  TextEditingController(),
              hint: 'Total Weight KG',
              validator: (value) {
                final totalWeight = double.tryParse(
                        _controllers[ControllerKeys.totalWeightController]
                                ?.text ??
                            '0') ??
                    0;
                if (_maxCityWeight != null && totalWeight > _maxCityWeight!) {
                  _showCustomSnackBar(context,
                      'Total weight ($totalWeight kg) exceeds the maximum allowed weight for the selected city ($_maxCityWeight kg)',
                      isError: true);
                  return;
                }
                return null;
              },
              enabled: false, // Make the field read-only
            ),
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
    return BlocBuilder<SendThemeCubit, bool>(
      builder: (context, isDark) {
        return SendUtils.buildCard(
          context: context,
          title: 'Insurance Percent % Of Value',
          child: Column(
            spacing: 10.h,
            children: [
              SendUtils.buildInputRow(
                context: context,
                icon: Icon(Icons.percent, size: 24.sp),
                child: Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(left: 36.0.w),
                        child: SendUtils.buildTextField(
                          padding: 8.w,
                          controller: _controllers[
                                  ControllerKeys.insurancePercentController] ??
                              TextEditingController(),
                          hint: 'Insurance Amount',
                          enabled: isInsuranceEnabled &&
                              !_isViewMode, // Enable/disable based on checkbox
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
                    ),
                    Checkbox(
                      value: isInsuranceEnabled,
                      onChanged: (value) {
                        setState(() {
                          isInsuranceEnabled = value ?? true;
                          // Clear the field when checkbox is unchecked
                          if (!isInsuranceEnabled) {
                            _controllers[
                                    ControllerKeys.insurancePercentController]
                                ?.clear();
                          }
                        });
                      },
                    ),
                  ],
                ),
              ),

              SendUtils.buildInputRow(
                context: context,
                icon: Icon(Icons.attach_money, size: 24.sp),
                child: SendUtils.buildTextField(
                  context: context,

                  hint: 'Goods Value',
                  enabled: true && !_isViewMode,
                  controller:
                      _controllers[ControllerKeys.goodsValueController] ??
                          TextEditingController(),
                  optional: true, // This field is optional
                ),
              ),

              // Replace the static container with a TextField for notes
              SendUtils.buildInputRow(
                context: context,
                icon: Icon(Icons.note_add_sharp, size: 30.sp),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 48.w),
                  child: TextFormField(
                    enabled: !_isViewMode,
                    style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold),

                    controller: _controllers[ControllerKeys.notesController],

                    decoration: InputDecoration(
                      hintText: 'Write notes here...',
                      hintStyle: TextStyle(
                        color: isDark ? Colors.white70 : Colors.grey[600],
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: isDark ? Colors.grey[800] : Colors.grey[200],
                    ),
                    maxLines: 4, // Allow multiple lines for notes
                  ),
                ),
              ),
            ],
          ),
        );
      },
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
          circularFlag: '',
          squareFlag: '',
          maxWeightKG: 0,
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
      context: context,
      title: 'Send Via Post',
      child: Column(
        spacing: 8.h,
        children: [
          SendUtils.buildInputRow(
            context: context,
            icon: Icon(
              Icons.home_outlined,
              size: 24.sp,
            ),
            child: SendUtils.buildTextField(
              context: context,
              hint: 'Street Name & No.',
              controller: _controllers[ControllerKeys.streetController] ??
                  TextEditingController(),
              enabled: isPostCity && !_isViewMode,
              validator: (value) {
                return conditionalValidator(
                  isPostCity, // Condition: Is post city selected?
                  value, // Field value
                  'Street Name & No. is required', // Error message
                );
              },
              textCapitalization: isPostCity
                  ? TextCapitalization.characters
                  : TextCapitalization.none, // Enforce uppercase only for POST
              inputFormatters: isPostCity
                  ? [
                      UpperCaseTextFormatter(), // Custom formatter to enforce uppercase
                    ]
                  : [],
            ),
          ),
          SendUtils.buildInputRow(
            context: context,
            icon: Icon(
              Icons.markunread_mailbox,
              size: 24.sp,
            ),
            child: SendUtils.buildTextField(
              context: context,
              hint: 'ZIP Code',
              validator: (value) {
                return conditionalValidator(
                  isPostCity, // Condition: Is post city selected?
                  value, // Field value
                  'ZIP Code is required', // Error message
                );
              },
              controller: _controllers[ControllerKeys.zipCodeController] ??
                  TextEditingController(),
              enabled: isPostCity && !_isViewMode, // Disable if not a post city
            ),
          ),
          _buildAdressDropdown(),
        ],
      ),
    );
  }

  Widget receiverCard() {
    return SendUtils.buildCard(
      context: context,
      title: 'Receiver',
      child: Column(
        spacing: 8.h,
        children: [
          SendUtils.buildInputRow(
            context: context,
            icon: Icon(
              Icons.person_outline,
              size: 24.sp,
            ),
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
              textCapitalization:
                  TextCapitalization.characters, // Enforce uppercase
              inputFormatters: [
                UpperCaseTextFormatter(), // Custom formatter to enforce uppercase
              ],
              enabled: !_isViewMode,
            ),
          ),
          SendUtils.buildInputRow(
            context: context,
            icon: Icon(
              Icons.phone_outlined,
              size: 24.sp,
            ),
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
              enabled: !_isViewMode,
            ),
          ),
          _buildCountryDropdown(),
          _buildCityDropdown(),
        ],
      ),
    );
  }

  Widget agentCard() {
    return SendUtils.buildCard(
      context: context,
      backgroundColor: Colors.blue,
      child: Column(
        spacing: 8.h,
        children: [
          SendUtils.buildInputRow(
              context: context,
              icon: Icon(Icons.person, size: 24.sp),
              child: _buildAgentDropdown()),
          SendUtils.buildInputRow(
              context: context,
              icon: Icon(Icons.location_on, size: 24.sp),
              child: _buildBranchDropdown()),
          SendUtils.buildInputRow(
            context: context,
            icon: Icon(Icons.code, size: 24.sp),
            child: _buildCodeListDropdown(
              hint: 'Code List Items/ press ctrl + F to search',
              context: context, // Add actual items as needed
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountryDropdown() {
    return BlocConsumer<CountryCubit, CountryState>(
      listener: (context, state) {
        if (state is CountryError) {
          _showCustomSnackBar(context, state.message, isError: true);
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
            context: context,
            icon: Icon(
              Icons.flag,
              size: 24.sp,
            ),
            child: SendUtils.buildDropdownField(
              context: context,
              enabled: !_isViewMode,
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

  void _openCodeListDialog() async {
    final result = await showDialog(
      context: context,
      builder: (context) => RecordsTableDialog(
        onRecordSelected: (record) {}, // Keep empty if not needed
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      final action = result['action'];
      final record = result['record'] as SendRecord;

      if (action == 'edit') {
        // Populate form in edit mode
        setState(() {
          _isViewMode = false;
          _populateFormWithRecord(record);
        });
      } else if (action == 'view') {
        // Populate form in view mode
        setState(() {
          _isViewMode = true;
          _populateFormWithRecord(record);
        });
      } else if (action == 'new') {
        // Populate form with sender/receiver info and reset other fields
        setState(() {
          _isViewMode = false;
          _populateFormWithRecord(record, isNewRecord: true);
        });
      }
    }
  }

  Widget _buildCityDropdown() {
    return BlocConsumer<CityCubit, CityState>(
      listener: (context, state) {
        if (state is CityErrorState) {
          _showCustomSnackBar(context, state.errorMessage, isError: true);
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
          context: context,
          icon: Icon(
            Icons.location_on,
            size: 24.sp,
          ),
          child: SendUtils.buildDropdownField(
            context: context,
            enabled: !_isViewMode,
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
                        circularFlag: '',
                        squareFlag: '',
                        maxWeightKG: 0),
                  );

                  // Update the fields with the city's prices
                  _controllers[ControllerKeys.doorToDoorPriceController]?.text =
                      city.doorToDoorPrice.toString();
                  _controllers[ControllerKeys.pricePerKgController]?.text =
                      city.priceKg.toString();
                  _controllers[ControllerKeys.minimumPriceController]?.text =
                      city.minimumPrice.toString();
                  _maxCityWeight = city.maxWeightKG;
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
                    euroRate: _selectedCurrencyAgainstIQD,
                    maxCityWeight: _maxCityWeight, // Add this
                    context: context,
                  );

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

  Widget _buildAdressDropdown() {
    return BlocConsumer<CityCubit, CityState>(
      listener: (context, state) {
        if (state is CityErrorState) {
          _showCustomSnackBar(context, state.errorMessage, isError: true);
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
          context: context,
          icon: Icon(
            Icons.location_on,
            size: 24.sp,
          ),
          child: SendUtils.buildDropdownField(
            context: context,
            enabled: !_isViewMode,
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
                        circularFlag: '',
                        squareFlag: '',
                        maxWeightKG: 0),
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
                    euroRate: _selectedCurrencyAgainstIQD,
                    maxCityWeight: _maxCityWeight, // Add this
                    context: context,
                  );

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
          circularFlag: '',
          squareFlag: '',
          maxWeightKG: 0,
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
          _showCustomSnackBar(context, state.errorMessage, isError: true);
        }
      },
      builder: (context, state) {
        if (state is BranchLoadedState) {
          // Use the non-editable text field for the branch
          return SendUtils.buildTextField(
            context: context,
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
      context: context,
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
        }

        if (selectedValue != null && !codeNumbers.contains(selectedValue)) {
          selectedValue = null; // Reset the value if it's not in the list
        }

        return SendUtils.buildDropdownField(
          context: context,
          enabled: !_isViewMode,
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
      context: context,
      backgroundColor: Colors.blue,
      child: Column(
        spacing: 8.h,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SendUtils.buildInputRow(
            context: context,
            label: 'Door To Door Price',
            child: SendUtils.buildTextField(
              context: context,
              controller:
                  _controllers[ControllerKeys.doorToDoorPriceController] ??
                      TextEditingController(),
              hint: 'Door To Door Price',
              enabled: false, // Make the field read-only
            ),
          ),
          SendUtils.buildInputRow(
            context: context,
            label: 'Price For Each 1 KG',
            child: SendUtils.buildTextField(
              context: context,
              controller: _controllers[ControllerKeys.pricePerKgController] ??
                  TextEditingController(),
              hint: 'Price For Each 1 KG',
              enabled: false, // Make the field read-only
            ),
          ),
          SendUtils.buildInputRow(
            context: context,
            label: 'Minimum Price',
            child: Padding(
              padding: EdgeInsets.only(left: 32.0.w),
              child: SendUtils.buildTextField(
                context: context,
                controller:
                    _controllers[ControllerKeys.minimumPriceController] ??
                        TextEditingController(),
                hint: 'Minimum Price',
                enabled: false, // Make the field read-only
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget costsCard() {
    return BlocBuilder<SendThemeCubit, bool>(
      builder: (context, isDark) {
        return SendUtils.buildCard(
          context: context,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 48.w),
            child: Column(
              spacing: 10.h, // Consistent spacing with other cards
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Exchange Currency Text (not a field, so keep as is but update style)
                Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: 16.w), // Consistent padding
                  child: Text(
                    'Exchange Currency: 1 EUR = $_selectedCurrencyAgainstIQD IQD',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                      color: Colors.blue,
                    ),
                  ),
                ),

                // Insurance Amount (without label)
                SendUtils.buildTextField(
                  context: context,
                  controller:
                      _controllers[ControllerKeys.insuranceAmountController] ??
                          TextEditingController(),
                  hint: 'Insurance Amount',
                  enabled: true,
                  height: 50,
                  padding: 48,
                ),

                // Customs Cost (without label)
                SendUtils.buildTextField(
                  context: context,
                  controller:
                      _controllers[ControllerKeys.customsCostController] ??
                          TextEditingController(),
                  hint: 'Customs Cost',
                  optional: true,
                  enabled: !_isViewMode,
                  height: 50,
                  padding: 48,
                ),

                // Box Packing Cost (without label)
                SendUtils.buildTextField(
                  context: context,
                  controller:
                      _controllers[ControllerKeys.boxPackingCostController] ??
                          TextEditingController(),
                  hint: 'Box Packing Cost',
                  enabled: true,
                  height: 50,
                  padding: 48,
                ),

                // Door To Door Cost (without label)
                SendUtils.buildTextField(
                  context: context,
                  controller:
                      _controllers[ControllerKeys.doorToDoorCostController] ??
                          TextEditingController(),
                  hint: 'Door To Door Cost',
                  enabled: true,
                  height: 50,
                  padding: 48,
                ),

                // Post Sub Cost (without label)
                SendUtils.buildTextField(
                  context: context,
                  controller:
                      _controllers[ControllerKeys.postSubCostController] ??
                          TextEditingController(),
                  hint: 'Post Sub Cost',
                  enabled: true,
                  height: 50,
                  padding: 48,
                ),

                // Discount Amount (without label)
                SendUtils.buildTextField(
                  context: context,
                  controller:
                      _controllers[ControllerKeys.discountAmountController] ??
                          TextEditingController(),
                  hint: 'Discount Amount',
                  optional: true,
                  enabled: !_isViewMode,
                  height: 50,
                  padding: 48,
                ),

                // Total Post Cost (without label)
                SendUtils.buildTextField(
                  context: context,
                  controller:
                      _controllers[ControllerKeys.totalPostCostController] ??
                          TextEditingController(),
                  hint: 'Total Post Cost',
                  enabled: true,
                  height: 50,
                  padding: 48,
                ),

                // Total Post Cost Paid with Checkbox (without label, adjust layout)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      flex:
                          1, // Ensure the text field fills the available width
                      child: Padding(
                        padding: EdgeInsets.only(left: 48.0.w),
                        child: SendUtils.buildTextField(
                          context: context,
                          controller: _controllers[
                                  ControllerKeys.totalPostCostPaidController] ??
                              TextEditingController(),
                          hint: 'Total Post Cost Paid',
                          enabled: !_isViewMode,
                          height: 50,
                          padding: 0,
                        ),
                      ),
                    ),
                    Checkbox(
                      value: isPostCostPaid,
                      onChanged: (value) {
                        setState(() {
                          isPostCostPaid = value ?? false;
                          final totalPostCostController = _controllers[
                              ControllerKeys.totalPostCostController];
                          final totalPostCostPaidController = _controllers[
                              ControllerKeys.totalPostCostPaidController];

                          if (totalPostCostController != null &&
                              totalPostCostPaidController != null) {
                            if (isPostCostPaid) {
                              // When checked, set to total post cost
                              totalPostCostPaidController.text =
                                  totalPostCostController.text;
                            } else {
                              // When unchecked, set to zero
                              totalPostCostPaidController.text = '0.00';
                            }

                            // Trigger recalculation of unpaid amounts
                            SendPageLogic.updateCalculations(
                              controllers: _controllers,
                              maxCityWeight: _maxCityWeight, // Add this
                              context: context,
                              isInsuranceEnabled: isInsuranceEnabled,
                              euroRate: _selectedCurrencyAgainstIQD,
                            );
                          }
                        });
                      },
                    ),
                  ],
                ),

                // Unpaid Amount (without label)
                SendUtils.buildTextField(
                  context: context,
                  controller:
                      _controllers[ControllerKeys.unpaidAmountController] ??
                          TextEditingController(),
                  hint: 'Unpaid Amount',
                  enabled: true,
                  height: 50,
                  padding: 48,
                ),

                // Total Cost By Europe Currency (without label)
                SendUtils.buildTextField(
                  context: context,
                  controller:
                      _controllers[ControllerKeys.totalCostEurController] ??
                          TextEditingController(),
                  hint: 'Total Cost By Europe Currency',
                  enabled: true,
                  height: 50,
                  padding: 48,
                ),

                // Unpaid and Will Paid In Europe (without label)
                SendUtils.buildTextField(
                  context: context,
                  controller:
                      _controllers[ControllerKeys.unpaidEurCostController] ??
                          TextEditingController(),
                  hint: 'Unpaid and Will Paid In Europe',
                  enabled: true,
                  height: 50,
                  padding: 48,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget actionButton() {
    return SendUtils.buildCard(
      context: context,
      title: 'Actions',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionButton(
            'Add Code',
            Colors.blue,
            () async {
              if (_formKey.currentState!.validate()) {
                await _saveRecordWithCode();
              } else {
                _showCustomSnackBar(
                    context, 'Please fix validation errors before saving',
                    isError: true);
              }
            },
            isEnabled: !_isModifying && !_isViewMode, // Disable when modifying
          ),
          _buildActionButton(
            'Update Code',
            Colors.pink,
            () async {
              if (currentRecordId == null) {
                _showCustomSnackBar(context, 'Please select a record to update',
                    isError: true);
                return;
              }
              await _updateRecord();
            },
            isEnabled: _isModifying && !_isViewMode, // Disable when adding
          ),

          // Example usage in a widget
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

  Widget _buildActionButton(
    String text,
    Color color,
    VoidCallback onPressed, {
    bool isEnabled = true,
  }) {
    return CustomButton(
      color: color,
      text: text,
      function: isEnabled ? onPressed : null, // Disable button if not enabled
    );
  }

  Widget clearButton() {
    return SendUtils.buildCard(
      context: context,
      title: 'Actions',
      child: CustomButton(
        color: Colors.red,
        text: 'Clear',
        function: _clearForm,
        width: 400.w,
      ),
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
        phoneNo1: _selectedBranchPhoneNo1 ?? '', // Add branch phone numbers
        phoneNo2: _selectedBranchPhoneNo2 ?? '',
      );

      final costs = CostSummary(
        shippingCost:
            _controllers[ControllerKeys.doorToDoorCostController]?.text ?? '',
        emptyBoxCost:
            _controllers[ControllerKeys.boxPackingCostController]?.text ?? '',
        customsAdmin:
            _controllers[ControllerKeys.customsCostController]?.text ?? '',
        deliveryCost:
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
        amountDueEur:
            _controllers[ControllerKeys.unpaidEurCostController]?.text ?? '',
        isInsuranceEnabled: isInsuranceEnabled,
      );

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
        isPostCity: _isPostCitySelected(),
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
          _showCustomSnackBar(context, 'Invoice saved: ${invoice.path}');
        }
      }
    } catch (e) {
      if (mounted) {
        _showCustomSnackBar(context, 'Error generating invoice: $e',
            isError: true);
      }
    }
  }
 void generateLabelPdf() async {
    final palletNumber = int.tryParse(
            _controllers[ControllerKeys.palletNumberController]?.text ?? '1') ??
        1;

    // Fetch the selected city from CityCubit based on _selectedCity
    final cityState = context.read<CityCubit>().state;
    City? selectedCity;
    if (cityState is CityLoadedState) {
      selectedCity = cityState.cities.firstWhere(
        (city) => city.cityName == _selectedCity,
        orElse: () => City(
          id: null,
          cityName: _selectedCity,
          country: _selectedCountry,
          hasAgent: false,
          isPost: false,
          doorToDoorPrice: 0,
          priceKg: 0,
          minimumPrice: 0,
          boxPrice: 0,
          circularFlag: 'assets/icons/Subtraction 1.png', // Fallback flag
          squareFlag: 'assets/icons/Subtraction 1.png',
          maxWeightKG: 0,
        ),
      );
    } else {
      selectedCity = City(
        id: null,
        cityName: _selectedCity,
        country: _selectedCountry,
        hasAgent: false,
        isPost: false,
        doorToDoorPrice: 0,
        priceKg: 0,
        minimumPrice: 0,
        boxPrice: 0,
        circularFlag: 'assets/icons/Subtraction 1.png', // Fallback flag
        squareFlag: 'assets/icons/Subtraction 1.png',
        maxWeightKG: 0,
      );
    }

    // Loop through each pallet and generate a label
    for (int currentLabelIndex = 1;
        currentLabelIndex <= palletNumber;
        currentLabelIndex++) {
      // var regularFont =
      //     await ShippingLabelGenerator.loadCairoFont(isBold: false);
      // var boldFont = await ShippingLabelGenerator.loadCairoFont(isBold: true);

      // Create ShipmentInfo with correct parameters
      final shipment = ShipmentInfo(
        // date: DateTime.now().toString(), // Use DateTime.now() for date
        // time: TimeOfDay.now()
        //     .format(context)
        //     .toString(), // Use TimeOfDay for time
        // truckNumber:
        //     _controllers[ControllerKeys.truckNumberController]?.text ?? '',
        itemDetails:
            _controllers[ControllerKeys.goodsDescriptionController]?.text ?? '',
        itemNumber:
            '$currentLabelIndex of $palletNumber', // Dynamic item number
        weight: _controllers[ControllerKeys.weightController]?.text ?? '',
        // volumeDifference:
        //     _controllers[ControllerKeys.additionalKGController]?.text ?? '',
        code: _controllers[ControllerKeys.codeNumberController]?.text ?? '',
      );

      // Generate the label for the current pallet
     // Modify this section in paste.txt
      final pdfData = await ShippingLabelGenerator.generateShippingLabel(
        sender: SenderDetails(
          name: _controllers[ControllerKeys.senderNameController]?.text ?? '',
        ),
        receiver: ReceiverDetails(
          name: _controllers[ControllerKeys.receiverNameController]?.text ?? '',
          phone:
              _controllers[ControllerKeys.receiverPhoneController]?.text ?? '',
          city: _selectedCity,
          country: _selectedCountry,
          address: _controllers[ControllerKeys.streetController]?.text ?? '',
        ),
        shipment: shipment,
        selectedCity: selectedCity,
      );

// Handle the PDF data
      final tempDir = await getTemporaryDirectory();
      final file =
          await File('${tempDir.path}/shipping_label_$currentLabelIndex.pdf')
              .create();
      await file.writeAsBytes(pdfData);

      if (mounted) {
        // Show the preview dialog for the current label
        final result = await showDialog(
          context: context,
          builder: (context) => LabelPDFPreviewDialog(pdfFile: file),
        );

        if (mounted && result == 'save') {
          _showCustomSnackBar(context, 'Label saved: ${file.path}');
        }
      }    }
  }
}

// Enums and Models
enum LabelLanguage { arabic, english, kurdish }
