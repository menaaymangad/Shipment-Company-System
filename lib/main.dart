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
import 'package:app/helper/shared_prefs_service.dart';
import 'package:app/helper/sql_helper.dart';
import 'package:app/pages/admin_pages/branches/branches_page.dart';
import 'package:app/pages/admin_pages/cities/cities_page.dart';
import 'package:app/pages/admin_pages/countries/countries_page.dart';
import 'package:app/pages/admin_pages/currencies/currencies_page.dart';
import 'package:app/pages/admin_pages/users/users_page.dart';
import 'package:app/pages/main_pages/admin_page.dart';

import 'package:app/pages/main_pages/login_page.dart';
import 'package:app/pages/main_pages/main_page.dart';
import 'package:app/pages/main_pages/report_page.dart';
import 'package:app/pages/main_pages/send_page/send.dart';
import 'package:app/pages/main_pages/setting/setting_page.dart';
import 'package:app/pages/reports_pages/eu_reports_page.dart';
import 'package:app/pages/reports_pages/overview_page.dart';
import 'package:app/pages/reports_pages/reports_page.dart';
import 'package:app/widgets/custom_scroll_behavior.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:path/path.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

void main() {
  // Add more robust error handling and logging
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await SharedPreferences.getInstance();
    await SharedPrefsService.initializeAdminCredentials();
    await windowManager.ensureInitialized();
    await windowManager.maximize();
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.top],
    );
    WindowOptions windowOptions = const WindowOptions(
      size: Size(1280, 720), // Default starting size
      minimumSize: Size(800, 600),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
      await windowManager.setMinimumSize(const Size(800, 600));
      await windowManager.maximize();
      await windowManager.setAspectRatio(16 / 9);
    });

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

      runApp(MyApp());
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
  MyApp({
    super.key,
  });
  final RouteObserver<ModalRoute> routeObserver = RouteObserver<ModalRoute>();
  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(1920, 1080),
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
          BlocProvider(create: (_) => CityFormCubit()),
          BlocProvider(create: (_) => CountryFormCubit()),
          BlocProvider(create: (_) => BranchFormCubit()),
          BlocProvider(create: (_) => CurrencyFormCubit()),
          BlocProvider(create: (_) => UserFormCubit()),
          BlocProvider(create: (_) => OverviewFormCubit()),
          BlocProvider(create: (_) => ReportsFormCubit()),
          BlocProvider(create: (_) => EUReportsFormCubit()),
          BlocProvider(
            create: (context) => SettingFormCubit(),
          ),
        ],
        child: MaterialApp(
          scrollBehavior: PermanentScrollBehavior(),
          debugShowCheckedModeBanner: false,
          title: 'Transport Company',
          theme: ThemeData(
            fontFamily: 'Poppins',
            // Set the default text style to bold
            textTheme: TextTheme(
              bodyLarge: TextStyle(fontWeight: FontWeight.bold),
              bodyMedium: TextStyle(fontWeight: FontWeight.bold),
              bodySmall: TextStyle(fontWeight: FontWeight.bold),
              titleLarge: TextStyle(fontWeight: FontWeight.bold),
              titleMedium: TextStyle(fontWeight: FontWeight.bold),
              titleSmall: TextStyle(fontWeight: FontWeight.bold),
              labelLarge: TextStyle(fontWeight: FontWeight.bold),
              labelMedium: TextStyle(fontWeight: FontWeight.bold),
              labelSmall: TextStyle(fontWeight: FontWeight.bold),
              headlineLarge: TextStyle(fontWeight: FontWeight.bold),
              headlineMedium: TextStyle(fontWeight: FontWeight.bold),
              headlineSmall: TextStyle(fontWeight: FontWeight.bold),
              displayLarge: TextStyle(fontWeight: FontWeight.bold),
              displayMedium: TextStyle(fontWeight: FontWeight.bold),
              displaySmall: TextStyle(fontWeight: FontWeight.bold),
            ),
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
          routes: {
            LoginPage.id: (context) => const LoginPage(),
            SendScreen.id: (context) => const SendScreen(),
            AdminPage.id: (context) => const AdminPage(),
            ReportPage.id: (context) => const ReportPage(),
            SettingPage.id: (context) => const SettingPage(),
            MainLayout.id: (context) => const MainLayout(),
            CitiesPage.id: (context) => const CitiesPage(),
            BranchesPage.id: (context) => const BranchesPage(),
          },
          initialRoute: LoginPage.id,
          navigatorObservers: [routeObserver],
        ),
      ),
    );
  }
}
