import 'package:app/helper/shared_prefs_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../admin_pages/branches/branches_page.dart';
import '../admin_pages/cities/cities_page.dart';
import '../admin_pages/countries/countries_page.dart';
import '../admin_pages/currencies/currencies_page.dart';
import '../admin_pages/users/users_page.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});
  static String id = 'admin';

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  int _selectedIndex = 0;

  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

 Future<void> _checkAdminStatus() async {
    try {
      _isAdmin = await SharedPrefsService.isUserAdmin();
      debugPrint('Admin status: $_isAdmin');
      setState(() {});
    } catch (e) {
      debugPrint('Error checking admin status: $e');
    }
  }


  final List<String> _tabs = [
    
    'Branches',
    'Countries',
    'Cities',
    'Currencies',
    'Users',
  ];

@override
  Widget build(BuildContext context) {
    if (!_isAdmin) {
      return const Center(
        child: Text('You are not authorized to access the Admin page.'),
      );
    }
    return Column(
      children: [
        // Top Navigation
        Container(
          color: Colors.white,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _tabs.asMap().entries.map((entry) {
                return Padding(
                  padding: EdgeInsets.all(8.r),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedIndex == entry.key
                          ? Colors.blue[800]
                          : Colors.blue[200],
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      setState(() {
                        _selectedIndex = entry.key;
                      });
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _getIconForTab(entry.value),
                          size: 20,
                        ),
                        SizedBox(width: 16.w),
                        Text(entry.value),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        // Main Content
        Expanded(child: _buildMainContent())
      ],
    );
  }
  Widget _buildMainContent() {
    try {
      switch (_selectedIndex) {
      
        case 0:
          return const BranchesPage();
        case 1:
          return const CountriesPage();
        case 2:
          return const CitiesPage();
        case 3:
          return const CurrenciesPage();
        case 4:
          return const UsersPage();
        default:
          return const BranchesPage();
      }
    } catch (e) {
      return Center(child: Text('Error loading page: $e'));
    }
  }


  IconData _getIconForTab(String tab) {
    switch (tab) {
     
      case 'Branches':
        return Icons.business;
      case 'Countries':
        return Icons.public;
      case 'Cities':
        return Icons.location_city;
      case 'Currencies':
        return Icons.attach_money;
      case 'Users':
        return Icons.person;
      default:
        return Icons.circle;
    }
  }
}
