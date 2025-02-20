import 'dart:convert';

import 'package:app/cubits/login_cubit/login_cubit_cubit.dart';
import 'package:app/helper/cities_db_helper.dart';
import 'package:app/helper/send_db_helper.dart';
import 'package:app/helper/sql_helper.dart';
import 'package:app/models/send_model.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:io';

import 'package:intl/intl.dart';

// State management class
class EUReportState {
  final bool isLoading;
  final String? error;
  final String? selectedBranch;
  final String? selectedTruck;
  final String? selectedAgentCity;
  final String? selectedPostCity;
  final List<String> postCities;
  final List<String> agentCities;
  final List<String> allTrucks;

  EUReportState({
    this.isLoading = false,
    this.error,
    this.selectedBranch,
    this.selectedTruck,
    this.selectedAgentCity,
    this.selectedPostCity,
    this.postCities = const [],
    this.agentCities = const [],
    this.allTrucks = const ['All'],
  });

  EUReportState copyWith({
    bool? isLoading,
    String? error,
    String? selectedBranch,
    String? selectedTruck,
    String? selectedAgentCity,
    String? selectedPostCity,
    List<String>? postCities,
    List<String>? agentCities,
    List<String>? allTrucks,
  }) {
    return EUReportState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      selectedBranch: selectedBranch ?? this.selectedBranch,
      selectedTruck: selectedTruck ?? this.selectedTruck,
      selectedAgentCity: selectedAgentCity ?? this.selectedAgentCity,
      selectedPostCity: selectedPostCity ?? this.selectedPostCity,
      postCities: postCities ?? this.postCities,
      agentCities: agentCities ?? this.agentCities,
      allTrucks: allTrucks ?? this.allTrucks,
    );
  }
}

class EUReportScreen extends StatefulWidget {
  const EUReportScreen({super.key});

  @override
  State<EUReportScreen> createState() => _EUReportScreenState();
}

class _EUReportScreenState extends State<EUReportScreen> {
  late EUReportState _state;
  final SendRecordDatabaseHelper _dbHelper = SendRecordDatabaseHelper();
  final DatabaseHelper _citiesHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _state = EUReportState();
    _initializeData();
  }

  Future<void> _exportReport(
      List<SendRecord> records, String filePrefix) async {
    try {
      setState(() => _state = _state.copyWith(isLoading: true, error: null));

      final excel = Excel.createExcel();
      final sheet = excel['Sheet1'];

      // Add ALL fields from SendRecord as headers
      final headers = [
        'ID',
        'Date',
        'Truck Number',
        'Code Number',
        'Sender Name',
        'Sender Phone',
        'Sender ID Number',
        'Goods Description',
        'Box Number',
        'Pallet Number',
        'Real Weight (KG)',
        'Length',
        'Width',
        'Height',
        'Is Dimension Calculated',
        'Additional KG',
        'Total Weight (KG)',
        'Agent Name',
        'Branch Name',
        'Receiver Name',
        'Receiver Phone',
        'Receiver Country',
        'Receiver City',
        'Street Name',
        'Zip Code',
        'Door to Door Price',
        'Price per KG',
        'Minimum Price',
        'Insurance Percent',
        'Goods Value',
        'Insurance Amount',
        'Customs Cost',
        'Box Packing Cost',
        'Door to Door Cost',
        'Post Sub Cost',
        'Discount Amount',
        'Total Post Cost',
        'Total Post Cost Paid',
        'Unpaid Amount',
        'Total Cost (Euro Currency)',
        'Unpaid Amount (Euro)'
      ];

      // Add headers to the first row
      sheet.appendRow(headers.map((header) => TextCellValue(header)).toList());

      // Add data rows with ALL fields
      for (var record in records) {
        sheet.appendRow([
          record.id ?? '',
          record.date ?? '',
          record.truckNumber ?? '',
          record.codeNumber ?? '',
          record.senderName ?? '',
          record.senderPhone ?? '',
          record.senderIdNumber ?? '',
          record.goodsDescription ?? '',
          record.boxNumber ?? 0,
          record.palletNumber ?? 0,
          record.realWeightKg ?? 0.0,
          record.length ?? 0.0,
          record.width ?? 0.0,
          record.height ?? 0.0,
          record.isDimensionCalculated ?? 0,
          record.additionalKg ?? 0.0,
          record.totalWeightKg ?? 0.0,
          record.agentName ?? '',
          record.branchName ?? '',
          record.receiverName ?? '',
          record.receiverPhone ?? '',
          record.receiverCountry ?? '',
          record.receiverCity ?? '',
          record.streetName ?? '',
          record.zipCode ?? '',
          record.doorToDoorPrice ?? 0.0,
          record.pricePerKg ?? 0.0,
          record.minimumPrice ?? 0.0,
          record.insurancePercent ?? 0.0,
          record.goodsValue ?? 0.0,
          record.insuranceAmount ?? 0.0,
          record.customsCost ?? 0.0,
          record.boxPackingCost ?? 0.0,
          record.doorToDoorCost ?? 0.0,
          record.postSubCost ?? 0.0,
          record.discountAmount ?? 0.0,
          record.totalPostCost ?? 0.0,
          record.totalPostCostPaid ?? 0.0,
          record.unpaidAmount ?? 0.0,
          record.totalCostEuroCurrency ?? 0.0,
          record.unpaidAmountEuro ?? 0.0,
        ].map((value) => TextCellValue(value.toString())).toList());
      }

      final String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Excel File',
        fileName: '${filePrefix}_${DateTime.now().millisecondsSinceEpoch}.xlsx',
        allowedExtensions: ['xlsx'],
      );

      if (outputFile != null) {
        final file = File(outputFile);
        await file.writeAsBytes(excel.encode()!);
        _showSnackBar('Excel file saved successfully');
      }
    } catch (e) {
      _showSnackBar('Failed to export report: ${e.toString()}');
    } finally {
      setState(() => _state = _state.copyWith(isLoading: false));
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          height: 1.sh,
          width: .5.sw,
          padding: EdgeInsets.all(24.w),
          child: Card(
            child: _state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          SizedBox(height: 24.h),
          _buildOfficeField(),
          SizedBox(height: 16.h),
          _buildTruckDropdown(),
          SizedBox(height: 16.h),
          _buildAgentCityDropdown(), // New dropdown for agent cities
          SizedBox(height: 24.h),
          _buildAgentCityExportButton(), // New export button for agent city
          SizedBox(height: 24.h),
          _buildPostCityDropdown(), // New dropdown for post cities
          SizedBox(height: 16.h),
          _buildPostCityExportButton(), // New export button for post city
          // In _buildContent() method, after post city export button:
          SizedBox(height: 24.h),
          _buildGoodsDescriptionExportButton(),
          if (_state.error != null)
            Padding(
              padding: EdgeInsets.only(top: 16.h),
              child: Text(
                _state.error!,
                style: TextStyle(color: Colors.red),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGoodsDescriptionExportButton() {
    return ElevatedButton(
      onPressed:
          _state.selectedTruck != null ? _handleGoodsDescriptionExport : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.purple,
        minimumSize: Size(200.w, 50.h),
      ),
      child: Text('Export Goods Descriptions for ${_state.selectedTruck}'),
    );
  }

  Future<void> _handleGoodsDescriptionExport() async {
    try {
      setState(() => _state = _state.copyWith(isLoading: true, error: null));

      final records = await _dbHelper.getAllSendRecords();
      final truckRecords = _state.selectedTruck == 'All'
          ? records
          : records
              .where((r) => r.truckNumber == _state.selectedTruck)
              .toList();

      final Map<int, Map<String, dynamic>> goodsMap = {};

      for (var record in truckRecords) {
        try {
          final goodsList = jsonDecode(record.goodsDescription ?? '[]') as List;

          for (var goodsJson in goodsList) {
            final id = goodsJson['id'] as int? ?? 0;
            final descEn = goodsJson['descriptionEn']?.toString() ?? 'N/A';
            final descAr = goodsJson['descriptionAr']?.toString() ?? 'N/A';
            final quantity = (goodsJson['quantity'] as num?)?.toDouble() ?? 0;
            final weight = (goodsJson['weight'] as num?)?.toDouble() ?? 0;

            goodsMap.update(id, (value) {
              return {
                'descriptionEn': descEn,
                'descriptionAr': descAr,
                'quantity': value['quantity'] + quantity,
                'weight': value['weight'] + weight
              };
            },
                ifAbsent: () => {
                      'descriptionEn': descEn,
                      'descriptionAr': descAr,
                      'quantity': quantity,
                      'weight': weight
                    });
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error processing record ${record.id}: $e');
          }
        }
      }

      // Sort by ID and create ordered list
      final sortedGoods = goodsMap.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key));

      // Create Excel
      final excel = Excel.createExcel();
      final sheet = excel['GoodsDescriptions'];

      // Headers
      sheet.appendRow([
        'ID',
        'Description (EN)',
        'Description (AR)',
        'Total Quantity',
        'Total Weight (KG)'
      ].map((h) => TextCellValue(h)).toList());

      // Add sorted data
      for (var entry in sortedGoods) {
        sheet.appendRow([
          entry.key.toString(),
          entry.value['descriptionEn'],
          entry.value['descriptionAr'],
          entry.value['quantity'].toString(),
          entry.value['weight'].toStringAsFixed(2)
        ].map((v) => TextCellValue(v)).toList());
      }

      // Generate filename
      final fileName = _state.selectedTruck == 'All'
          ? 'all_trucks_goods_report'
          : 'goods_${_state.selectedTruck}_report';

      // Save file
      final String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Goods Report',
        fileName:
            '${fileName}_${DateFormat('yyyyMMdd').format(DateTime.now())}.xlsx',
        allowedExtensions: ['xlsx'],
      );

      if (outputFile != null) {
        final file = File(outputFile);
        await file.writeAsBytes(excel.encode()!);
        _showSnackBar('Exported ${sortedGoods.length} goods descriptions');
      }
    } catch (e) {
      _showSnackBar('Export failed: ${e.toString()}');
    } finally {
      setState(() => _state = _state.copyWith(isLoading: false));
    }
  }

  // New method to build agent city dropdown
  Widget _buildAgentCityDropdown() {
    return DropdownButtonFormField<String>(
      value: _state.selectedAgentCity,
      decoration: const InputDecoration(
        labelText: 'Agent City',
        border: OutlineInputBorder(),
      ),
      hint: const Text('Select Agent City'),
      items: [
        const DropdownMenuItem(
          value: null,
          child: Text('Select City'),
        ),
        ..._state.agentCities.map((city) {
          return DropdownMenuItem(value: city, child: Text(city));
        }),
      ],
      onChanged: (value) {
        setState(() => _state = _state.copyWith(selectedAgentCity: value));
      },
    );
  }

  // New method to build agent city export button
  Widget _buildAgentCityExportButton() {
    return ElevatedButton(
      onPressed: _state.selectedAgentCity != null
          ? () => _handleSelectedAgentCityExport()
          : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        minimumSize: Size(200.w, 50.h),
      ),
      child: Text('Export ${_state.selectedAgentCity ?? 'Agent City'} Data'),
    );
  }

  // New method to handle export for selected agent city
  Future<void> _handleSelectedAgentCityExport() async {
    if (_state.selectedAgentCity == null) {
      _showSnackBar('Please select an agent city');
      return;
    }

    final records = await _dbHelper.getAllSendRecords();
    final filteredRecords = records.where((record) {
      final matchesTruck = _state.selectedTruck == 'All' ||
          record.truckNumber == _state.selectedTruck;
      final matchesCity = record.receiverCity == _state.selectedAgentCity;
      return matchesTruck && matchesCity;
    }).toList();

    await _exportReport(filteredRecords,
        'agent_${_state.selectedTruck != 'All' ? '${_state.selectedTruck}_' : ''}${_state.selectedAgentCity!.toLowerCase()}_report');
  }

  Widget _buildPostCityDropdown() {
    return DropdownButtonFormField<String>(
      value: _state.selectedPostCity,
      decoration: const InputDecoration(
        labelText: 'POST City',
        border: OutlineInputBorder(),
      ),
      hint: const Text('Select POST City'),
      items: [
        const DropdownMenuItem(
          value: null,
          child: Text('Select City'),
        ),
        ..._state.postCities.map((city) {
          return DropdownMenuItem(value: city, child: Text(city));
        }),
      ],
      onChanged: (value) {
        setState(() => _state = _state.copyWith(selectedPostCity: value));
      },
    );
  }

  // New method to build post city export button
  Widget _buildPostCityExportButton() {
    return ElevatedButton(
      onPressed: _state.selectedPostCity != null
          ? () => _handleSelectedPostCityExport()
          : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        minimumSize: Size(200.w, 50.h),
      ),
      child: Text('Export ${_state.selectedPostCity ?? 'POST City'} Data'),
    );
  }

  // New method to handle export for selected post city
  Future<void> _handleSelectedPostCityExport() async {
    if (_state.selectedPostCity == null) {
      _showSnackBar('Please select a POST city');
      return;
    }

    final records = await _dbHelper.getAllSendRecords();
    final filteredRecords = records.where((record) {
      final matchesTruck = _state.selectedTruck == 'All' ||
          record.truckNumber == _state.selectedTruck;
      final matchesCity = record.receiverCountry ==
          _state.selectedPostCity!.replaceAll(' POST', '');
      return matchesTruck && matchesCity;
    }).toList();

    await _exportReport(filteredRecords,
        'post_${_state.selectedTruck != 'All' ? '${_state.selectedTruck}_' : ''}${_state.selectedPostCity!.toLowerCase()}_report');
  }

  // Modify _initializeData to reset selectedAgentCity when initializing
  Future<void> _initializeData() async {
    try {
      setState(() => _state = _state.copyWith(isLoading: true, error: null));
      setState(() => _state = _state.copyWith(
          isLoading: true, error: null, selectedPostCity: null));

      final authCubit = context.read<AuthCubit>();

      // Get all trucks
      final trucks = await _dbHelper.getUniqueTruckNumbers();
      final allTrucks = ['All', ...trucks];

      // Get cities
      final allCities = await _citiesHelper.getAllCities();
      final postCities = allCities
          .where((city) => city.isPost)
          .map((city) => "${city.country} POST")
          .toList();

      final agentCities = allCities
          .where((city) => city.hasAgent && !city.isPost)
          .map((city) => city.cityName)
          .toList();

      setState(() {
        _state = _state.copyWith(
          isLoading: false,
          selectedBranch: authCubit.selectedBranch,
          selectedTruck: trucks.isNotEmpty ? trucks.first : 'All',
          selectedAgentCity: null, // Reset agent city
          postCities: postCities,
          agentCities: agentCities,
          allTrucks: allTrucks,
        );
      });
    } catch (e) {
      setState(() => _state = _state.copyWith(
            isLoading: false,
            error: 'Failed to load data: ${e.toString()}',
          ));
      setState(() => _state = _state.copyWith(
            isLoading: false,
            error: 'Failed to load data: ${e.toString()}',
          ));
    }
  }

  Widget _buildHeader() {
    return Text(
      'EU Report Data',
      style: Theme.of(context).textTheme.titleLarge,
    );
  }

  Widget _buildOfficeField() {
    return TextField(
      enabled: false,
      controller: TextEditingController(text: _state.selectedBranch),
      decoration: const InputDecoration(
        labelText: 'Office Name',
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildTruckDropdown() {
    return DropdownButtonFormField<String>(
      value: _state.selectedTruck,
      decoration: const InputDecoration(
        labelText: 'Truck Number',
        border: OutlineInputBorder(),
      ),
      items: _state.allTrucks.map((truck) {
        return DropdownMenuItem(value: truck, child: Text(truck));
      }).toList(),
      onChanged: (value) {
        setState(() => _state = _state.copyWith(selectedTruck: value));
      },
    );
  }





}
