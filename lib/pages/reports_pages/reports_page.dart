import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:app/pages/reports_pages/reports_utils.dart';
import 'package:app/helper/send_db_helper.dart';
import 'package:app/models/send_model.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  // Dropdown values
  String? selectedOffice;
  String? selectedTruck;
  String? selectedEUCountry;
  String? selectedAgentCity;

  // Date picker values
  DateTime? selectedDate;

  // Lists to hold dropdown options
  List<String> officeNames = [];
  List<String> truckNumbers = [];
  List<String> euCountries = [];
  List<String> agentCities = [];

  // StatsCard values
  int totalCodes = 0;
  int totalBoxes = 0;
  int totalPallets = 0;
  double totalKG = 0.0;

  // EUCountriesTable data
  List<String> countries = [];
  Map<String, Map<String, dynamic>> countryTotals = {};


@override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _restoreFormData());
    _fetchDropdownData();
    _fetchStatsData();
    _fetchCountryData();
  }

  @override
  void deactivate() {
    _saveFormData();
    super.deactivate();
  }

  void _saveFormData() {
    final formData = {
      'selectedOffice': selectedOffice,
      'selectedTruck': selectedTruck,
      'selectedEUCountry': selectedEUCountry,
      'selectedAgentCity': selectedAgentCity,
      'selectedDate': selectedDate?.toIso8601String(),
    };
    context.read<ReportsFormCubit>().saveFormData(formData);
  }

  void _restoreFormData() {
    final formData = context.read<ReportsFormCubit>().state;
    setState(() {
      selectedOffice = formData['selectedOffice'];
      selectedTruck = formData['selectedTruck'];
      selectedEUCountry = formData['selectedEUCountry'];
      selectedAgentCity = formData['selectedAgentCity'];
      selectedDate = formData['selectedDate'] != null
          ? DateTime.parse(formData['selectedDate'])
          : null;
    });
  }

  Future<void> _fetchDropdownData() async {
    final dbHelper = SendRecordDatabaseHelper();
    officeNames = await dbHelper.getUniqueOfficeNames();
    truckNumbers = await dbHelper.getUniqueTruckNumbers();
    euCountries = await dbHelper.getUniqueEUCountries();
    agentCities = await dbHelper.getUniqueAgentCities();
    setState(() {});
  }

  Future<void> _fetchStatsData() async {
    final dbHelper = SendRecordDatabaseHelper();
    totalCodes = await dbHelper.getTotalCodes();
    totalBoxes = await dbHelper.getTotalBoxes();
    totalPallets = await dbHelper.getTotalPallets();
    totalKG = await dbHelper.getTotalKG();
    setState(() {});
  }

  Future<void> _fetchCountryData() async {
    final dbHelper = SendRecordDatabaseHelper();
    countries = await dbHelper.getUniqueEUCountries();

    for (var country in countries) {
      final totals = await dbHelper.getCountryTotals(country);
      countryTotals[country] = totals;
    }

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
    return Container(
      width: 1.sw,
      height: 1.sh,
      padding: EdgeInsets.all(16.w),
      child: Column(
        children: [
          SizedBox(
            height: 0.3.sh,
            child: statsGridView(),
          ),
          SizedBox(height: 20.h),
          Expanded(
            child: euCountriesTable(),
          ),
        ],
      ),
    );
  }

  Widget euCountriesTable() {
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
            DataColumn(label: Text('Total Cash in')),
            DataColumn(label: Text('Total Commissions')),
            DataColumn(label: Text('Total Paid To company')),
            DataColumn(label: Text('Total Paid in Europe')),
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
                DataCell(
                    Text(totals['totalCashIn']?.toStringAsFixed(2) ?? '0.00')),
                DataCell(Text(
                    totals['totalCommissions']?.toStringAsFixed(2) ?? '0.00')),
                DataCell(Text(
                    totals['totalPaidToCompany']?.toStringAsFixed(2) ??
                        '0.00')),
                DataCell(Text(
                    totals['totalPaidInEurope']?.toStringAsFixed(2) ?? '0.00')),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget statsGridView() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      mainAxisSpacing: 16.w,
      crossAxisSpacing: 16.w,
      childAspectRatio: 2,
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
      ],
    );
  }
}
class ReportsFormCubit extends Cubit<Map<String, dynamic>> {
  ReportsFormCubit() : super({});

  void saveFormData(Map<String, dynamic> formData) => emit(formData);
  void clearFormData() => emit({});
}
