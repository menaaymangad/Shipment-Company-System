import 'dart:io';

import 'package:app/helper/branch_db_helper.dart';
import 'package:app/helper/cities_db_helper.dart';
import 'package:app/helper/good_description_db_helper.dart';
import 'package:app/helper/send_db_helper.dart';
import 'package:app/helper/sql_helper.dart';
import 'package:app/helper/user_db_helper.dart';
import 'package:app/models/branches_model.dart';
import 'package:app/models/city_model.dart';
import 'package:app/models/country_model.dart';
import 'package:app/models/currency_model.dart';
import 'package:app/models/good_description_model.dart';
import 'package:app/models/send_model.dart';
import 'package:app/models/user_model.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseManagementExcelImport {
  final dbHelper = DatabaseHelper();
 

  static Future<void> exportToExcel(BuildContext context) async {
    try {
      final dbHelper = DatabaseHelper();

      // Fetch data from all tables
      List<Branch> branches = await dbHelper.getAllBranches();
      List<City> cities = await dbHelper.getAllCities();
      List<Country> countries = await dbHelper.getAllCountries();
      List<Currency> currencies = await dbHelper.getAllCurrencies();
      List<GoodsDescription> goodsDescriptions =
          await dbHelper.getAllGoodsDescriptions();
      List<SendRecord> sendRecords =
          await SendRecordDatabaseHelper().getAllSendRecords();
      List<User> users = await dbHelper.getAllUsers();

      // Debug logs to check if data is fetched
      if (kDebugMode) {
        print('Branches fetched: ${branches.length}');
        print('Cities fetched: ${cities.length}');
        print('Countries fetched: ${countries.length}');
        print('Currencies fetched: ${currencies.length}');
        print('Goods Descriptions fetched: ${goodsDescriptions.length}');
        print('Send Records fetched: ${sendRecords.length}');
        print('Users fetched: ${users.length}');
      }

      // Create a new Excel document
      var excel = Excel.createExcel();

      // Export Branches
      _exportTableToExcel(
          excel,
          'Branches',
          [
            'id',
            'branchName',
            'contactPersonName',
            'branchCompany',
            'phoneNo1',
            'phoneNo2',
            'address',
            'city',
            'charactersPrefix',
            'yearPrefix',
            'numberOfDigits',
            'codeStyle',
            'invoiceLanguage'
          ],
          branches
              .map((branch) => [
                    branch.id,
                    branch.branchName,
                    branch.contactPersonName,
                    branch.branchCompany,
                    branch.phoneNo1,
                    branch.phoneNo2,
                    branch.address,
                    branch.city,
                    branch.charactersPrefix,
                    branch.yearPrefix,
                    branch.numberOfDigits,
                    branch.codeStyle,
                    branch.invoiceLanguage
                  ])
              .toList());

      // Export Cities
      _exportTableToExcel(
          excel,
          'Cities',
          [
            'id',
            'cityName',
            'country',
            'hasAgent',
            'isPost',
            'doorToDoorPrice',
            'priceKg',
            'minimumPrice',
            'boxPrice'
          ],
          cities
              .map((city) => [
                    city.id,
                    city.cityName,
                    city.country,
                    city.hasAgent,
                    city.isPost,
                    city.doorToDoorPrice,
                    city.priceKg,
                    city.minimumPrice,
                    city.boxPrice
                  ])
              .toList());

      // Export Countries
      _exportTableToExcel(
          excel,
          'Countries',
          [
            'id',
            'countryName',
            'alpha2Code',
            'zipCodeDigit1',
            'zipCodeDigit2',
            'zipCodeText',
            'currency',
            'currencyAgainstIQD',
            'hasAgent',
            'maxWeightKG',
            'flagBoxLabel',
            'postBoxLabel'
          ],
          countries
              .map((country) => [
                    country.id,
                    country.countryName,
                    country.alpha2Code,
                    country.zipCodeDigit1,
                    country.zipCodeDigit2,
                    country.zipCodeText,
                    country.currency,
                    country.currencyAgainstIQD,
                    country.hasAgent,
      
                    
                  ])
              .toList());

      // Export Currencies
      _exportTableToExcel(
          excel,
          'Currencies',
          ['id', 'currencyName', 'currencyAgainst1IraqiDinar'],
          currencies
              .map((currency) => [
                    currency.id,
                    currency.currencyName,
                    currency.currencyAgainst1IraqiDinar
                  ])
              .toList());

      // Export Goods Descriptions
      _exportTableToExcel(
          excel,
          'Goods Descriptions',
          ['id', 'descriptionEn', 'descriptionAr', 'weight'],
          goodsDescriptions
              .map((goods) => [
                    goods.id,
                    goods.descriptionEn,
                    goods.descriptionAr,
                    goods.weight
                  ])
              .toList());

      // Export Send Records
      _exportTableToExcel(
          excel,
          'Send Records',
          [
            'id',
            'date',
            'truckNumber',
            'codeNumber',
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
          ],
          sendRecords
              .map((record) => [
                    record.id,
                    record.date,
                    record.truckNumber,
                    record.codeNumber,
                    record.senderName,
                    record.senderPhone,
                    record.senderIdNumber,
                    record.goodsDescription,
                    record.boxNumber,
                    record.palletNumber,
                    record.realWeightKg,
                    record.length,
                    record.width,
                    record.height,
                    record.isDimensionCalculated,
                    record.additionalKg,
                    record.totalWeightKg,
                    record.agentName,
                    record.branchName,
            
                    record.receiverName,
                    record.receiverPhone,
                    record.receiverCountry,
                    record.receiverCity,
                    record.streetName,
                
                    record.zipCode,
                
                    record.doorToDoorPrice,
                    record.pricePerKg,
                    record.minimumPrice,
                    record.insurancePercent,
                    record.goodsValue,
                
                    record.insuranceAmount,
                    record.customsCost,
                
                    record.boxPackingCost,
                    record.doorToDoorCost,
                    record.postSubCost,
                    record.discountAmount,
                    record.totalPostCost,
                    record.totalPostCostPaid,
                    record.unpaidAmount,
                    record.totalCostEuroCurrency,
                    record.unpaidAmountEuro
                  ])
              .toList());

      // Export Users
      _exportTableToExcel(
          excel,
          'Users',
          [
            'id',
            'userName',
            'branchName',
            'authorization',
            'allowLogin',
            'password'
          ],
          users
              .map((user) => [
                    user.id,
                    user.userName,
                    user.branchName,
                    user.authorization,
                    user.allowLogin,
                    user.password
                  ])
              .toList());

      // Debug logs to check if data is added to the sheets
      if (kDebugMode) {
        print('Excel sheets: ${excel.sheets.keys}');
        for (var sheet in excel.sheets.values) {
          print('Sheet: ${sheet.sheetName}, Rows: ${sheet.rows.length}');
        }
      }

      // Let the user choose where to save the file
      String? outputFilePath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Excel File',
        fileName: 'export.xlsx',
        allowedExtensions: ['xlsx'],
      );

      // Save the Excel file
      var fileBytes = excel.save();
      if (fileBytes != null) {
        File(outputFilePath!)
          ..createSync(recursive: true)
          ..writeAsBytesSync(fileBytes);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Data exported to $outputFilePath')),
        );

        // Debug log to check if the file is saved
        if (kDebugMode) {
          print('File saved at: $outputFilePath');
        }
      } else {
        if (kDebugMode) {
          print('Failed to save Excel file: fileBytes is null');
        }
      }
        } catch (e) {
      if (kDebugMode) {
        print('Excel export error: $e');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to export Excel file')),
      );
    }
  }

  static void _exportTableToExcel(Excel excel, String tableName,
      List<String> headers, List<List<dynamic>> rows) {
    // Create a new sheet for the table
    var sheet = excel[tableName];

    // Add headers
    for (int i = 0; i < headers.length; i++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
          .value = TextCellValue(headers[i]);
    }

    // Add rows
    for (int rowIndex = 0; rowIndex < rows.length; rowIndex++) {
      var row = rows[rowIndex];
      for (int colIndex = 0; colIndex < row.length; colIndex++) {
        var cellValue = row[colIndex];
        // Convert the value to TextCellValue
        sheet
            .cell(CellIndex.indexByColumnRow(
                columnIndex: colIndex,
                rowIndex: rowIndex + 1 // +1 because row 0 is headers
                ))
            .value = TextCellValue(cellValue.toString());
      }
    }

    // Debug logs to check if data is added to the sheet
    if (kDebugMode) {
      print('Sheet: $tableName, Rows: ${sheet.rows.length}');
    }
  }

  static Future<void> importFromExcel(BuildContext context) async {
    try {
      // Let the user choose the Excel file to import
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (result != null) {
        // Get the file path
        String filePath = result.files.single.path!;

        // Load the Excel file
        var bytes = File(filePath).readAsBytesSync();
        var excel = Excel.decodeBytes(bytes);

        // Debug log to check sheets in the file
        if (kDebugMode) {
          print('Sheets in the file: ${excel.sheets.keys}');
        }

        // Import data from each sheet
        for (var sheetName in excel.sheets.keys) {
          var sheet = excel.sheets[sheetName]!;

          // Debug log to check sheet data
          if (kDebugMode) {
            print('Sheet: $sheetName, Rows: ${sheet.rows.length}');
          }

          // Skip if the sheet is empty
          if (sheet.rows.isEmpty) continue;

          // Get headers (first row)
          var headers = sheet.rows[0]
              .map((cell) => cell?.value.toString() ?? '')
              .toList();

          // Process rows (skip the header row)
          for (int rowIndex = 1; rowIndex < sheet.rows.length; rowIndex++) {
            var row = sheet.rows[rowIndex];
            var rowData = row.map((cell) => cell?.value.toString()).toList();

            // Map row data to the appropriate model based on the sheet name
            switch (sheetName) {
              case 'Branches':
                await _importBranch(headers, rowData);
                break;
              case 'Cities':
                await _importCity(headers, rowData);
                break;
              case 'Countries':
                await _importCountry(headers, rowData);
                break;
              case 'Currencies':
                await _importCurrency(headers, rowData);
                break;
              case 'Goods Descriptions':
                await _importGoodsDescription(headers, rowData);
                break;
              case 'Send Records':
                await _importSendRecord(headers, rowData);
                break;
              case 'Users':
                await _importUser(headers, rowData);
                break;
              default:
                if (kDebugMode) {
                  print('Unknown sheet: $sheetName');
                }
                break;
            }
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data imported successfully')),
        );
      } else {
        if (kDebugMode) {
          print('File picker canceled by user');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Excel import error: $e');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to import Excel file')),
      );
    }
  }

  static Future<void> _importBranch(
      List<String> headers, List<String?> rowData) async {
    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;

    // Map row data to Branch model
    var branch = Branch(
      id: int.tryParse(rowData[headers.indexOf('id')] ?? ''),
      branchName: rowData[headers.indexOf('branchName')] ?? '',
      contactPersonName: rowData[headers.indexOf('contactPersonName')] ?? '',
      branchCompany: rowData[headers.indexOf('branchCompany')] ?? '',
      phoneNo1: rowData[headers.indexOf('phoneNo1')] ?? '',
      phoneNo2: rowData[headers.indexOf('phoneNo2')] ?? '',
      address: rowData[headers.indexOf('address')] ?? '',
      city: rowData[headers.indexOf('city')] ?? '',
      charactersPrefix: rowData[headers.indexOf('charactersPrefix')] ?? '',
      yearPrefix: rowData[headers.indexOf('yearPrefix')] ?? '',
      numberOfDigits:
          int.tryParse(rowData[headers.indexOf('numberOfDigits')] ?? '') ?? 0,
      codeStyle: rowData[headers.indexOf('codeStyle')] ?? '',
      invoiceLanguage: rowData[headers.indexOf('invoiceLanguage')] ?? '',
    );

    // Insert or replace the branch
    await db.insert(
      'branches',
      branch.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace, // Update if exists
    );

    if (kDebugMode) {
      print('Branch with id ${branch.id} imported/updated successfully.');
    }
  }

  static Future<void> _importCity(
      List<String> headers, List<String?> rowData) async {
    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;

    // Map row data to City model
    var city = City(
      id: int.tryParse(rowData[headers.indexOf('id')] ?? ''),
      cityName: rowData[headers.indexOf('cityName')] ?? '',
      country: rowData[headers.indexOf('country')] ?? '',
      hasAgent: rowData[headers.indexOf('hasAgent')] == 'true',
      isPost: rowData[headers.indexOf('isPost')] == 'true',
      doorToDoorPrice:
          double.tryParse(rowData[headers.indexOf('doorToDoorPrice')] ?? '') ??
              0.0,
      priceKg:
          double.tryParse(rowData[headers.indexOf('priceKg')] ?? '') ?? 0.0,
      minimumPrice:
          double.tryParse(rowData[headers.indexOf('minimumPrice')] ?? '') ??
              0.0,
      boxPrice:
          double.tryParse(rowData[headers.indexOf('boxPrice')] ?? '') ?? 0.0,  squareFlag: rowData[headers.indexOf('flagBoxLabel')] ?? '',
      circularFlag: rowData[headers.indexOf('postBoxLabel')] ?? '',
      maxWeightKG:
          double.tryParse(rowData[headers.indexOf('maxWeightKG')] ?? '') ?? 0.0,
    );

    // Insert or replace the city
    await db.insert(
      'cities',
      city.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace, // Update if exists
    );

    if (kDebugMode) {
      print('City with id ${city.id} imported/updated successfully.');
    }
  }

  static Future<void> _importCountry(
      List<String> headers, List<String?> rowData) async {
    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;

    // Map row data to Country model
    var country = Country(
      id: int.tryParse(rowData[headers.indexOf('id')] ?? ''),
      countryName: rowData[headers.indexOf('countryName')] ?? '',
      alpha2Code: rowData[headers.indexOf('alpha2Code')] ?? '',
      zipCodeDigit1: rowData[headers.indexOf('zipCodeDigit1')] ?? '',
      zipCodeDigit2: rowData[headers.indexOf('zipCodeDigit2')] ?? '',
      zipCodeText: rowData[headers.indexOf('zipCodeText')] ?? '',
      currency: rowData[headers.indexOf('currency')] ?? '',
      currencyAgainstIQD: double.tryParse(
              rowData[headers.indexOf('currencyAgainstIQD')] ?? '') ??
          0.0,
      hasAgent: rowData[headers.indexOf('hasAgent')] == 'true',

     
    );

    // Insert or replace the country
    await db.insert(
      'countries',
      country.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace, // Update if exists
    );

    if (kDebugMode) {
      print('Country with id ${country.id} imported/updated successfully.');
    }
  }

  static Future<void> _importCurrency(
      List<String> headers, List<String?> rowData) async {
    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;

    // Map row data to Currency model
    var currency = Currency(
      id: int.tryParse(rowData[headers.indexOf('id')] ?? ''),
      currencyName: rowData[headers.indexOf('currencyName')] ?? '',
      currencyAgainst1IraqiDinar: double.tryParse(
              rowData[headers.indexOf('currencyAgainst1IraqiDinar')] ?? '') ??
          0.0,
    );

    // Insert or replace the currency
    await db.insert(
      'currencies',
      currency.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace, // Update if exists
    );

    if (kDebugMode) {
      print('Currency with id ${currency.id} imported/updated successfully.');
    }
  }

  static Future<void> _importGoodsDescription(
      List<String> headers, List<String?> rowData) async {
    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;

    // Map row data to GoodsDescription model
    var goodsDescription = GoodsDescription(
      id: int.tryParse(rowData[headers.indexOf('id')] ?? ''),
      descriptionEn: rowData[headers.indexOf('descriptionEn')] ?? '',
      descriptionAr: rowData[headers.indexOf('descriptionAr')] ?? '',
      weight: double.tryParse(rowData[headers.indexOf('weight')] ?? '') ?? 0.0,
    );

    // Insert or replace the goods description
    await db.insert(
      'goods_descriptions',
      goodsDescription.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace, // Update if exists
    );

    if (kDebugMode) {
      print(
          'Goods Description with id ${goodsDescription.id} imported/updated successfully.');
    }
  }

  static Future<void> _importSendRecord(
      List<String> headers, List<String?> rowData) async {
    final dbHelper = SendRecordDatabaseHelper();
    final db = await dbHelper.database;

    // Map row data to SendRecord model
    var sendRecord = SendRecord(
      id: int.tryParse(rowData[headers.indexOf('id')] ?? ''),
      date: rowData[headers.indexOf('date')] ?? '',
      truckNumber: rowData[headers.indexOf('truckNumber')] ?? '',
      codeNumber: rowData[headers.indexOf('codeNumber')] ?? '',
      senderName: rowData[headers.indexOf('senderName')] ?? '',
      senderPhone: rowData[headers.indexOf('senderPhone')] ?? '',
      senderIdNumber: rowData[headers.indexOf('senderIdNumber')] ?? '',
      goodsDescription: rowData[headers.indexOf('goodsDescription')] ?? '',
      boxNumber: int.tryParse(rowData[headers.indexOf('boxNumber')] ?? '') ?? 0,
      palletNumber:
          int.tryParse(rowData[headers.indexOf('palletNumber')] ?? '') ?? 0,
      realWeightKg:
          double.tryParse(rowData[headers.indexOf('realWeightKg')] ?? '') ??
              0.0,
      length: double.tryParse(rowData[headers.indexOf('length')] ?? '') ?? 0.0,
      width: double.tryParse(rowData[headers.indexOf('width')] ?? '') ?? 0.0,
      height: double.tryParse(rowData[headers.indexOf('height')] ?? '') ?? 0.0,
      isDimensionCalculated:
          rowData[headers.indexOf('isDimensionCalculated')] == 'true',
      additionalKg:
          double.tryParse(rowData[headers.indexOf('additionalKg')] ?? '') ??
              0.0,
      totalWeightKg:
          double.tryParse(rowData[headers.indexOf('totalWeightKg')] ?? '') ??
              0.0,
      agentName: rowData[headers.indexOf('agentName')] ?? '',
      branchName: rowData[headers.indexOf('branchName')] ?? '',
   
      receiverName: rowData[headers.indexOf('receiverName')] ?? '',
      receiverPhone: rowData[headers.indexOf('receiverPhone')] ?? '',
      receiverCountry: rowData[headers.indexOf('receiverCountry')] ?? '',
      receiverCity: rowData[headers.indexOf('receiverCity')] ?? '',
      streetName: rowData[headers.indexOf('streetName')] ?? '',
     
      zipCode: rowData[headers.indexOf('zipCode')] ?? '',

      doorToDoorPrice:
          double.tryParse(rowData[headers.indexOf('doorToDoorPrice')] ?? '') ??
              0.0,
      pricePerKg:
          double.tryParse(rowData[headers.indexOf('pricePerKg')] ?? '') ?? 0.0,
      minimumPrice:
          double.tryParse(rowData[headers.indexOf('minimumPrice')] ?? '') ??
              0.0,
      insurancePercent:
          double.tryParse(rowData[headers.indexOf('insurancePercent')] ?? '') ??
              0.0,
      goodsValue:
          double.tryParse(rowData[headers.indexOf('goodsValue')] ?? '') ?? 0.0,
    
      insuranceAmount:
          double.tryParse(rowData[headers.indexOf('insuranceAmount')] ?? '') ??
              0.0,
      customsCost:
          double.tryParse(rowData[headers.indexOf('customsCost')] ?? '') ?? 0.0,
    
      boxPackingCost:
          double.tryParse(rowData[headers.indexOf('boxPackingCost')] ?? '') ??
              0.0,
      doorToDoorCost:
          double.tryParse(rowData[headers.indexOf('doorToDoorCost')] ?? '') ??
              0.0,
      postSubCost:
          double.tryParse(rowData[headers.indexOf('postSubCost')] ?? '') ?? 0.0,
      discountAmount:
          double.tryParse(rowData[headers.indexOf('discountAmount')] ?? '') ??
              0.0,
      totalPostCost:
          double.tryParse(rowData[headers.indexOf('totalPostCost')] ?? '') ??
              0.0,
      totalPostCostPaid: double.tryParse(
              rowData[headers.indexOf('totalPostCostPaid')] ?? '') ??
          0.0,
      unpaidAmount:
          double.tryParse(rowData[headers.indexOf('unpaidAmount')] ?? '') ??
              0.0,
      totalCostEuroCurrency: double.tryParse(
              rowData[headers.indexOf('totalCostEuroCurrency')] ?? '') ??
          0.0,
      unpaidAmountEuro:
          double.tryParse(rowData[headers.indexOf('unpaidAmountEuro')] ?? '') ??
              0.0,
    );

    // Insert or replace the send record
    await db.insert(
      'send_records',
      sendRecord.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace, // Update if exists
    );

    if (kDebugMode) {
      print(
          'Send Record with id ${sendRecord.id} imported/updated successfully.');
    }
  }

  static Future<void> _importUser(
      List<String> headers, List<String?> rowData) async {
    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;

    // Map row data to User model
    var user = User(
      id: int.tryParse(rowData[headers.indexOf('id')] ?? ''),
      userName: rowData[headers.indexOf('userName')] ?? '',
      branchName: rowData[headers.indexOf('branchName')] ?? '',
      authorization: rowData[headers.indexOf('authorization')] ?? '',
      allowLogin: rowData[headers.indexOf('allowLogin')] == 'true',
      password: rowData[headers.indexOf('password')] ?? '',
    );

    // Insert or replace the user
    await db.insert(
      'users',
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace, // Update if exists
    );

    if (kDebugMode) {
      print('User with id ${user.id} imported/updated successfully.');
    }
  }
}
