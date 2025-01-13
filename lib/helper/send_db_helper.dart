// send_record_database_helper.dart
import 'package:app/models/send_model.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';


class SendRecordDatabaseHelper {
  static final SendRecordDatabaseHelper _instance =
      SendRecordDatabaseHelper._internal();
  static Database? _database;

  factory SendRecordDatabaseHelper() => _instance;

  SendRecordDatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'send_records.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createTable,
    );
  }

Future<void> _createTable(Database db, int version) async {
    await db.execute('''
    CREATE TABLE send_records (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      date TEXT,
      truckNumber TEXT,
      codeNumber TEXT,
      senderName TEXT,
      senderPhone TEXT,
      senderIdNumber TEXT,
      goodsDescription TEXT,
      boxNumber INTEGER,
      palletNumber INTEGER,
      realWeightKg REAL,
      length REAL,
      width REAL,
      height REAL,
      isDimensionCalculated INTEGER,
      additionalKg REAL,
      totalWeightKg REAL,
      agentName TEXT,
      branchName TEXT,
      agentCode TEXT,
      receiverName TEXT,
      receiverPhone TEXT,
      receiverCountry TEXT,
      receiverCity TEXT,
      streetName TEXT,
      apartmentNumber TEXT,
      zipCode TEXT,
      postalCity TEXT,
      postalCountry TEXT,
      doorToDoorPrice REAL,
      pricePerKg REAL,
      minimumPrice REAL,
      insurancePercent REAL,
      goodsValue REAL,
      agentCommission REAL,
      insuranceAmount REAL,
      customsCost REAL,
      exportDocCost REAL,
      boxPackingCost REAL,
      doorToDoorCost REAL,
      postSubCost REAL,
      discountAmount REAL,
      totalPostCost REAL,
      totalPostCostPaid REAL,
      unpaidAmount REAL,
      totalCostEuroCurrency REAL,
      unpaidAmountEuro REAL
    )
  ''');

    await db
        .execute('CREATE INDEX idx_codeNumber ON send_records (codeNumber);');
    await db
        .execute('CREATE INDEX idx_branchName ON send_records (branchName);');
  }
 
  Future<int> insertSendRecord(SendRecord record) async {
    final db = await database;
    return await db.insert('send_records', record.toMap());
  }

  Future<List<SendRecord>> getAllSendRecords() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('send_records');
    return List.generate(maps.length, (i) => SendRecord.fromMap(maps[i]));
  }

  Future<SendRecord?> getSendRecordById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'send_records',
      where: 'id = ?',
      whereArgs: [id],
    );
    return maps.isNotEmpty ? SendRecord.fromMap(maps.first) : null;
  }

  Future<int> updateSendRecord(SendRecord record) async {
    final db = await database;
    return await db.update(
      'send_records',
      record.toMap(),
      where: 'id = ?',
      whereArgs: [record.id],
    );
  }

Future<int> updateSendRecordFields(int id, String codeNumber) async {
    final db = await database;
    final columns = [
      'id',
      'date',
      'truckNumber',
      'senderName',
      'senderPhone',
      'senderIdNumber',
      'goodsDescription',
      'boxNumber',
      'palletNumber',
      'realWeightKg',
      'length',
      'width',
      'height',
      'isDimensionCalculated',
      'additionalKg',
      'totalWeightKg',
      'agentName',
      'branchName',
      'agentCode',
      'receiverName',
      'receiverPhone',
      'receiverCountry',
      'receiverCity',
      'streetName',
      'apartmentNumber',
      'zipCode',
      'postalCity',
      'postalCountry',
      'doorToDoorPrice',
      'pricePerKg',
      'minimumPrice',
      'insurancePercent',
      'goodsValue',
      'agentCommission',
      'insuranceAmount',
      'customsCost',
      'exportDocCost',
      'boxPackingCost',
      'doorToDoorCost',
      'postSubCost',
      'discountAmount',
      'totalPostCost',
      'totalPostCostPaid',
      'unpaidAmount',
      'totalCostEuroCurrency',
      'unpaidAmountEuro'
    ];
    final setClause = columns.map((col) => '$col = NULL').join(', ');
    return await db.rawUpdate('''
    UPDATE send_records
    SET $setClause
    WHERE id = ? AND codeNumber = ?
  ''', [id, codeNumber]);
  }
  
  Future<int> deleteSendRecord(int id) async {
    final db = await database;
    return await db.delete(
      'send_records',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  Future<List<String>> getUniqueOfficeNames() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT DISTINCT branchName FROM send_records WHERE branchName IS NOT NULL',
    );
    return List.generate(maps.length, (i) => maps[i]['branchName'] as String);
  }

  Future<List<String>> getUniqueTruckNumbers() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT DISTINCT truckNumber FROM send_records WHERE truckNumber IS NOT NULL',
    );
    return List.generate(maps.length, (i) => maps[i]['truckNumber'] as String);
  }

  Future<List<String>> getUniqueEUCountries() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT DISTINCT receiverCountry FROM send_records WHERE receiverCountry IS NOT NULL',
    );
    return List.generate(
        maps.length, (i) => maps[i]['receiverCountry'] as String);
  }

  Future<List<String>> getUniqueAgentCities() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT DISTINCT receiverCity FROM send_records WHERE receiverCity IS NOT NULL',
    );
    return List.generate(maps.length, (i) => maps[i]['receiverCity'] as String);
  }
  Future<int> getTotalCodes() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT COUNT(*) as total FROM send_records',
    );
    return maps.first['total'] as int;
  }

  Future<int> getTotalBoxes() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT SUM(boxNumber) as total FROM send_records',
    );
    return maps.first['total'] as int? ??0;
  }

  Future<int> getTotalPallets() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT SUM(palletNumber) as total FROM send_records',
    );
    return maps.first['total'] as int? ??0;
  }

  Future<double> getTotalKG() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT SUM(totalWeightKg) as total FROM send_records',
    );
    return maps.first['total'] as double? ??0.0;
  }

  Future<List<String>> getUniqueCountries() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT DISTINCT receiverCountry FROM send_records WHERE receiverCountry IS NOT NULL',
    );
    return List.generate(
        maps.length, (i) => maps[i]['receiverCountry'] as String? ??'');
  }

  Future<Map<String, dynamic>> getCountryTotals(String country) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT
        COUNT(*) as totalCodes,
        SUM(boxNumber) as totalBoxes,
        SUM(palletNumber) as totalPallets,
        SUM(totalWeightKg) as totalKG,
        SUM(totalCostEuroCurrency) as totalCashIn,
        SUM(agentCommission) as totalCommissions,
        SUM(totalPostCostPaid) as totalPaidToCompany,
        SUM(unpaidAmountEuro) as totalPaidInEurope
      FROM send_records
      WHERE receiverCountry = ?
    ''', [country]);

    return maps.first;
  }
}
