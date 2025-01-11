import 'dart:io';

import 'package:app/helper/send_db_helper.dart';
import 'package:app/models/send_model.dart';
import 'package:app/pages/reports_pages/reports_utils.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:pdf/widgets.dart' as pw;

class EUReportScreen extends StatefulWidget {
  const EUReportScreen({super.key});

  @override
  State<EUReportScreen> createState() => _EUReportScreenState();
}

class _EUReportScreenState extends State<EUReportScreen> {
  // Dropdown values
  String? selectedOffice;
  String? selectedTruck;
  String? selectedEUCountry;
  String? selectedAgentCity;

  // Date picker values
  DateTime? selectedDate;
  DateTime? depDateKU;
  DateTime? arrivalDateNL;

  // Text field controllers
  final TextEditingController truckNoController = TextEditingController();

  // Checkbox values
  bool getOnlyCountriesAccounts = true;
  bool getAllAgentsAccounts = false;
  bool makeCompleteShipment = true;
  bool printPreview = true;

  // Lists to hold dropdown options
  List<String> officeNames = [];
  List<String> truckNumbers = [];
  List<String> euCountries = [];
  List<String> agentCities = [];

  @override
  void initState() {
    super.initState();
    _fetchDropdownData();
  }

  Future<void> _fetchDropdownData() async {
    final dbHelper = SendRecordDatabaseHelper();
    officeNames = await dbHelper.getUniqueOfficeNames();
    truckNumbers = await dbHelper.getUniqueTruckNumbers();
    euCountries = await dbHelper.getUniqueEUCountries();
    agentCities = await dbHelper.getUniqueAgentCities();
    setState(() {});
  }

  Future<List<SendRecord>> fetchSendRecords({
    DateTime? selectedDate,
    String? selectedTruck,
    String? selectedOffice,
    String? selectedEUCountry,
    String? selectedAgentCity,
  }) async {
    final dbHelper = SendRecordDatabaseHelper();
    final allRecords = await dbHelper.getAllSendRecords();

    // Filter records based on selected fields
    return allRecords.where((record) {
      final matchesDate = selectedDate == null ||
          record.date == DateFormat('yyyy-MM-dd').format(selectedDate);
      final matchesTruck =
          selectedTruck == null || record.truckNumber == selectedTruck;
      final matchesOffice =
          selectedOffice == null || record.branchName == selectedOffice;
      final matchesEUCountry = selectedEUCountry == null ||
          record.receiverCountry == selectedEUCountry;
      final matchesAgentCity =
          selectedAgentCity == null || record.receiverCity == selectedAgentCity;

      return matchesDate &&
          matchesTruck &&
          matchesOffice &&
          matchesEUCountry &&
          matchesAgentCity;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ReportCard(
              title: 'EU Report Data Per Office',
              children: [
                CustomDropdown(
                  label: 'Office Name',
                  value: selectedOffice,
                  items: officeNames,
                  onChanged: (value) {
                    setState(() {
                      selectedOffice = value;
                    });
                  },
                ),
                CustomDropdown(
                  label: 'Truck No.',
                  value: selectedTruck,
                  items: truckNumbers,
                  onChanged: (value) {
                    setState(() {
                      selectedTruck = value;
                    });
                  },
                ),
                CustomDropdown(
                  label: 'EU Country',
                  value: selectedEUCountry,
                  items: euCountries,
                  onChanged: (value) {
                    setState(() {
                      selectedEUCountry = value;
                    });
                  },
                ),
                CustomDropdown(
                  label: 'Agent City',
                  value: selectedAgentCity,
                  items: agentCities,
                  onChanged: (value) {
                    setState(() {
                      selectedAgentCity = value;
                    });
                  },
                ),
                CustomDatePicker(
                  label: 'Date',
                  selectedDate: selectedDate,
                  onDateSelected: (date) {
                    setState(() {
                      selectedDate = date;
                    });
                  },
                ),
                ButtonRow(
                  buttons: [
                    CustomButton(
                      text: 'Excel Report',
                      color: Colors.green,
                      onPressed: () async {
                        final records = await fetchSendRecords(
                          selectedDate: selectedDate,
                          selectedTruck: selectedTruck,
                          selectedOffice: selectedOffice,
                          selectedEUCountry: selectedEUCountry,
                          selectedAgentCity: selectedAgentCity,
                        );
                        await exportToExcel(records);
                      },
                    ),
                    CustomButton(
                      text: 'PDF Report',
                      color: Colors.blue,
                      onPressed: () async {
                        final records = await fetchSendRecords(
                          selectedDate: selectedDate,
                          selectedTruck: selectedTruck,
                          selectedOffice: selectedOffice,
                          selectedEUCountry: selectedEUCountry,
                          selectedAgentCity: selectedAgentCity,
                        );
                        await exportToPdf(records);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ReportCard(
              title: 'EU Report Data Per Truck',
              children: [
                CheckboxListTile(
                  title: const Text('Get Only Countries Accounts'),
                  value: getOnlyCountriesAccounts,
                  onChanged: (value) {
                    setState(() {
                      getOnlyCountriesAccounts = value ?? true;
                    });
                  },
                ),
                CheckboxListTile(
                  title: const Text('Get All Agents Accounts'),
                  value: getAllAgentsAccounts,
                  onChanged: (value) {
                    setState(() {
                      getAllAgentsAccounts = value ?? false;
                    });
                  },
                ),
                CheckboxListTile(
                  title: const Text('Make Complete Shipment'),
                  value: makeCompleteShipment,
                  onChanged: (value) {
                    setState(() {
                      makeCompleteShipment = value ?? true;
                    });
                  },
                ),
                CheckboxListTile(
                  title: const Text('Print Preview'),
                  value: printPreview,
                  onChanged: (value) {
                    setState(() {
                      printPreview = value ?? true;
                    });
                  },
                ),
                CustomTextField(
                  label: 'EU Truck No.',
                  controller: truckNoController,
                ),
                CustomDatePicker(
                  label: 'Dep. Date KU',
                  selectedDate: depDateKU,
                  onDateSelected: (date) {
                    setState(() {
                      depDateKU = date;
                    });
                  },
                ),
                CustomDatePicker(
                  label: 'Arrival Date NL',
                  selectedDate: arrivalDateNL,
                  onDateSelected: (date) {
                    setState(() {
                      arrivalDateNL = date;
                    });
                  },
                ),
                ButtonRow(
                  buttons: [
                    CustomButton(
                      text: 'Excel Report',
                      color: Colors.green,
                      onPressed: () async {
                        final records = await fetchSendRecords();
                        await exportToExcel(records);
                      },
                    ),
                    CustomButton(
                      text: 'PDF Report',
                      color: Colors.blue,
                      onPressed: () async {
                        final records = await fetchSendRecords();
                        await exportToPdf(records);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Export to Excel
  Future<void> exportToExcel(List<SendRecord> records) async {
    // Create an Excel workbook
    var excel = Excel.createExcel();
    var sheet = excel['Sheet1'];

    // Add headers
    sheet.appendRow([
      TextCellValue('Date'),
      TextCellValue('Truck Number'),
      TextCellValue('Code Number'),
      TextCellValue('Sender Name'),
      TextCellValue('Receiver Name'),
      TextCellValue('Receiver Country'),
      TextCellValue('Receiver City'),
      TextCellValue('Total Weight (kg)'),
      TextCellValue('Total Cost (EUR)'),
    ]);

    // Add data rows
    for (var record in records) {
      sheet.appendRow([
        TextCellValue(record.date ?? ''),
        TextCellValue(record.truckNumber ?? ''),
        TextCellValue(record.codeNumber ?? ''),
        TextCellValue(record.senderName ?? ''),
        TextCellValue(record.receiverName ?? ''),
        TextCellValue(record.receiverCountry ?? ''),
        TextCellValue(record.receiverCity ?? ''),
        TextCellValue(record.totalWeightKg?.toString() ?? ''),
        TextCellValue(record.totalCostEuroCurrency?.toString() ?? ''),
      ]);
    }

    // Let the user choose where to save the file
    String? outputFile = await FilePicker.platform.saveFile(
      dialogTitle: 'Save Excel File',
      fileName: 'send_report.xlsx',
      allowedExtensions: ['xlsx'],
    );

    if (outputFile != null) {
      // Save the Excel file
      final file = File(outputFile);
      await file.writeAsBytes(excel.encode()!);

      // Show a success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Excel file saved at $outputFile')),
      );
    }
  }

  // Export to PDF
  Future<void> exportToPdf(List<SendRecord> records) async {
    // Create a PDF document
    final pdf = pw.Document();

    // Add a page to the PDF
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(level: 0, text: 'Send Report'),
              pw.TableHelper.fromTextArray(
                context: context,
                data: [
                  [
                    'Date',
                    'Truck Number',
                    'Code Number',
                    'Sender Name',
                    'Receiver Name',
                    'Receiver Country',
                    'Receiver City',
                    'Total Weight (kg)',
                    'Total Cost (EUR)'
                  ],
                  ...records.map((record) => [
                        record.date ?? '',
                        record.truckNumber ?? '',
                        record.codeNumber ?? '',
                        record.senderName ?? '',
                        record.receiverName ?? '',
                        record.receiverCountry ?? '',
                        record.receiverCity ?? '',
                        record.totalWeightKg?.toString() ?? '',
                        record.totalCostEuroCurrency?.toString() ?? '',
                      ]),
                ],
              ),
            ],
          );
        },
      ),
    );

    // Let the user choose where to save the file
    String? outputFile = await FilePicker.platform.saveFile(
      dialogTitle: 'Save PDF File',
      fileName: 'send_report.pdf',
      allowedExtensions: ['pdf'],
    );

    if (outputFile != null) {
      // Save the PDF file
      final file = File(outputFile);
      await file.writeAsBytes(await pdf.save());

      // Show a success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF file saved at $outputFile')),
      );
    }
  }
}
