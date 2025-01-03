// reports_screen.dart
import 'package:app/pages/reports_pages/reports_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1.sw, // Screen width
      height: 1.sh, // Screen height
      padding: EdgeInsets.all(16.w),
      child: Column(
        children: [
          SizedBox(
            height: 0.3.sh, // 30% of screen height
            child: const StatsGridView(),
          ),
          SizedBox(height: 20.h),
          const Expanded(
            child: EUCountriesTable(),
          ),
        ],
      ),
    );
  }
}
