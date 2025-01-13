import 'dart:async';
import 'dart:io';

import 'package:app/cubits/brach_cubit/branch_cubit.dart';
import 'package:app/cubits/cities_cubit/cities_cubit.dart';
import 'package:app/cubits/countries_cubit/countries_cubit.dart';
import 'package:app/cubits/currencies_cubit/currencies_cubit.dart';
import 'package:app/cubits/login_cubit/login_cubit_cubit.dart';
import 'package:app/cubits/send_cubit/send_cubit.dart';
import 'package:app/cubits/user_cubit/user_cubit.dart';
import 'package:app/helper/send_db_helper.dart';
import 'package:app/helper/sql_helper.dart';
import 'package:app/pages/admin_pages/cities/cities_page.dart';
import 'package:app/pages/main_pages/admin_page.dart';

import 'package:app/pages/main_pages/login_page.dart';
import 'package:app/pages/main_pages/main_page.dart';
import 'package:app/pages/main_pages/report_page.dart';
import 'package:app/pages/main_pages/send_page/send.dart';
import 'package:app/pages/main_pages/setting/setting_page.dart';
import 'package:app/widgets/theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:path/path.dart';
import 'package:provider/provider.dart';

void main() {
  // Add more robust error handling and logging
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Configure error handling
    FlutterError.onError = (FlutterErrorDetails details) {
      if (kDebugMode) {
        print('Unhandled Flutter framework error: ${details.exception}');
      }
      if (kDebugMode) {
        print('Stack trace: ${details.stack}');
      }
    };

    try {
      // Initialize database before running the app
      await _initializeDatabase();

      runApp(const MyApp());
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Critical app initialization error: $e');
      }
      if (kDebugMode) {
        print('Stack trace: $stackTrace');
      }

      // Optionally, run a minimal error app
      runApp(ErrorApp(error: e));
    }
  }, (error, stackTrace) {
    if (kDebugMode) {
      print('Unhandled zone error: $error');
    }
    if (kDebugMode) {
      print('Stack trace: $stackTrace');
    }
  });
}

// Separate database initialization
Future<void> _initializeDatabase() async {
  try {
    final databaseHelper = DatabaseHelper();

    // Initialize database
    await databaseHelper.ensureInitialized();

    // Additional error checking for Windows
    if (Platform.isWindows) {
      final exePath = Platform.resolvedExecutable;
      final appDir = dirname(exePath);
      final dllPath = join(appDir, 'sqlite3.dll');

      if (!File(dllPath).existsSync()) {
        throw Exception('sqlite3.dll not found at: $dllPath');
      }
    }

    await databaseHelper.verifyDatabaseStructure();

    if (kDebugMode) {
      print('Database initialized successfully');
    }
  } catch (e, stackTrace) {
    if (kDebugMode) {
      print('Database initialization failed: $e');
      print('Stack trace: $stackTrace');
    }
    rethrow;
  }
}

// Add an error fallback app
class ErrorApp extends StatelessWidget {
  final Object error;

  const ErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('App Initialization Error'),
          backgroundColor: Colors.red,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 100),
                const SizedBox(height: 20),
                Text(
                  'Failed to initialize the app',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  'Error: $error',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(3072, 1727),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) => MultiBlocProvider(
        providers: [
          BlocProvider<BranchCubit>(
            create: (context) => BranchCubit(DatabaseHelper()),
          ),
          BlocProvider<CityCubit>(
            create: (context) => CityCubit(DatabaseHelper()),
          ),
          BlocProvider<CountryCubit>(
            create: (context) => CountryCubit(DatabaseHelper()),
          ),
          BlocProvider<CurrencyCubit>(
            create: (context) => CurrencyCubit(DatabaseHelper()),
          ),
          BlocProvider<UserCubit>(
            create: (context) => UserCubit(),
          ),
          BlocProvider<AuthCubit>(
            create: (context) => AuthCubit(UserCubit(), DatabaseHelper()),
          ),
          BlocProvider<SendRecordCubit>(
            create: (context) => SendRecordCubit(SendRecordDatabaseHelper()),
          ),
        ],
        child: ChangeNotifierProvider(
          create: (_) => ThemeProvider(), // Add ThemeProvider
          child: Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return MaterialApp(
                debugShowCheckedModeBanner: false,
                title: 'Transport Company',
                theme: ThemeData(
                  fontFamily: 'Poppins',
                  // Add more theme customizations
                  primarySwatch: Colors.blue,
                  appBarTheme: const AppBarTheme(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  elevatedButtonTheme: ElevatedButtonThemeData(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                darkTheme: ThemeData.dark().copyWith(
                  appBarTheme: const AppBarTheme(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                  ),
                  elevatedButtonTheme: ElevatedButtonThemeData(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                themeMode: themeProvider.themeMode,
                // Add home property for more reliable routing
                home: const LoginPage(),
                routes: {
                  LoginPage.id: (context) => const LoginPage(),
                  SendScreen.id: (context) => const SendScreen(),
                  AdminPage.id: (context) => const AdminPage(),
                  ReportPage.id: (context) => const ReportPage(),
                  SettingPage.id: (context) => const SettingPage(),
                  MainLayout.id: (context) => const MainLayout(),
                  CitiesPage.id: (context) => const CitiesPage(),
                },
                // Add navigation observer for analytics or logging
                navigatorObservers: [
                  RouteObserver(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
