// main_screen.dart
import 'package:app/pages/reports_pages/eu_reports_page.dart';
import 'package:app/pages/reports_pages/overview_page.dart';
import 'package:app/pages/reports_pages/reports_page.dart';
import 'package:app/pages/reports_pages/reports_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const OverviewScreen(),
    const ReportsScreen(),
    const EUReportScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          CustomAppBar(
            currentIndex: _selectedIndex, // Updated parameter name
            onTabSelected: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
          ),
          SizedBox(height: 16.h), // Added spacing
          Expanded(
            child: _screens[_selectedIndex],
          ),
        ],
      ),
    );
  }
}
