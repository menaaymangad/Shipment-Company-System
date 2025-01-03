// eu_report_screen.dart
import 'package:app/pages/reports_pages/reports_utils.dart';
import 'package:flutter/material.dart';

class EUReportScreen extends StatelessWidget {
  const EUReportScreen({super.key});

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
                const CustomDropdown(label: 'Office Name'),
                const CustomDropdown(label: 'Truck No.'),
                const CustomDropdown(label: 'EU Country'),
                const CustomDropdown(label: 'Agent City'),
                const CustomDatePicker(label: 'Date'),
                ButtonRow(
                  buttons: [
                    CustomButton(
                      text: 'Excel Report',
                      color: Colors.green,
                      onPressed: () {},
                    ),
                    CustomButton(
                      text: 'Germany Post',
                      color: Colors.blue,
                      onPressed: () {},
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
                  value: true,
                  onChanged: (value) {},
                ),
                CheckboxListTile(
                  title: const Text('Get All Agents Accounts'),
                  value: false,
                  onChanged: (value) {},
                ),
                CheckboxListTile(
                  title: const Text('Make Complete Shipment'),
                  value: true,
                  onChanged: (value) {},
                ),
                CheckboxListTile(
                  title: const Text('Print Preview'),
                  value: true,
                  onChanged: (value) {},
                ),
                const CustomTextField(label: 'EU Truck No.'),
                const CustomDatePicker(label: 'Dep. Date KU'),
                const CustomDatePicker(label: 'Arrival Date NL'),
                ButtonRow(
                  buttons: [
                    CustomButton(
                      text: 'Excel Report',
                      color: Colors.green,
                      onPressed: () {},
                    ),
                    CustomButton(
                      text: 'PDF Report',
                      color: Colors.blue,
                      onPressed: () {},
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
}
