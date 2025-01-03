import 'package:app/pages/reports_pages/reports_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class OverviewScreen extends StatelessWidget {
  const OverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1.sw,
      height: 1.sh,
      padding: EdgeInsets.all(16.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ReportCard(
              title: 'Make Report',
              children: _buildMakeReportFields(),
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: ReportCard(
              title: 'Daily Report',
              children: _buildDailyReportFields(),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildMakeReportFields() {
    return [
      const CustomDropdown(label: 'Office Name'),
      const CustomDropdown(label: 'From Truck No.'),
      const CustomDropdown(label: 'To Truck No.'),
      const CustomDropdown(label: 'EU Country'),
      const CustomDropdown(label: 'Agent City'),
      const CustomDatePicker(label: 'Date'),
      Spacer(),
      ButtonRow(
        buttons: _buildReportButtons(),
      ),
    ];
  }

  List<Widget> _buildDailyReportFields() {
    return [
      const CustomDropdown(label: 'Office Name'),
      const CustomTextField(label: 'Daily Codes'),
      const CustomTextField(label: 'Daily Pallet'),
      const CustomTextField(label: 'Daily Boxes'),
      const CustomTextField(label: 'Daily KG'),
      const CustomTextField(label: 'Daily Cash in'),
      const CustomTextField(label: 'Daily Commission'),
      const CustomDatePicker(label: 'Date'),
      Spacer(),
      ButtonRow(
        buttons: _buildReportButtons(),
      ),
    ];
  }

  List<Widget> _buildReportButtons() {
    return [
      CustomButton(
        text: 'Excel Report',
        color: Colors.green,
        onPressed: () {},
      ),
      CustomButton(
        text: 'PDF Report',
        color: Colors.purple,
        onPressed: () {},
      ),
    ];
  }
}
