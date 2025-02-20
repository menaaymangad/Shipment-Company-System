import 'dart:typed_data';

import 'package:app/helper/send_db_helper.dart';
import 'package:app/pages/reports_pages/reports_utils.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pdf/pdf.dart';

import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  // Filter values
  String? selectedYear;
  String? selectedTruckNumber;

  // Stats values
  int totalCodes = 0;
  int totalBoxes = 0;
  int totalPallets = 0;
  double totalKG = 0.0;
  int totalTrucks = 0;
  double totalCashIn = 0.0;
  double totalPayInEurope = 0.0;

  // Table data
  List<String> countries = [];
  Map<String, Map<String, dynamic>> countryTotals = {};

  Future<void> _fetchStatsData() async {
    final dbHelper = SendRecordDatabaseHelper();

    // Fetch stats based on filters
    final stats = await dbHelper.getFilteredStats(
      year: selectedYear,
      truckNumber: selectedTruckNumber,
    );

    setState(() {
      totalCodes = stats['totalCodes'] ?? 0;
      totalBoxes = stats['totalBoxes'] ?? 0;
      totalPallets = stats['totalPallets'] ?? 0;
      totalKG = stats['totalKG'] ?? 0.0;
      totalTrucks = stats['totalTrucks'] ?? 0;
      totalCashIn = stats['totalCashIn'] ?? 0.0;
      totalPayInEurope = stats['totalPayInEurope'] ?? 0.0;

      countries = stats['countries'] ?? [];
      countryTotals = stats['countryTotals'] ?? {};
    });
  }

  Future<void> _exportToExcel() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Text('Preparing Excel export...'),
          ],
        ),
      ),
    );

    try {
      if (countries.isEmpty) throw Exception('No data to export');

      final excel = Excel.createExcel();
      final sheet = excel['Reports'];

      // Add headers
      const headers = [
        'Country',
        'Total Codes',
        'Total Boxes',
        'Total Pallets',
        'Total KG',
        'Total Trucks',
        'Total Cash In',
        'Total Pay in Europe'
      ];

      for (var i = 0; i < headers.length; i++) {
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
            .value = TextCellValue(headers[i]);
      }

      // Add data rows
      var rowIndex = 1;
      for (final country in countries) {
        final data = countryTotals[country] ?? {};
        final rowData = [
          country,
          data['totalCodes'] ?? 0,
          data['totalBoxes'] ?? 0,
          data['totalPallets'] ?? 0,
          data['totalKG'] ?? 0.0,
          data['totalTrucks'] ?? 0,
          data['totalCashIn'] ?? 0.0,
          data['totalPayInEurope'] ?? 0.0,
        ];

        for (var colIndex = 0; colIndex < rowData.length; colIndex++) {
          final value = rowData[colIndex];
          final cell = sheet.cell(CellIndex.indexByColumnRow(
            columnIndex: colIndex,
            rowIndex: rowIndex,
          ));

          if (value is int) {
            cell.value = IntCellValue(value);
          } else if (value is double) {
            cell.value = DoubleCellValue(value);
          } else {
            cell.value = TextCellValue(value.toString());
          }
        }
        rowIndex++;
      }

      // Get file bytes
      final bytes = Uint8List.fromList(excel.encode()!);

      // Let user choose location
      final result = await FileSaver.instance.saveAs(
        name: 'reports_${DateTime.now().toString().replaceAll(':', '-')}',
        bytes: bytes,
        ext: 'xlsx',
        mimeType: MimeType.microsoftExcel,
      );

      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content:
              Text(result != null ? 'Exported to $result' : 'Export canceled'),
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Excel export failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      Navigator.of(context).pop(); // Close loading dialog
    }
  }

  Future<void> _exportToPDF() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Text('Preparing PDF export...'),
          ],
        ),
      ),
    );

    try {
      if (countries.isEmpty) throw Exception('No data to export');

      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(20),
          build: (context) => pw.Column(
            children: [
              pw.Header(
                level: 0,
                child: pw.Text('Transportation Report',
                    style: const pw.TextStyle(fontSize: 24)),
              ),
              pw.SizedBox(height: 20),
              pw.Expanded(
                child: pw.TableHelper.fromTextArray(
                  border: pw.TableBorder.all(),
                  headerStyle: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                  ),
                  cellStyle: const pw.TextStyle(
                    fontSize: 10,
                  ),
                  headers: [
                    'Country',
                    'Total Codes',
                    'Total Boxes',
                    'Total Pallets',
                    'Total KG',
                    'Total Trucks',
                    'Total Cash In',
                    'Total Pay in Europe'
                  ],
                  data: countries.map((country) {
                    final data = countryTotals[country] ?? {};
                    return [
                      country,
                      (data['totalCodes'] ?? 0).toString(),
                      (data['totalBoxes'] ?? 0).toString(),
                      (data['totalPallets'] ?? 0).toString(),
                      (data['totalKG']?.toStringAsFixed(2) ?? '0.00'),
                      (data['totalTrucks'] ?? 0).toString(),
                      (data['totalCashIn']?.toStringAsFixed(2) ?? '0.00'),
                      (data['totalPayInEurope']?.toStringAsFixed(2) ?? '0.00'),
                    ];
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      );

      // Get PDF bytes
      final bytes = await pdf.save();

      // Let user choose location
      final result = await FileSaver.instance.saveAs(
        name: 'reports_${DateTime.now().toString().replaceAll(':', '-')}',
        bytes: bytes,
        ext: 'pdf',
        mimeType: MimeType.pdf,
      );

      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content:
              Text(result != null ? 'Exported to $result' : 'Export canceled'),
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('PDF export failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      Navigator.of(context).pop(); // Close loading dialog
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1.sw,
      height: 1.sh,
      padding: EdgeInsets.all(8.r),
      child: Column(
        children: [
          _buildFilters(),
          SizedBox(height: 8.h),
          SizedBox(
            height: 0.35.sh,
            child: _buildStatsGrid(),
          ),
          SizedBox(height: 8.h),
          _buildExportButtons(),
          SizedBox(height: 8.h),
          Expanded(
            child: _buildCountryTable(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        FutureBuilder<List<String>>(
          future: SendRecordDatabaseHelper().getAvailableYears(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const CircularProgressIndicator();
            }

            final years = snapshot.data ?? [];
            // Ensure selectedYear is in the list of available years
            if (!years.contains(selectedYear)) {
              selectedYear = years.isNotEmpty ? years.first : null;
            }

            return SizedBox(
              width: 200.w,
              child: DropdownButtonFormField<String>(
                value: selectedYear,
                decoration: const InputDecoration(labelText: 'Year'),
                items: years.map((year) {
                  return DropdownMenuItem(
                    value: year,
                    child: Text(year),
                  );
                }).toList(),
                onChanged: (value) async {
                  setState(() {
                    selectedYear = value;
                    selectedTruckNumber = null; // Reset truck selection
                  });
                  await _fetchStatsData();
                },
              ),
            );
          },
        ),
        SizedBox(width: 16.w),
        FutureBuilder<List<String>>(
          future: selectedYear != null
              ? SendRecordDatabaseHelper().getTruckNumbersByYear(selectedYear!)
              : Future.value([]),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const CircularProgressIndicator();
            }

            final trucks = snapshot.data ?? [];
            // Ensure selectedTruckNumber is in the list of available trucks
            if (!trucks.contains(selectedTruckNumber)) {
              selectedTruckNumber = trucks.isNotEmpty ? trucks.first : null;
            }

            return SizedBox(
              width: 200.w,
              child: DropdownButtonFormField<String>(
                value: selectedTruckNumber,
                decoration: const InputDecoration(labelText: 'Truck Number'),
                items: trucks.map((truck) {
                  return DropdownMenuItem(
                    value: truck,
                    child: Text(truck),
                  );
                }).toList(),
                onChanged: trucks.isEmpty
                    ? null
                    : (value) async {
                        setState(() {
                          selectedTruckNumber = value;
                        });
                        await _fetchStatsData();
                      },
              ),
            );
          },
        ),
      ],
    );
  }

  // Also update the initState method to properly initialize the filters
  @override
  void initState() {
    super.initState();
    // Initialize filters asynchronously
    _initializeFilters();
    _fetchStatsData();
  }

  Future<void> _initializeFilters() async {
    final dbHelper = SendRecordDatabaseHelper();
    final years = await dbHelper.getAvailableYears();

    if (years.isNotEmpty) {
      final year = years.first;
      final trucks = await dbHelper.getTruckNumbersByYear(year);

      setState(() {
        selectedYear = year;
        selectedTruckNumber = trucks.isNotEmpty ? trucks.first : null;
      });
    }
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 4,
      mainAxisSpacing: 2.w,
      crossAxisSpacing: 2.w,
      childAspectRatio: 2.5,
      children: [
        StatsCard(
          value: totalCodes.toString(),
          label: 'Total Codes',
          color: Colors.purple,
        ),
        StatsCard(
          value: totalBoxes.toString(),
          label: 'Total Boxes',
          color: Colors.cyan,
        ),
        StatsCard(
          value: totalPallets.toString(),
          label: 'Total Pallets',
          color: Colors.orange,
        ),
        StatsCard(
          value: totalKG.toStringAsFixed(2),
          label: 'Total KG',
          color: Colors.blue,
        ),
        StatsCard(
          value: totalTrucks.toString(),
          label: 'Total Trucks',
          color: Colors.green,
        ),
        StatsCard(
          value: totalCashIn.toStringAsFixed(2),
          label: 'Total Cash In',
          color: Colors.red,
        ),
        StatsCard(
          value: totalPayInEurope.toStringAsFixed(2),
          label: 'Total Pay in Europe',
          color: Colors.brown,
        ),
      ],
    );
  }

  Widget _buildExportButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        ElevatedButton.icon(
          icon: const Icon(Icons.file_download),
          label: const Text('Export to Excel'),
          onPressed: _exportToExcel,
        ),
        SizedBox(width: 8.w),
        ElevatedButton.icon(
          icon: const Icon(Icons.picture_as_pdf),
          label: const Text('Export to PDF'),
          onPressed: _exportToPDF,
        ),
      ],
    );
  }

  Widget _buildCountryTable() {
    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Country')),
            DataColumn(label: Text('Total Codes')),
            DataColumn(label: Text('Total Boxes')),
            DataColumn(label: Text('Total Pallets')),
            DataColumn(label: Text('Total KG')),
            DataColumn(label: Text('Total Trucks')),
            DataColumn(label: Text('Total Cash In')),
            DataColumn(label: Text('Total Pay in Europe')),
          ],
          rows: countries.map((country) {
            final totals = countryTotals[country] ?? {};
            return DataRow(
              cells: [
                DataCell(Text(country)),
                DataCell(Text(totals['totalCodes']?.toString() ?? '0')),
                DataCell(Text(totals['totalBoxes']?.toString() ?? '0')),
                DataCell(Text(totals['totalPallets']?.toString() ?? '0')),
                DataCell(Text(totals['totalKG']?.toStringAsFixed(2) ?? '0.00')),
                DataCell(Text(totals['totalTrucks']?.toString() ?? '0')),
                DataCell(
                    Text(totals['totalCashIn']?.toStringAsFixed(2) ?? '0.00')),
                DataCell(Text(
                    totals['totalPayInEurope']?.toStringAsFixed(2) ?? '0.00')),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
