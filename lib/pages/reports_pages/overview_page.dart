import 'dart:io';
import 'package:app/cubits/login_cubit/login_cubit_cubit.dart';
import 'package:excel/excel.dart' as xl;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:app/pages/reports_pages/reports_utils.dart';
import 'package:app/helper/send_db_helper.dart';
import 'package:app/models/send_model.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter_bloc/flutter_bloc.dart';

class OverviewScreen extends StatefulWidget {
  const OverviewScreen({super.key});

  @override
  State<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends State<OverviewScreen> {
  // Dropdown values
  String? selectedOffice;
  String? selectedFromTruck;
  String? selectedToTruck;
  String? selectedEUCountry;
  String? selectedAgentCity;
  static const String ALL_OPTION = "All";
  String? _selectedBranch;
  // Daily Report controllers
  final TextEditingController _dailyCodesController = TextEditingController();
  final TextEditingController _dailyPalletsController = TextEditingController();
  final TextEditingController _dailyBoxesController = TextEditingController();
  final TextEditingController _dailyKGController = TextEditingController();
  final TextEditingController _dailyCashInController = TextEditingController();
  final TextEditingController _dailyCommissionController =
      TextEditingController();
  DateTime _fromDate = DateTime.now();
  DateTime _toDate = DateTime.now();
  // Dropdown options
  String? officeNames;
  List<String> truckNumbers = [];
  List<String> euCountries = [];
  List<String> agentCities = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _restoreFormData();
      _loadDailyReportData(); // Add this line to load data on init
    });
    _fetchDropdownData();
    final authCubit = context.read<AuthCubit>();
    _selectedBranch = authCubit.selectedBranch;
  }

  @override
  void deactivate() {
    _saveFormData(); // This calls the method
    super.deactivate();
  }

  @override
  void dispose() {
    _dailyCodesController.dispose();
    _dailyPalletsController.dispose();
    _dailyBoxesController.dispose();
    _dailyKGController.dispose();
    _dailyCashInController.dispose();
    _dailyCommissionController.dispose();
    super.dispose();
  }

  void _saveFormData() {
    context.read<OverviewFormCubit>().saveFormData({
      // Make Report Card
      'selectedOffice': selectedOffice,
      'selectedFromTruck': selectedFromTruck,
      'selectedToTruck': selectedToTruck,
      'selectedEUCountry': selectedEUCountry,
      'selectedAgentCity': selectedAgentCity,

      // Daily Report Card
      'dailyCodes': _dailyCodesController.text,
      'dailyPallets': _dailyPalletsController.text,
      'dailyBoxes': _dailyBoxesController.text,
      'dailyKG': _dailyKGController.text,
      'dailyCashIn': _dailyCashInController.text,
      'dailyCommission': _dailyCommissionController.text,
    });
  }

  void _restoreFormData() {
    final formData = context.read<OverviewFormCubit>().state;
    setState(() {
      // Make Report Card
      selectedOffice = formData['selectedOffice'];
      selectedFromTruck = formData['selectedFromTruck'];
      selectedToTruck = formData['selectedToTruck'];
      selectedEUCountry = formData['selectedEUCountry'];
      selectedAgentCity = formData['selectedAgentCity'];

      // Daily Report Card
      _dailyCodesController.text = formData['dailyCodes'] ?? '';
      _dailyPalletsController.text = formData['dailyPallets'] ?? '';
      _dailyBoxesController.text = formData['dailyBoxes'] ?? '';
      _dailyKGController.text = formData['dailyKG'] ?? '';
      _dailyCashInController.text = formData['dailyCashIn'] ?? '';
      _dailyCommissionController.text = formData['dailyCommission'] ?? '';
    });
  }

  Future<void> _loadDailyReportData() async {
    final dbHelper = SendRecordDatabaseHelper();

    // Format dates for SQL query
    final fromDateStr = _fromDate.toYMD();
    final toDateStr = _toDate.toYMD();

    try {
      // Get daily totals for the date range
      final dailyTotals = await dbHelper.getDailyTotals(
        fromDate: fromDateStr,
        toDate: toDateStr,
        branchName: _selectedBranch,
      );

      setState(() {
        _dailyCodesController.text = dailyTotals['codeCount'].toString();
        _dailyPalletsController.text = dailyTotals['palletCount'].toString();
        _dailyBoxesController.text = dailyTotals['boxCount'].toString();
        _dailyKGController.text = dailyTotals['totalWeight'].toStringAsFixed(2);
        _dailyCashInController.text =
            dailyTotals['totalPaid'].toStringAsFixed(2);
      });
    } catch (e) {
      print('Error loading daily report data: $e');
      // Show error message to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading daily report data')),
      );
    }
  }

  // Add this widget for date range selection
  Widget _buildDateRangeSelector() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('From Date', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8.h),
              InkWell(
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _fromDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null && picked != _fromDate) {
                    setState(() {
                      _fromDate = picked;
                      _loadDailyReportData();
                    });
                  }
                },
                child: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    DateFormat('yyyy-MM-dd').format(_fromDate),
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('To Date', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8.h),
              InkWell(
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _toDate,
                    firstDate: _fromDate,
                    lastDate: DateTime.now(),
                  );
                  if (picked != null && picked != _toDate) {
                    setState(() {
                      _toDate = picked;
                      _loadDailyReportData();
                    });
                  }
                },
                child: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    DateFormat('yyyy-MM-dd').format(_toDate),
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Modify the Daily Report section in the build method
  Widget _buildDailyReportCard() {
    return Expanded(
      child: ReportCard(
        title: 'Daily Report',
        children: [
          CustomTextField(
            label: 'Office Name',
            enabled: false,
            controller: TextEditingController(text: _selectedBranch ?? ''),
          ),
          SizedBox(height: 24.h),
          _buildDateRangeSelector(),
          SizedBox(height: 24.h),
          CustomTextField(
            label: 'Daily Codes',
            enabled: false,
            controller: _dailyCodesController,
          ),
          SizedBox(height: 16.h),
          CustomTextField(
            label: 'Daily Pallets',
            enabled: false,
            controller: _dailyPalletsController,
          ),
          SizedBox(height: 16.h),
          CustomTextField(
            label: 'Daily Boxes',
            enabled: false,
            controller: _dailyBoxesController,
          ),
          SizedBox(height: 16.h),
          CustomTextField(
            label: 'Daily KG',
            enabled: false,
            controller: _dailyKGController,
          ),
          SizedBox(height: 16.h),
          CustomTextField(
            label: 'Daily Cash In',
            enabled: false,
            controller: _dailyCashInController,
          ),
          SizedBox(height: 24.h),
          ButtonRow(
            buttons: [
              CustomButton(
                text: 'Excel Report',
                color: Colors.green,
                onPressed: () async {
                  await exportDailyReportToExcel();
                },
              ),
              SizedBox(width: 16.w),
              CustomButton(
                text: 'PDF Report',
                color: Colors.purple,
                onPressed: () async {
                  await exportDailyReportToPdf();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _generateReportFileName(bool isDailyReport) {
    String dateRange = '';

    // Format the dates in the specified format (d-M-yyyy)
    String fromDateFormatted = DateFormat('d-M-yyyy').format(_fromDate);
    String toDateFormatted = DateFormat('d-M-yyyy').format(_toDate);

    // Construct the date range part
    if (_fromDate == _toDate) {
      dateRange = fromDateFormatted;
    } else {
      dateRange = '$fromDateFormatted-$toDateFormatted';
    }

    // Construct the base file name
    String baseName = isDailyReport ? 'Daily Report' : 'Report';

    // Combine the parts
    return '$baseName-$dateRange';
  }

  Future<void> exportDailyReportToExcel() async {
    // Create Excel workbook with the new alias
    var workbook = xl.Excel.createExcel();
    var sheet = workbook['Daily Report'];

    // Add title and date range
    sheet.appendRow([
      xl.TextCellValue('Daily Report'),
    ]);
    sheet.appendRow([
      xl.TextCellValue('Branch:'),
      xl.TextCellValue(_selectedBranch ?? ''),
    ]);
    sheet.appendRow([
      xl.TextCellValue('From Date:'),
      xl.TextCellValue(DateFormat('yyyy-MM-dd').format(_fromDate)),
      xl.TextCellValue('To Date:'),
      xl.TextCellValue(DateFormat('yyyy-MM-dd').format(_toDate)),
    ]);
    sheet.appendRow([]); // Empty row for spacing

    // Add summary data
    sheet.appendRow([
      xl.TextCellValue('Summary'),
    ]);
    sheet.appendRow([
      xl.TextCellValue('Total Codes:'),
      xl.TextCellValue(_dailyCodesController.text),
    ]);
    sheet.appendRow([
      xl.TextCellValue('Total Pallets:'),
      xl.TextCellValue(_dailyPalletsController.text),
    ]);
    sheet.appendRow([
      xl.TextCellValue('Total Boxes:'),
      xl.TextCellValue(_dailyBoxesController.text),
    ]);
    sheet.appendRow([
      xl.TextCellValue('Total Weight (KG):'),
      xl.TextCellValue(_dailyKGController.text),
    ]);
    sheet.appendRow([
      xl.TextCellValue('Total Cash In:'),
      xl.TextCellValue(_dailyCashInController.text),
    ]);

    // Format the workbook
    // Set column widths
    sheet.setColumnWidth(0, 20);
    sheet.setColumnWidth(1, 15);
    sheet.setColumnWidth(2, 15);
    sheet.setColumnWidth(3, 15);

    // Generate file name with date range
    final fileName = '${_generateReportFileName(true)}.xlsx';

    // Save file
    String? outputFile = await FilePicker.platform.saveFile(
      dialogTitle: 'Save Excel File',
      fileName: fileName,
      allowedExtensions: ['xlsx'],
    );

    final file = File(outputFile!);
    await file.writeAsBytes(workbook.encode()!);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Excel file saved as $fileName')),
    );
    }

  Future<void> exportDailyReportToPdf() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text(
                  'Daily Report',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),

              // Branch and Date Range Information
              pw.Text('Branch: ${_selectedBranch ?? ""}'),
              pw.Text(
                  'From Date: ${DateFormat('yyyy-MM-dd').format(_fromDate)}'),
              pw.Text('To Date: ${DateFormat('yyyy-MM-dd').format(_toDate)}'),
              pw.SizedBox(height: 20),

              // Summary Data
              pw.Text('Summary',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              _buildPdfSummaryRow('Total Codes:', _dailyCodesController.text),
              _buildPdfSummaryRow(
                  'Total Pallets:', _dailyPalletsController.text),
              _buildPdfSummaryRow('Total Boxes:', _dailyBoxesController.text),
              _buildPdfSummaryRow(
                  'Total Weight (KG):', _dailyKGController.text),
              _buildPdfSummaryRow(
                  'Total Cash In:', _dailyCashInController.text),
            ],
          );
        },
      ),
    );

    // Generate file name with date range
    final fileName = '${_generateReportFileName(true)}.pdf';

    String? outputFile = await FilePicker.platform.saveFile(
      dialogTitle: 'Save PDF File',
      fileName: fileName,
      allowedExtensions: ['pdf'],
    );

    final file = File(outputFile!);
    await file.writeAsBytes(await pdf.save());
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('PDF file saved as $fileName')),
    );
    }

// Helper method for PDF generation
  pw.Widget _buildPdfSummaryRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        children: [
          pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(width: 10),
          pw.Text(value),
        ],
      ),
    );
  }

  Future<void> _fetchDropdownData() async {
    final dbHelper = SendRecordDatabaseHelper();
    officeNames = _selectedBranch;

    // Get unique truck numbers and add "All" option
    final allTruckNumbers = await dbHelper.getUniqueTruckNumbers();
    setState(() {
      truckNumbers = [ALL_OPTION, ...allTruckNumbers];
      selectedFromTruck = ALL_OPTION;
      selectedToTruck = ALL_OPTION;
    });

    // Add "All" option to other dropdowns
    final fetchedEUCountries = await dbHelper.getUniqueEUCountries();
    final fetchedAgentCities = await dbHelper.getUniqueAgentCities();

    setState(() {
      euCountries = [ALL_OPTION, ...fetchedEUCountries];
      agentCities = [ALL_OPTION, ...fetchedAgentCities];
      selectedEUCountry = ALL_OPTION;
      selectedAgentCity = ALL_OPTION;
    });
  }

  Future<List<SendRecord>> fetchSendRecords({
    String? selectedFromTruck,
    String? selectedToTruck,
    String? selectedOffice,
    String? selectedEUCountry,
    String? selectedAgentCity,
  }) async {
    final dbHelper = SendRecordDatabaseHelper();
    final allRecords = await dbHelper.getAllSendRecords();

    return allRecords.where((record) {
      // Handle "All" option for truck range
      bool matchesTruckRange = true;
      if (selectedFromTruck != ALL_OPTION && selectedToTruck != ALL_OPTION) {
        final currentTruck = int.tryParse(record.truckNumber ?? '') ?? 0;
        final fromTruck = int.tryParse(selectedFromTruck ?? '') ?? 0;
        final toTruck = int.tryParse(selectedToTruck ?? '') ?? 0;
        matchesTruckRange =
            currentTruck >= fromTruck && currentTruck <= toTruck;
      }

      // Handle "All" option for other filters
      final matchesOffice =
          selectedOffice == null || record.branchName == selectedOffice;
      final matchesEUCountry = selectedEUCountry == ALL_OPTION ||
          record.receiverCountry == selectedEUCountry;
      final matchesAgentCity = selectedAgentCity == ALL_OPTION ||
          record.receiverCity == selectedAgentCity;

      return matchesTruckRange &&
          matchesOffice &&
          matchesEUCountry &&
          matchesAgentCity;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1.sw,
      height: 1.sh,
      padding: EdgeInsets.all(24.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Make Report Card
          Flexible(
            child: ReportCard(
              title: 'Make Report',
              children: [
                // CustomDropdown(
                //   label: 'Office Name',
                //   value: selectedOffice,
                //   items: officeNames,
                //   onChanged: (value) => setState(() => selectedOffice = value),
                // ),
                CustomTextField(
                  label: 'Office Name',
                  enabled: false,
                  controller:
                      TextEditingController(text: _selectedBranch ?? ''),
                ),
                SizedBox(height: 24.h),
                CustomDropdown(
                  label: 'Truck No. From',
                  value: selectedFromTruck,
                  items: truckNumbers,
                  onChanged: (value) {
                    setState(() {
                      selectedFromTruck = value;
                      // Auto-select "All" in To field if From is "All"
                      if (value == ALL_OPTION) {
                        selectedToTruck = ALL_OPTION;
                      }
                    });
                  },
                ),
                SizedBox(height: 24.h),
                CustomDropdown(
                  label: 'Truck No. To',
                  value: selectedToTruck,
                  items: truckNumbers,
                  // Disable To dropdown if From is "All"
                  enabled: selectedFromTruck != ALL_OPTION,
                  onChanged: (value) {
                    setState(() {
                      selectedToTruck = value;
                      // Auto-select "All" in To field if From is "All"
                      if (value == ALL_OPTION) {
                        selectedFromTruck = ALL_OPTION;
                      }
                    });
                  },
                ),
                SizedBox(height: 24.h),
                CustomDropdown(
                  label: 'EU Country',
                  value: selectedEUCountry,
                  items: euCountries,
                  onChanged: (value) =>
                      setState(() => selectedEUCountry = value),
                ),
                SizedBox(height: 24.h),
                CustomDropdown(
                  label: 'Agent City',
                  value: selectedAgentCity,
                  items: agentCities,
                  onChanged: (value) =>
                      setState(() => selectedAgentCity = value),
                ),
                SizedBox(height: 90.h),
                ButtonRow(
                  buttons: [
                    CustomButton(
                      text: 'Excel Report',
                      color: Colors.green,
                      onPressed: () async {
                        await exportToExcel();
                      },
                    ),
                    SizedBox(width: 16.w),
                    CustomButton(
                      text: 'PDF Report',
                      color: Colors.purple,
                      onPressed: () async {
                        await exportToPdf();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: 24.w),
          // Daily Report Card
          // Replace the existing Daily Report Card with this implementation
          _buildDailyReportCard(),
        ],
      ),
    );
  }

  // Add this new method to generate dynamic file name
  String _generateFileName() {
    final List<String> nameParts = [];

    // Add branch name if available
    if (_selectedBranch != null && _selectedBranch!.isNotEmpty) {
      nameParts.add(_selectedBranch!);
    }

    // Add truck range
    if (selectedFromTruck != null && selectedToTruck != null) {
      if (selectedFromTruck == ALL_OPTION) {
        nameParts.add('TruckAll');
      } else if (selectedFromTruck == selectedToTruck) {
        nameParts.add('Truck$selectedFromTruck');
      } else {
        nameParts.add('Truck$selectedFromTruck-$selectedToTruck');
      }
    }

    // Add country if selected
    if (selectedEUCountry != null && selectedEUCountry != ALL_OPTION) {
      nameParts.add(selectedEUCountry!);
    }

    // Add city if selected
    if (selectedAgentCity != null && selectedAgentCity != ALL_OPTION) {
      nameParts.add(selectedAgentCity!);
    }

    // Join all parts with hyphens and remove any invalid file name characters
    return nameParts
        .join('-')
        .replaceAll(
            RegExp(r'[<>:"/\\|?*]'), '') // Remove invalid file characters
        .replaceAll(RegExp(r'\s+'), '-'); // Replace spaces with hyphens
  }

  Future<void> exportToExcel() async {
    final records = await fetchSendRecords(
      selectedFromTruck: selectedFromTruck,
      selectedToTruck: selectedToTruck,
      selectedOffice: selectedOffice,
      selectedEUCountry: selectedEUCountry,
      selectedAgentCity: selectedAgentCity,
    );

    if (records.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No records found for the selected criteria.')),
      );
      return;
    }

    var excel = xl.Excel.createExcel();
    var sheet = excel['Sheet1'];

    // Comprehensive headers
    final headers = [
      'Date',
      'Branch Name',
      'Agent Name',

      'Truck Number',
      'Code Number',
      // Sender Information
      'Sender Name',
      'Sender Phone',
      'Sender ID Number',
      // Receiver Information
      'Receiver Name',
      'Receiver Phone',
      'Receiver Country',
      'Receiver City',
      'Street Name',
      'Apartment Number',
      'Zip Code',

      // Goods Information
      'Goods Description',
      'Box Number',
      'Pallet Number',
      'Real Weight (kg)',
      'Additional Weight (kg)',
      'Total Weight (kg)',
      // Dimensions
      'Length',
      'Width',
      'Height',

      // Financial Information
      'Door To Door Price',
      'Price Per Kg',
      'Minimum Price',
      'Insurance Percent',
      'Goods Value',

      'Insurance Amount',
      'Customs Cost',
      'Export Doc Cost',
      'Box Packing Cost',
      'Door To Door Cost',
      'Post Sub Cost',
      'Discount Amount',
      'Total Post Cost',
      'Total Post Cost Paid',
      'Unpaid Amount',
      'Total Cost (EUR)',
      'Unpaid Amount (EUR)',
    ];

    // Add headers
    sheet.appendRow(headers.map((header) => xl.TextCellValue(header)).toList());

    // Add data rows with comprehensive information
    for (var record in records) {
      sheet.appendRow([
        xl.TextCellValue(record.date ?? ''),
        xl.TextCellValue(record.branchName ?? ''),
        xl.TextCellValue(record.agentName ?? ''),

        xl.TextCellValue(record.truckNumber ?? ''),
        xl.TextCellValue(record.codeNumber ?? ''),
        // Sender Information
        xl.TextCellValue(record.senderName ?? ''),
        xl.TextCellValue(record.senderPhone ?? ''),
        xl.TextCellValue(record.senderIdNumber ?? ''),
        // Receiver Information
        xl.TextCellValue(record.receiverName ?? ''),
        xl.TextCellValue(record.receiverPhone ?? ''),
        xl.TextCellValue(record.receiverCountry ?? ''),
        xl.TextCellValue(record.receiverCity ?? ''),
        xl.TextCellValue(record.streetName ?? ''),
        xl.TextCellValue(record.zipCode ?? ''),
        // Goods Information
        xl.TextCellValue(record.goodsDescription ?? ''),
        xl.DoubleCellValue(record.boxNumber?.toDouble() ?? 0),
        xl.DoubleCellValue(record.palletNumber?.toDouble() ?? 0),
        xl.DoubleCellValue(record.realWeightKg ?? 0),
        xl.DoubleCellValue(record.additionalKg ?? 0),
        xl.DoubleCellValue(record.totalWeightKg ?? 0),
        // Dimensions
        xl.DoubleCellValue(record.length ?? 0),
        xl.DoubleCellValue(record.width ?? 0),
        xl.DoubleCellValue(record.height ?? 0),
        // Financial Information
        xl.DoubleCellValue(record.doorToDoorPrice ?? 0),
        xl.DoubleCellValue(record.pricePerKg ?? 0),
        xl.DoubleCellValue(record.minimumPrice ?? 0),
        xl.DoubleCellValue(record.insurancePercent ?? 0),
        xl.DoubleCellValue(record.goodsValue ?? 0),
        xl.DoubleCellValue(record.insuranceAmount ?? 0),
        xl.DoubleCellValue(record.customsCost ?? 0),
        xl.DoubleCellValue(record.boxPackingCost ?? 0),
        xl.DoubleCellValue(record.doorToDoorCost ?? 0),
        xl.DoubleCellValue(record.postSubCost ?? 0),
        xl.DoubleCellValue(record.discountAmount ?? 0),
        xl.DoubleCellValue(record.totalPostCost ?? 0),
        xl.DoubleCellValue(record.totalPostCostPaid ?? 0),
        xl.DoubleCellValue(record.unpaidAmount ?? 0),
        xl.DoubleCellValue(record.totalCostEuroCurrency ?? 0),
        xl.DoubleCellValue(record.unpaidAmountEuro ?? 0),
      ]);
    }

    // Auto-fit columns for better readability
    for (var col = 0; col < headers.length; col++) {
      sheet.setColumnWidth(col, 15.0);
    }

    final fileName = '${_generateFileName()}.xlsx';
    String? outputFile = await FilePicker.platform.saveFile(
      dialogTitle: 'Save Excel File',
      fileName: fileName,
      allowedExtensions: ['xlsx'],
    );

    final file = File(outputFile!);
    await file.writeAsBytes(excel.encode()!);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Excel file saved as $fileName')),
    );
    }

  Future<void> exportToPdf() async {
    final records = await fetchSendRecords(
      selectedFromTruck: selectedFromTruck,
      selectedToTruck: selectedToTruck,
      selectedOffice: selectedOffice,
      selectedEUCountry: selectedEUCountry,
      selectedAgentCity: selectedAgentCity,
    );

    if (records.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No records found for the selected criteria.')),
      );
      return;
    }

    final pdf = pw.Document();

    // Helper function to create a section
    pw.Widget createSection(String title, List<Map<String, String>> data) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 5),
          ...data.map((item) => pw.Row(
                children: [
                  pw.Text('${item.keys.first}: ',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text(item.values.first),
                ],
              )),
          pw.SizedBox(height: 10),
        ],
      );
    }

    // Add pages for each record
    for (var record in records) {
      pdf.addPage(
        pw.Page(
          margin: const pw.EdgeInsets.all(20),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Center(
                    child: pw.Text('Shipment Details',
                        style: pw.TextStyle(
                            fontSize: 20, fontWeight: pw.FontWeight.bold))),
                pw.SizedBox(height: 20),

                // Basic Information
                createSection('Basic Information', [
                  {'Date': record.date ?? ''},
                  {'Branch': record.branchName ?? ''},
                  {'Agent': record.agentName ?? ''},
                  {'Truck Number': record.truckNumber ?? ''},
                  {'Code Number': record.codeNumber ?? ''},
                ]),

                // Sender Information
                createSection('Sender Information', [
                  {'Name': record.senderName ?? ''},
                  {'Phone': record.senderPhone ?? ''},
                  {'ID Number': record.senderIdNumber ?? ''},
                ]),

                // Receiver Information
                createSection('Receiver Information', [
                  {'Name': record.receiverName ?? ''},
                  {'Phone': record.receiverPhone ?? ''},
                  {'Country': record.receiverCountry ?? ''},
                  {'City': record.receiverCity ?? ''},
                  {'Street': record.streetName ?? ''},
                  {'Zip Code': record.zipCode ?? ''},
                ]),

                // Goods Information
                createSection('Goods Information', [
                  {'Description': record.goodsDescription ?? ''},
                  {'Boxes': record.boxNumber?.toString() ?? '0'},
                  {'Pallets': record.palletNumber?.toString() ?? '0'},
                  {
                    'Real Weight':
                        '${record.realWeightKg?.toString() ?? "0"} kg'
                  },
                  {
                    'Additional Weight':
                        '${record.additionalKg?.toString() ?? "0"} kg'
                  },
                  {
                    'Total Weight':
                        '${record.totalWeightKg?.toString() ?? "0"} kg'
                  },
                ]),

                // Financial Information
                createSection('Financial Information', [
                  {
                    'Door To Door Price':
                        record.doorToDoorPrice?.toString() ?? '0'
                  },
                  {'Price Per Kg': record.pricePerKg?.toString() ?? '0'},
                  {
                    'Insurance':
                        '${record.insurancePercent?.toString() ?? "0"}%'
                  },
                  {'Goods Value': record.goodsValue?.toString() ?? '0'},
                  {
                    'Total Cost (EUR)':
                        record.totalCostEuroCurrency?.toString() ?? '0'
                  },
                  {
                    'Unpaid Amount (EUR)':
                        record.unpaidAmountEuro?.toString() ?? '0'
                  },
                ]),
              ],
            );
          },
        ),
      );
    }

    final fileName = '${_generateFileName()}.pdf';
    String? outputFile = await FilePicker.platform.saveFile(
      dialogTitle: 'Save PDF File',
      fileName: fileName,
      allowedExtensions: ['pdf'],
    );

    final file = File(outputFile!);
    await file.writeAsBytes(await pdf.save());
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('PDF file saved as $fileName')),
    );
    }
}

class OverviewFormCubit extends Cubit<Map<String, dynamic>> {
  OverviewFormCubit() : super({});

  void saveFormData(Map<String, dynamic> formData) => emit(formData);
  void clearFormData() => emit({});
}

extension DateFormatting on DateTime {
  String toYMD() {
    return DateFormat('yyyy-MM-dd').format(this);
  }
}
