import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Comprehensive shipping label generation class with improved error handling and design
// class ShippingLabelGenerator {
//   /// List of fallback fonts for Unicode support
//   static List<pw.Font> _fontFallback = [];

//   static Future<pw.Font> loadCairoFont({bool isBold = false}) async {
//     try {
//       // Load font directly from assets
//       final fontPath = isBold
//           ? 'fonts/Cairo/static/Cairo-Bold.ttf'
//           : 'fonts/Cairo/static/Cairo-Regular.ttf';

//       final fontData = await rootBundle.load(fontPath);
//       return pw.Font.ttf(fontData);
//     } catch (e) {
//       if (kDebugMode) {
//         print('Error loading Cairo font: $e');
//       }
//       // Fallback to a Unicode-supported font
//       return pw.Font.timesBold();
//     }
//   }

//   static Future<pw.Font> loadArabicFont() async {
//     final fontData = await rootBundle.load('fonts/NotoSansArabic-Regular.ttf');
//     return pw.Font.ttf(fontData);
//   }

//   static Future<pw.Font> loadKurdishFont() async {
//     final fontData = await rootBundle.load('fonts/Amiri-Regular.ttf');
//     return pw.Font.ttf(fontData);
//   }

//   static Future<pw.Font> loadRobotoFont() async {
//     try {
//       final fontData = await rootBundle.load('fonts/Roboto-Regular.ttf');
//       return pw.Font.ttf(fontData);
//     } catch (e) {
//       if (kDebugMode) {
//         print('Error loading Roboto font: $e');
//       }
//       return pw.Font.helvetica();
//     }
//   }

//   static Future<void> initializeFonts() async {
//     try {
//       // Load Arabic fonts
//       final cairoBold = await loadCairoFont(isBold: true);
//       final cairoRegular = await loadCairoFont(isBold: false);
//       final arabicFont = await loadArabicFont();
//       final kurdishFont = await loadKurdishFont();

//       final robotoFont = await loadRobotoFont();

//       // Update fallback list to include Roboto
//       _fontFallback = [
//         cairoBold,
//         cairoRegular,
//         arabicFont,
//         kurdishFont,
//         robotoFont, // Add Roboto to fallback list
//       ];
//     } catch (e) {
//       if (kDebugMode) {
//         print('Error initializing fonts: $e');
//       }
//     }
//   }

//   /// Create a standardized text style with fallback fonts
//   static pw.TextStyle _createTextStyle({
//     required pw.Font font,
//     required double fontSize,
//     PdfColor? color,
//     pw.FontWeight? fontWeight,
//   }) {
//     return pw.TextStyle(
//       font: font,
//       fontSize: fontSize.sp,
//       color: color ?? PdfColors.black,
//       fontWeight: fontWeight ?? pw.FontWeight.normal,
//       fontFallback: _fontFallback, // Ensure this is always included
//     );
//   }

//   /// Load image asset with error handling
//   static Future<pw.MemoryImage> _loadAssetImage(String assetPath) async {
//     try {
//       final ByteData data = await rootBundle.load(assetPath);
//       return pw.MemoryImage(data.buffer.asUint8List());
//     } catch (e) {
//       debugPrint('Error loading asset image: $e');
//       throw Exception('Failed to load image: $assetPath');
//     }
//   }

//   /// Generate shipping label PDF
//  static pw.Widget _buildShippingLabelContent({
//     required pw.Context context,
//     required pw.Font baseFont,
//     required pw.Font boldFont,
//     required pw.MemoryImage logoImage,
//     required pw.MemoryImage euknetLogo,
//     required pw.MemoryImage qrCode,
//     required SenderDetails sender,
//     required ReceiverDetails receiver,
//     required ShipmentInfo shipment,
//     required ShippingLabelLocalizations translations,
//   }) {
//     return pw.Column(
//       crossAxisAlignment: pw.CrossAxisAlignment.start,
//       children: [
//         // Header Section
//         _buildHeader(logoImage, euknetLogo, boldFont, translations),
//         pw.SizedBox(height: 20.h),

//         // Sender and Receiver Information
//         _buildSenderReceiverSection(
//             sender, receiver, baseFont, boldFont, translations),
//         pw.SizedBox(height: 20.h),

//         // Shipment Details
//         _buildShipmentDetails(shipment, baseFont, boldFont, translations),
//         pw.SizedBox(height: 20.h),

//         // Footer Section
//         _buildFooter(shipment, baseFont, translations),
//       ],
//     );
//   }

//   /// Build header with contact information and logos
//   static pw.Widget _buildHeader(
//     pw.MemoryImage logoImage,
//     pw.MemoryImage euknetLogo,
//     pw.Font boldFont,
//     ShippingLabelLocalizations translations,
//   ) {
//     return pw.Row(
//       mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
//       children: [
//         pw.Image(logoImage, width: 200.w),
//         pw.Column(
//           crossAxisAlignment: pw.CrossAxisAlignment.start,
//           children: [
//             pw.Text(
//               'EUKNET Transport B.V.',
//               style: pw.TextStyle(
//                 font: boldFont,
//                 fontSize: 16.sp,
//                 color: PdfColors.black,
//               ),
//             ),
//             pw.Text(
//               'De Steiger 98\n1351 AH Almere\nThe Netherlands',
//               style: pw.TextStyle(
//                 font: boldFont,
//                 fontSize: 12.sp,
//                 color: PdfColors.black,
//               ),
//             ),
//             pw.Text(
//               'Tel 1: 0031-(0)36 5342869\nTel 2: 0031-(0)36 5345523\nEmail: info@euknet.com\nWeb: www.euknet.com',
//               style: pw.TextStyle(
//                 font: boldFont,
//                 fontSize: 12.sp,
//                 color: PdfColors.black,
//               ),
//             ),
//           ],
//         ),
//         pw.Image(euknetLogo, width: 100.w),
//       ],
//     );
//   }

//   /// Build sender and receiver information section
//   static pw.Widget _buildSenderReceiverSection(
//     SenderDetails sender,
//     ReceiverDetails receiver,
//     pw.Font baseFont,
//     pw.Font boldFont,
//     ShippingLabelLocalizations translations,
//   ) {
//     return pw.Column(
//       crossAxisAlignment: pw.CrossAxisAlignment.start,
//       children: [
//         pw.Text(
//           'From:',
//           style: pw.TextStyle(
//             font: boldFont,
//             fontSize: 14.sp,
//             color: PdfColors.black,
//           ),
//         ),
//         pw.Text(
//           'Sender Name: ${sender.name}',
//           style: pw.TextStyle(
//             font: baseFont,
//             fontSize: 12.sp,
//             color: PdfColors.black,
//           ),
//         ),
//         pw.Text(
//           'Number of Parcel: 1', // Assuming 1 parcel for simplicity
//           style: pw.TextStyle(
//             font: baseFont,
//             fontSize: 12.sp,
//             color: PdfColors.black,
//           ),
//         ),
//         pw.Text(
//           'Weight Kg: ${shipment.weight}',
//           style: pw.TextStyle(
//             font: baseFont,
//             fontSize: 12.sp,
//             color: PdfColors.black,
//           ),
//         ),
//         pw.SizedBox(height: 10.h),
//         pw.Text(
//           'To:',
//           style: pw.TextStyle(
//             font: boldFont,
//             fontSize: 14.sp,
//             color: PdfColors.black,
//           ),
//         ),
//         pw.Text(
//           'Receiver Name: ${receiver.name}',
//           style: pw.TextStyle(
//             font: baseFont,
//             fontSize: 12.sp,
//             color: PdfColors.black,
//           ),
//         ),
//         pw.Text(
//           'Address: ${receiver.street}, ${receiver.apartment}',
//           style: pw.TextStyle(
//             font: baseFont,
//             fontSize: 12.sp,
//             color: PdfColors.black,
//           ),
//         ),
//         pw.Text(
//           'Postal Code: ${receiver.zipCode}',
//           style: pw.TextStyle(
//             font: baseFont,
//             fontSize: 12.sp,
//             color: PdfColors.black,
//           ),
//         ),
//         pw.Text(
//           'City Name: ${receiver.city}',
//           style: pw.TextStyle(
//             font: baseFont,
//             fontSize: 12.sp,
//             color: PdfColors.black,
//           ),
//         ),
//         pw.Text(
//           'Country: ${receiver.country}',
//           style: pw.TextStyle(
//             font: baseFont,
//             fontSize: 12.sp,
//             color: PdfColors.black,
//           ),
//         ),
//         pw.Text(
//           'Receiver Phone No.: ${receiver.phone}',
//           style: pw.TextStyle(
//             font: baseFont,
//             fontSize: 12.sp,
//             color: PdfColors.black,
//           ),
//         ),
//         pw.Text(
//           'Code: ${shipment.code}',
//           style: pw.TextStyle(
//             font: baseFont,
//             fontSize: 12.sp,
//             color: PdfColors.black,
//           ),
//         ),
//       ],
//     );
//   }

//   /// Build shipment details section
//   static pw.Widget _buildShipmentDetails(
//     ShipmentInfo shipment,
//     pw.Font baseFont,
//     pw.Font boldFont,
//     ShippingLabelLocalizations translations,
//   ) {
//     return pw.Column(
//       crossAxisAlignment: pw.CrossAxisAlignment.start,
//       children: [
//         pw.Text(
//           'Date & Time: ${shipment.date} ${shipment.time}',
//           style: pw.TextStyle(
//             font: boldFont,
//             fontSize: 14.sp,
//             color: PdfColors.black,
//           ),
//         ),
//         pw.Text(
//           'Item Details: ${shipment.itemDetails}',
//           style: pw.TextStyle(
//             font: baseFont,
//             fontSize: 12.sp,
//             color: PdfColors.black,
//           ),
//         ),
//       ],
//     );
//   }

//   /// Build footer with shipment details
//   static pw.Widget _buildFooter(
//     ShipmentInfo shipment,
//     pw.Font baseFont,
//     ShippingLabelLocalizations translations,
//   ) {
//     return pw.Column(
//       crossAxisAlignment: pw.CrossAxisAlignment.start,
//       children: [
//         pw.Text(
//           'Insurance: ${shipment.insuranceAmount}', // Assuming insurance amount is part of ShipmentInfo
//           style: pw.TextStyle(
//             font: boldFont,
//             fontSize: 14.sp,
//             color: PdfColors.black,
//           ),
//         ),
//         pw.Text(
//           'Payment Status: Paid', // Assuming payment status is part of ShipmentInfo
//           style: pw.TextStyle(
//             font: baseFont,
//             fontSize: 12.sp,
//             color: PdfColors.black,
//           ),
//         ),
//         pw.Image(qrCode, width: 100.w), // QR Code at the bottom
//       ],
//     );
//   }
// }

class ShippingLabelGenerator {
  /// List of fallback fonts for Unicode support
  static List<pw.Font> _fontFallback = [];

  static Future<pw.Font> loadCairoFont({bool isBold = false}) async {
    try {
      // Load font directly from assets
      final fontPath = isBold
          ? 'fonts/Cairo/static/Cairo-Bold.ttf'
          : 'fonts/Cairo/static/Cairo-Regular.ttf';

      final fontData = await rootBundle.load(fontPath);
      return pw.Font.ttf(fontData);
    } catch (e) {
      if (kDebugMode) {
        print('Error loading Cairo font: $e');
      }
      // Fallback to a Unicode-supported font
      return pw.Font.timesBold();
    }
  }

  static Future<pw.Font> loadArabicFont() async {
    final fontData = await rootBundle.load('fonts/NotoSansArabic-Regular.ttf');
    return pw.Font.ttf(fontData);
  }

  static Future<pw.Font> loadKurdishFont() async {
    final fontData = await rootBundle.load('fonts/Amiri-Regular.ttf');
    return pw.Font.ttf(fontData);
  }

  static Future<pw.Font> loadRobotoFont() async {
    try {
      final fontData = await rootBundle.load('fonts/Roboto-Regular.ttf');
      return pw.Font.ttf(fontData);
    } catch (e) {
      if (kDebugMode) {
        print('Error loading Roboto font: $e');
      }
      return pw.Font.helvetica();
    }
  }

  static Future<void> initializeFonts() async {
    try {
      // Load Arabic fonts
      final cairoBold = await loadCairoFont(isBold: true);
      final cairoRegular = await loadCairoFont(isBold: false);
      final arabicFont = await loadArabicFont();
      final kurdishFont = await loadKurdishFont();

      final robotoFont = await loadRobotoFont();

      // Update fallback list to include Roboto
      _fontFallback = [
        cairoBold,
        cairoRegular,
        arabicFont,
        kurdishFont,
        robotoFont, // Add Roboto to fallback list
      ];
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing fonts: $e');
      }
    }
  }

  static pw.TextStyle _createTextStyle({
    required pw.Font font,
    required double fontSize,
    PdfColor? color,
    pw.FontWeight? fontWeight,
  }) {
    return pw.TextStyle(
      font: font,
      fontSize: fontSize.sp,
      color: color ?? PdfColors.black,
      fontWeight: fontWeight ?? pw.FontWeight.normal,
      fontFallback: _fontFallback, // Ensure this is always included
    );
  }

  static void debugAssetPaths() async {
    try {
      // Print all registered assets
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestContent);
      if (kDebugMode) {
        print('Available assets:');
      }
      for (var key in manifestMap.keys) {
        if (kDebugMode) {
          print(key);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading asset manifest: $e');
      }
    }
  }

// Call this during initialization or when testing

  /// Load image asset with error handling
  static Future<pw.MemoryImage> _loadAssetImage(String assetPath) async {
    try {
      final ByteData data = await rootBundle.load(assetPath);
      return pw.MemoryImage(data.buffer.asUint8List());
    } catch (e) {
      debugPrint('Error loading asset image: $e');
      throw Exception('Failed to load image: $assetPath');
    }
  }

  static Future<pw.MemoryImage?> loadFlagImage(String assetPath) async {
    try {
      final ByteData data = await rootBundle.load(assetPath);
      if (data.lengthInBytes == 0) {
        throw Exception('Image data is empty');
      }
      return pw.MemoryImage(data.buffer.asUint8List());
    } catch (e) {
      debugPrint('Error loading flag image: $e');
      return null;
    }
  }

  static Future<void> generateShippingLabel({
    required SenderDetails sender,
    required ReceiverDetails receiver,
    required ShipmentInfo shipment,
    required pw.Font regularFont,
    required pw.Font boldFont,
    required Function(Uint8List) onGenerated,
  }) async {
    try {
      await initializeFonts();
      final pdf = pw.Document();

      // Load required images
      final logoImage =
          await _loadAssetImage('assets/icons/Sters Logo N-BG.png');
      final euknetLogo = await _loadAssetImage('assets/icons/euknet_logo.png');
      final qrCode = await _loadAssetImage('assets/icons/qr_code.png');
      final germanFlag = await _loadAssetImage('assets/icons/german_flag.png');

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) => _buildShippingLabelContent(
            context: context,
            logoImage: logoImage,
            euknetLogo: euknetLogo,
            qrCode: qrCode,
            germanFlag: germanFlag,
            sender: sender,
            receiver: receiver,
            shipment: shipment,
            baseFont: regularFont,
            boldFont: boldFont,
          ),
        ),
      );

      final pdfData = await pdf.save();
      onGenerated(pdfData);
    } catch (e) {
      debugPrint('Error generating shipping label: $e');
      rethrow;
    }
  }

  static pw.Widget _buildShippingLabelContent({
    required pw.Context context,
    required pw.MemoryImage logoImage,
    required pw.MemoryImage euknetLogo,
    required pw.MemoryImage qrCode,
    required pw.MemoryImage germanFlag,
    required SenderDetails sender,
    required ReceiverDetails receiver,
    required ShipmentInfo shipment,
    required pw.Font baseFont,
    required pw.Font boldFont,
  }) {
    return pw.Container(
      padding: pw.EdgeInsets.all(20),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Header with logos and contact info
          _buildHeader(logoImage, euknetLogo, qrCode, boldFont),
          pw.SizedBox(height: 20),

          // Main content
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Left side - main form
              pw.Expanded(
                flex: 4,
                child: _buildMainForm(
                  sender,
                  receiver,
                  shipment,
                  baseFont,
                ),
              ),
              // Right side - "From BAGHDAD"
              pw.Container(
                width: 80,
                child: pw.Transform.rotate(
                  angle: 90,
                  child: pw.Text(
                    'BAGHDAD',
                    style: pw.TextStyle(
                      font: boldFont,
                      fontSize: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Bottom flag
          pw.Positioned(
            bottom: 0,
            child: pw.Image(germanFlag, width: 200),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildHeader(
    pw.MemoryImage logoImage,
    pw.MemoryImage euknetLogo,
    pw.MemoryImage qrCode,
    pw.Font boldFont,
  ) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Row(
          children: [
            pw.Image(logoImage, width: 80),
            pw.SizedBox(width: 10),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'STERS TRANSPORT - IRAQ',
                  style: pw.TextStyle(font: boldFont, fontSize: 14),
                ),
                pw.Text(
                  'Sulemany : 0750 8155872\n'
                  'Hawler    : 0770 2120019\n'
                  'Duhok     : 0751 4142005\n'
                  'Karkuk    : 0750 8957008\n'
                  'Baghdad   : 0770 2961701',
                  style: pw.TextStyle(fontSize: 10),
                ),
              ],
            ),
          ],
        ),
        pw.Row(
          children: [
            pw.Image(qrCode, width: 60),
            pw.SizedBox(width: 10),
            pw.Image(euknetLogo, width: 60),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildMainForm(
    SenderDetails sender,
    ReceiverDetails receiver,
    ShipmentInfo shipment,
    pw.Font baseFont,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildFormField('Sender', sender.name),
        _buildFormField('Receiver', receiver.name),
        _buildFormField('Phone No.', receiver.phone),
        _buildFormField('Item Details', shipment.itemDetails),
        pw.Row(
          children: [
            pw.Expanded(
              child: _buildFormField('Item Number', shipment.itemNumber),
            ),
            pw.Text('Of', style: pw.TextStyle(fontSize: 12)),
          ],
        ),
        _buildFormField('Weight Kg', shipment.weight),
        _buildFormField('City', receiver.city),
        _buildFormField('Country', receiver.country),
        _buildFormField('Code', shipment.code),
      ],
    );
  }

  static pw.Widget _buildFormField(String label, String value) {
    return pw.Container(
      margin: pw.EdgeInsets.symmetric(vertical: 5),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 100,
            child: pw.Text('$label :'),
          ),
          pw.Expanded(
            child: pw.Text(value),
          ),
        ],
      ),
    );
  }
}

enum ShippingLabelLanguage { arabic, english, kurdish }

class ShippingLabelLocalizations {
  final ShippingLabelLanguage language;

  ShippingLabelLocalizations(this.language);

  pw.TextDirection get textDirection =>
      pw.TextDirection.ltr; // Always LTR for English

  Map<String, String> get translations => {
        // Company Info Section
        'company_name': 'Sters Company',
        'company_slogan': 'Leader in International Transport',
        'phone': 'Phone:',
        'branch': 'Branch:',

        // Header Section
        'shipping_label': 'Shipping Label',

        // Sender-Receiver Section
        'sender_info': 'Sender Info',
        'receiver_info': 'Receiver Info',
        'sender_name': 'Sender Name',
        'receiver_name': 'Receiver Name',
        'receiver_phone': 'Receiver Phone',
        'item_details': 'Item Details',
        'item_number': 'Item Number',
        'weight_kg': 'Weight / Kg',
        'city': 'City',
        'country': 'Country',
        'code': 'Code',

        // Footer Section
        'date': 'Date',
        'time': 'Time',
        'volume_difference': 'Volume Difference',
      };
}

// Data models (kept the same)
class ShipmentInfo {
  final String date;
  final String time;
  final String itemDetails;
  final String itemNumber;
  final String weight;
  final String volumeDifference;
  final String code;
  final String branch; // Add branch field
  final String insuranceAmount;
  final String truckNumber;
  const ShipmentInfo({
    required this.date,
    required this.time,
    required this.itemDetails,
    required this.itemNumber,
    required this.weight,
    required this.volumeDifference,
    required this.code,
    required this.branch,
    required this.insuranceAmount,
    required this.truckNumber,
  });
}

class SenderDetails {
  final String name;

  const SenderDetails({
    required this.name,
  });
}

class ReceiverDetails {
  final String name;
  final String phone;
  final String city;
  final String country;
  final String street;
  final String apartment;
  final String zipCode;
  const ReceiverDetails({
    required this.name,
    required this.phone,
    required this.city,
    required this.country,
    required this.street,
    required this.apartment,
    required this.zipCode,
  });
}
