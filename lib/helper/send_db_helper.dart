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

  Future<int> deleteSendRecord(int id) async {
    final db = await database;
    return await db.delete(
      'send_records',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
