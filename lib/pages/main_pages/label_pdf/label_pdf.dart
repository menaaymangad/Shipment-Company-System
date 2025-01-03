import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Comprehensive shipping label generation class with improved error handling and design
class ShippingLabelGenerator {
  /// List of fallback fonts for Unicode support
  static final List<pw.Font> _fontFallback = [];

  /// Loads Cairo font with error handling and fallback
  static Future<pw.Font> _loadCairoFont({bool isBold = false}) async {
    try {
      final fontPath = isBold
          ? 'fonts/Cairo/static/Cairo-Bold.ttf'
          : 'fonts/Cairo/static/Cairo-Regular.ttf';

      final fontData = await rootBundle.load(fontPath);
      return pw.Font.ttf(fontData);
    } catch (e) {
      debugPrint('Error loading Cairo font: $e');
      // Fallback to a Unicode-supported font
      return pw.Font.times();
    }
  }

  /// Initialize fonts with comprehensive error handling
  static Future<void> _initializeFonts() async {
    try {
      final cairoBold = await _loadCairoFont(isBold: true);
      final cairoRegular = await _loadCairoFont(isBold: false);

      // Add multiple fallback fonts for better Unicode support
      _fontFallback.clear(); // Clear previous fallbacks
      _fontFallback.addAll([
        cairoBold,
        cairoRegular,
        pw.Font.times(), // Times Roman
        pw.Font.helvetica(), // Helvetica
        pw.Font.courier(), // Courier
        pw.Font.zapfDingbats(), // Additional symbol support
      ]);
    } catch (e) {
      debugPrint('Critical error initializing fonts: $e');
    }
  }

  /// Create a standardized text style with fallback fonts
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

  /// Generate shipping label PDF
  static Future<void> generateShippingLabel({
    required SenderDetails sender,
    required ReceiverDetails receiver,
    required ShipmentInfo shipment,
    required Function(Uint8List) onGenerated,
  }) async {
    try {
      await _initializeFonts();
      final pdf = pw.Document();

      final baseFont = await _loadCairoFont();
      final boldFont = await _loadCairoFont(isBold: true);

      final logoImage =
          await _loadAssetImage('assets/icons/Sters Logo N-BG.png');
      final euknetLogo =
          await _loadAssetImage('assets/icons/EUKnet Logo Invoice.png');
      final qrCode = await _loadAssetImage('assets/icons/Sters QR.png');

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) => _buildShippingLabelContent(
            context: context,
            baseFont: baseFont,
            boldFont: boldFont,
            logoImage: logoImage,
            euknetLogo: euknetLogo,
            qrCode: qrCode,
            sender: sender,
            receiver: receiver,
            shipment: shipment,
          ),
        ),
      );

      final pdfData = await pdf.save();
      onGenerated(pdfData);
    } catch (e) {
      debugPrint('Error generating shipping label: $e');
      // Consider providing error callback or rethrow
    }
  }

  /// Build the complete shipping label content
  static pw.Widget _buildShippingLabelContent({
    required pw.Context context,
    required pw.Font baseFont,
    required pw.Font boldFont,
    required pw.MemoryImage logoImage,
    required pw.MemoryImage euknetLogo,
    required pw.MemoryImage qrCode,
    required SenderDetails sender,
    required ReceiverDetails receiver,
    required ShipmentInfo shipment,
  }) {
    return pw.Column(
      children: [
        _buildHeader(logoImage, qrCode, euknetLogo, boldFont),
        pw.SizedBox(height: 20.h),
        _buildShippingDetails(
          sender: sender,
          receiver: receiver,
          shipment: shipment,
          baseFont: baseFont,
          boldFont: boldFont,
        ),
        pw.SizedBox(height: 20.h),
        _buildFooter(shipment, baseFont),
      ],
    );
  }

  /// Build header with contact information and logos
  static pw.Widget _buildHeader(
    pw.MemoryImage logoImage,
    pw.MemoryImage qrCode,
    pw.MemoryImage euknetLogo,
    pw.Font boldFont,
  ) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Image(logoImage, width: 200.w),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildContactInfo(
                'Sulemany', ['0750 8155872', '0770 2120019'], boldFont),
            _buildContactInfo(
                'Hawler', ['07514142005', '0750 8957008'], boldFont),
            _buildContactInfo('Duhok', ['0750 3179286'], boldFont),
            _buildContactInfo('Karkuk', ['0771 4173401'], boldFont),
            _buildContactInfo('Baghdad', ['0770 2961701'], boldFont),
          ],
        ),
        pw.Row(
          children: [
            pw.Image(qrCode, width: 100.w),
            pw.SizedBox(width: 10.w),
            pw.Image(euknetLogo, width: 100.w),
          ],
        ),
      ],
    );
  }

  /// Build shipping details section
  static pw.Widget _buildShippingDetails({
    required SenderDetails sender,
    required ReceiverDetails receiver,
    required ShipmentInfo shipment,
    required pw.Font baseFont,
    required pw.Font boldFont,
  }) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          flex: 4,
          child: pw.Container(
            padding: pw.EdgeInsets.all(10.r),
            decoration: pw.BoxDecoration(border: pw.Border.all()),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Sender', sender.name, boldFont),
                _buildDetailRow('Receiver', receiver.name, boldFont),
                _buildDetailRow('Phone No.', receiver.phone, boldFont),
                _buildDetailRow('Item Details', shipment.itemDetails, boldFont),
                _buildDetailRow('Item Number', shipment.itemNumber,
                    boldFont), // Display item number
                _buildDetailRow('Weight Kg', shipment.weight, boldFont),
                _buildDetailRow('City', receiver.city, boldFont),
                _buildDetailRow('Country', receiver.country, boldFont),
                _buildDetailRow('Code', shipment.code, boldFont),
              ],
            ),
          ),
        ),
        pw.SizedBox(width: 10.w),
        pw.Expanded(
          child: pw.Container(
            padding: pw.EdgeInsets.all(10.r),
            decoration: pw.BoxDecoration(border: pw.Border.all()),
            child: pw.Text(
              shipment.branch.toUpperCase(), // Use the branch field
              style: _createTextStyle(
                font: boldFont,
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Build contact information row
  static pw.Widget _buildContactInfo(
    String location,
    List<String> numbers,
    pw.Font boldFont,
  ) {
    return pw.Row(
      children: [
        pw.Text(
          '$location : ',
          style: _createTextStyle(
            font: boldFont,
            fontSize: 20,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.Text(numbers.join(' / '),
            style: _createTextStyle(font: boldFont, fontSize: 16)),
      ],
    );
  }

  /// Build a detail row with label and value
  static pw.Widget _buildDetailRow(
    String label,
    String value,
    pw.Font baseFont,
  ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 120.w,
            child: pw.Text(
              label,
              style: _createTextStyle(
                font: baseFont,
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.Text(' : ', style: _createTextStyle(font: baseFont, fontSize: 16)),
          pw.Expanded(
            child: pw.Text(
              value,
              style: _createTextStyle(font: baseFont, fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }

  /// Build footer with shipment details
  static pw.Widget _buildFooter(ShipmentInfo shipment, pw.Font baseFont) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          'Date: ${shipment.date}',
          style: _createTextStyle(font: baseFont, fontSize: 16),
        ),
        pw.Text(
          'Time: ${shipment.time}',
          style: _createTextStyle(font: baseFont, fontSize: 16),
        ),
        pw.Text(
          'Volume Difference: ${shipment.volumeDifference}',
          style: _createTextStyle(font: baseFont, fontSize: 16),
        ),
      ],
    );
  }
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

  const ShipmentInfo({
    required this.date,
    required this.time,
    required this.itemDetails,
    required this.itemNumber,
    required this.weight,
    required this.volumeDifference,
    required this.code,
    required this.branch, // Add branch field
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

  const ReceiverDetails({
    required this.name,
    required this.phone,
    required this.city,
    required this.country,
  });
}
