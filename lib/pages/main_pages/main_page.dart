import 'package:app/pages/main_pages/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'admin_page.dart';
import 'report_page.dart';
import 'send_page/send.dart';
import 'setting/setting_page.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});
  static String id = 'main_layout';

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int selectedIndex = 0;
  bool _isExpanded = true;
  Widget? customPage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: Row(
        children: [
          _buildNavigationRail(),
          Expanded(child: _buildMainContent()),
        ],
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      toolbarHeight: 120.h,
      backgroundColor: Colors.white,
      elevation: 4, // Add elevation for a 3D effect
      shadowColor: Colors.black.withAlpha(40), // Shadow color
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(20), // Rounded bottom corners
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.menu, color: Colors.black),
        onPressed: () {
          setState(() {
            _isExpanded = !_isExpanded;
          });
        },
      ),
      title: Row(
        children: [
          Container(
            height: 77.h,
            padding: const EdgeInsets.symmetric(horizontal: 5),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.blue.shade700,
                  Colors.blue.shade400
                ], // Gradient background
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Center(
              child: Text(
                'EUKnet',
                style: TextStyle(
                  color: Colors.white, // White text for better contrast
                  fontWeight: FontWeight.bold,
                  fontSize: 40.sp,
                ),
              ),
            ),
          ),
          Text(
            ' TRANSPORT COMPANY',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 40.sp,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.logout, color: Colors.black), // Logout icon
          onPressed: () {
            // Add logout functionality here
            _logout(context);
          },
        ),
      ],
    );
  }

  void _logout(BuildContext context) {
    // Show a confirmation dialog before logging out
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // Cancel
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Perform logout logic here
              Navigator.pop(context); // Close the dialog
              // Navigate to the login screen or clear user session
              Navigator.pushReplacementNamed(context, LoginPage.id); // Example
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationRail() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: _isExpanded ? 400.w : 100.w,
      child: NavigationRail(
        backgroundColor: const Color(0xFFF5F7FA),
        selectedIndex: selectedIndex,
        onDestinationSelected: (int index) {
          setState(() {
            selectedIndex = index;
            customPage = null;
          });
        },
        extended: MediaQuery.sizeOf(context).width < 1000 ? false : _isExpanded,
        leading: Padding(
          padding: EdgeInsets.symmetric(vertical: 8.h),
          child: IconButton(
            icon: Icon(
              _isExpanded ? Icons.chevron_left : Icons.chevron_right,
              color: const Color(0xFF2D3748),
            ),
            onPressed: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
          ),
        ),
        destinations: _buildNavDestinations(),
      ),
    );
  }

  List<NavigationRailDestination> _buildNavDestinations() {
    return [
      _buildNavDestination(Icons.dashboard_outlined, 'Dashboard'),
      _buildNavDestination(Icons.send_outlined, 'Send'),
      _buildNavDestination(Icons.assessment_outlined, 'Reports'),
      _buildNavDestination(Icons.admin_panel_settings_outlined, 'Admin'),
      _buildNavDestination(Icons.settings_outlined, 'Settings'),
    ];
  }

  NavigationRailDestination _buildNavDestination(IconData icon, String label) {
    return NavigationRailDestination(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      icon: Icon(
        icon,
        size: 50.sp,
        color: const Color(0xFF64748B),
      ),
      selectedIcon: Icon(
        icon,
        size: 50.sp,
        color: const Color(0xFF3B82F6),
      ),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 28.sp,
          color: const Color(0xFF2D3748),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    if (customPage != null) {
      return customPage!;
    }

    switch (selectedIndex) {
      case 0:
        return _buildHomePage();
      case 1:
        return const SendScreen();
      case 2:
        return const ReportPage();
      case 3:
        return const AdminPage();
      case 4:
        return const SettingPage();
      default:
        return _buildHomePage();
    }
  }

  Widget _buildHomePage() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          SvgPicture.asset(
            'assets/icons/EUKnet Logo (1).svg',
            width: MediaQuery.sizeOf(context).width * 0.1,
            height: MediaQuery.sizeOf(context).height * 0.1,
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 30,
                margin: const EdgeInsets.only(
                  left: 10,
                  right: 10,
                ),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xff236bc9),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: const Padding(
                  padding: EdgeInsets.only(
                    left: 5.0,
                    right: 5,
                  ),
                  child: Text(
                    'EUKnet',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              const Text(
                ' TRANSPORT COMPANY',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: _buildDashboardButtons(),
          ),
          const Spacer(),
          Text(
            'Baghdad Office',
            style: TextStyle(
              fontSize: 55.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  List<Widget> _buildDashboardButtons() {
    final buttons = [
      _buildDashboardButton('Send', Icons.send, Colors.blue, () {
        setState(() {
          customPage = const SendScreen();
        });
      }),
      _buildDashboardButton('Reports', Icons.bar_chart, Colors.pink, () {
        setState(() {
          selectedIndex = 2;
          customPage = null;
        });
      }),
      _buildDashboardButton('Admin', Icons.admin_panel_settings, Colors.green,
          () {
        setState(() {
          selectedIndex = 3;
          customPage = null;
        });
      }),
      _buildDashboardButton('Settings', Icons.settings, Colors.purple, () {
        setState(() {
          selectedIndex = 4;
          customPage = null;
        });
      }),
    ];

    return buttons;
  }

  Widget _buildDashboardButton(
      String label, IconData icon, Color color, VoidCallback onPressed) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 50.w),
      child: InkWell(
        onTap: onPressed,
        child: Container(
          height: 300.h,
          width: 300.w,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(60).r,
              bottomRight: const Radius.circular(60).r,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 80.sp, color: Colors.white),
              SizedBox(height: 10.h),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 40.sp,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
