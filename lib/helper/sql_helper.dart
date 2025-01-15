import 'dart:async';
import 'dart:ffi';
import 'dart:io';

import 'package:app/models/country_model.dart';
import 'package:app/models/currency_model.dart';
import 'package:app/models/user_model.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;
  static bool _initialized = false;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<void> ensureInitialized() async {
    if (_initialized) return;

    try {
      // Get the executable directory
      final exePath = Platform.resolvedExecutable;
      final appDir = dirname(exePath);

      // In release mode, look for sqlite3.dll in the same directory as the exe
      if (Platform.isWindows) {
        // Set the database factory
        sqfliteFfiInit();

        // Specify the path to look for sqlite3.dll
        final dllPath = join(appDir, 'sqlite3.dll');

        // Load the DLL explicitly
        DynamicLibrary.open(dllPath);
      }

      databaseFactory = databaseFactoryFfi;
      _initialized = true;
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing database factory: $e');
      }
      rethrow;
    }
  }

  Future<Database> get database async {
    if (_database != null) return _database!;

    await ensureInitialized();
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String dbPath;
    if (Platform.isWindows) {
      // Use LOCALAPPDATA for storing app-specific data
      final appDataPath = Platform.environment['LOCALAPPDATA']!;
      dbPath =
          join(appDataPath, 'EuknetTransport', 'data', 'euknet_transport.db');

      // Ensure the data directory exists
      final directory = Directory(dirname(dbPath));
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
    } else {
      // Use default documents path for other platforms
      final documentsPath = await getDatabasesPath();
      dbPath = join(documentsPath, 'euknet_transport.db');
    }

    if (kDebugMode) {
      print('Opening database at: $dbPath');
    }

    return await databaseFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: 1, // Increment this version
        onCreate: createTables,
        onUpgrade: _onUpgrade,
        onOpen: _onOpen,
      ),
    );
  }

// Add this helper method to DatabaseHelper class
  // In sql_helper.dart
  Future<void> resetDatabase() async {
    try {
      // Close existing connections first
      await DatabaseHelper.closeDatabase();

      // Get correct database path using same logic as _initDatabase()
      String dbPath;
      if (Platform.isWindows) {
        final appDataPath = Platform.environment['LOCALAPPDATA']!;
        dbPath =
            join(appDataPath, 'EuknetTransport', 'data', 'euknet_transport.db');
      } else {
        final documentsPath = await getDatabasesPath();
        dbPath = join(documentsPath, 'euknet_transport.db');
      }

      // Delete existing database file
      final file = File(dbPath);
      if (await file.exists()) {
        await file.delete();
      }

      // Reset instance variables
      _database = null;
      _initialized = false;

      // Reinitialize database with tables
      final db = await database; // This will trigger _initDatabase()
      await createTables(db, 1); // Recreate all tables
    } catch (e) {
      if (kDebugMode) {
        print('Error resetting database: $e');
      }
      rethrow;
    }
  }

  Future<void> _onOpen(Database db) async {
    try {
      // Verify table exists
      final tableExists = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='users'");

      if (tableExists.isEmpty) {
        if (kDebugMode) {
          print('Users table does not exist. Recreating tables.');
        }
        await createTables(db, 3);
        return;
      }

      // Check user count
      final List<Map<String, dynamic>> result =
          await db.rawQuery('SELECT COUNT(*) as count FROM users');
      final int userCount = result[0]['count'] ?? 0;

      if (userCount == 0) {
        if (kDebugMode) {
          print('No users found. Inserting default admin user.');
        }
        await _insertDefaultAdminUser(db);
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Error in onOpen: $e');
      }
      if (kDebugMode) {
        print('Stack trace: $stackTrace');
      }

      // Attempt to recreate tables if there's a critical error
      try {
        await createTables(db, 3);
      } catch (recreateError) {
        if (kDebugMode) {
          print('Failed to recreate tables: $recreateError');
        }
        rethrow;
      }
    }
  }

  Future<void> verifyDatabaseStructure() async {
    final db = await database;

    // Check if tables exist
    final tables = await db
        .query('sqlite_master', where: 'type = ?', whereArgs: ['table']);

    if (kDebugMode) {
      print('Existing tables: ${tables.map((t) => t['name']).toList()}');
    }

    // Verify users table structure
    final usersTable = tables.firstWhere(
      (table) => table['name'] == 'users',
      orElse: () => {},
    );

    if (usersTable.isEmpty) {
      if (kDebugMode) {
        print('Users table not found - recreating...');
      }
      await createTables(db, 3); // Current version is 3
    }

    // Verify admin user exists
    final adminUser =
        await db.query('users', where: 'userName = ?', whereArgs: ['admin']);

    if (adminUser.isEmpty) {
      if (kDebugMode) {
        print('Admin user not found - creating...');
      }
      await _insertDefaultAdminUser(db);
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE send_records ADD COLUMN newColumn TEXT;');
    }
  }

  Future<void> createTables(Database db, int version) async {
    try {
      // Create all tables first using batch
      Batch batch = db.batch();

      // Branches table
      batch.execute('''
      CREATE TABLE IF NOT EXISTS branches (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        branchName TEXT NOT NULL,
        contactPersonName TEXT NOT NULL,
        branchCompany TEXT NOT NULL,
        phoneNo1 TEXT NOT NULL,
        phoneNo2 TEXT,
        address TEXT NOT NULL,
        city TEXT NOT NULL,
        charactersPrefix TEXT NOT NULL,
        yearPrefix TEXT NOT NULL,
        numberOfDigits INTEGER NOT NULL,
        codeStyle TEXT NOT NULL,
        invoiceLanguage TEXT NOT NULL
      )
    ''');

      // Countries table
      batch.execute('''
      CREATE TABLE IF NOT EXISTS countries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        countryName TEXT NOT NULL,
        alpha2Code TEXT NOT NULL,
        zipCodeDigit1 TEXT,
        zipCodeDigit2 TEXT,
        zipCodeText TEXT,
        currency TEXT NOT NULL,
        currencyAgainstIQD REAL NOT NULL,
        hasAgent INTEGER NOT NULL,
        maxWeightKG REAL,
        flagBoxLabel TEXT,
        postBoxLabel TEXT
      )
    ''');

      // Cities table
      batch.execute('''
  CREATE TABLE IF NOT EXISTS cities (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    cityName TEXT NOT NULL,
    country TEXT NOT NULL,
    hasAgent INTEGER NOT NULL,
    isPost INTEGER NOT NULL DEFAULT 0, 
    doorToDoorPrice REAL NOT NULL,
    priceKg REAL NOT NULL DEFAULT 0,
    minimumPrice REAL NOT NULL DEFAULT 0,
    boxPrice REAL NOT NULL DEFAULT 0
  )
''');
      // Currencies table
      batch.execute('''
      CREATE TABLE IF NOT EXISTS currencies (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        currencyName TEXT NOT NULL UNIQUE,
        currencyAgainst1IraqiDinar REAL NOT NULL DEFAULT 0
      )
    ''');

      // Users table - ENSURE THIS IS THE LAST TABLE CREATION
      batch.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userName TEXT NOT NULL,
        branchName TEXT NOT NULL,
        authorization TEXT NOT NULL,
        allowLogin INTEGER NOT NULL,
        password TEXT NOT NULL
      )
    ''');
      if (kDebugMode) {
        print('Creating goods_descriptions table...');
      }
      batch.execute('''
      CREATE TABLE IF NOT EXISTS goods_descriptions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        description_en TEXT NOT NULL,
        description_ar TEXT NOT NULL,
        
        UNIQUE(description_en, description_ar)
      )
    ''');
      // Commit all table creation statements
      await batch.commit(noResult: true);

      // After all tables are created, insert the default admin user
      await _insertDefaultAdminUser(db);

      if (kDebugMode) {
        print('Database created successfully ********************************');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error creating database tables: $e');
      }
      rethrow;
    }
  }

Future<void> _insertDefaultAdminUser(Database db) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('admin_username', 'admin');
    await prefs.setString('admin_password', 'admin'); // Default password
    if (kDebugMode) {
      print('Admin credentials saved to SharedPreferences');
    }
  }

  static Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
      _initialized = false; // Reset initialization flag
    }
  }

  // Method to check if database exists
  Future<bool> databaseExists() async {
    String dbPath;
    if (Platform.isWindows) {
      final exePath = Platform.resolvedExecutable;
      final appDir = dirname(exePath);
      dbPath = join(appDir, 'data', 'euknet_transport.db');
    } else {
      final documentsPath = await getDatabasesPath();
      dbPath = join(documentsPath, 'euknet_transport.db');
    }
    return File(dbPath).exists();
  }

  // Method to reinitialize database
  Future<void> reinitializeDatabase() async {
    _database = null;
    _initialized = false;
    await ensureInitialized();
    await database; // This will trigger _initDatabase()
  }

  Future<User?> getUserById(int userId) async {
    final db = await database;

    List<Map<String, dynamic>> results =
        await db.query('users', where: 'id = ?', whereArgs: [userId]);

    if (results.isNotEmpty) {
      return User.fromMap(results.first);
    }

    return null;
  }

  Future<List<Country>> getAllCountries() async {
    final db = await database;
    final result = await db.query('countries');
    return result.map((map) => Country.fromMap(map)).toList();
  }

  // Add this method to fetch all currencies
  Future<List<Currency>> getAllCurrencies() async {
    final db = await database;
    final result = await db.query('currencies');
    return result.map((map) => Currency.fromMap(map)).toList();
  }

  Future<int> insertCurrency(Currency currency) async {
    final db = await database;
    return await db.insert(
      'currencies',
      currency.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> insertCountry(Country country) async {
    final db = await database;
    return await db.insert(
      'countries',
      country.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
