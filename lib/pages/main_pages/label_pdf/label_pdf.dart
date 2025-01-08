import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Comprehensive shipping label generation class with improved error handling and design
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
    required pw.Font regularFont,
    required pw.Font boldFont,
    required Function(Uint8List) onGenerated,
    required ShippingLabelLanguage language, // Add language parameter
  }) async {
    try {
      await initializeFonts();
      final pdf = pw.Document();

      final logoImage =
          await _loadAssetImage('assets/icons/Sters Logo N-BG.png');
      final euknetLogo =
          await _loadAssetImage('assets/icons/EUKnet Logo Invoice.png');
      final qrCode = await _loadAssetImage('assets/icons/Sters QR.png');

      final translations =
          ShippingLabelLocalizations(language); // Initialize translations

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) => _buildShippingLabelContent(
            context: context,

            logoImage: logoImage,
            euknetLogo: euknetLogo,
            qrCode: qrCode,
            sender: sender,
            receiver: receiver,
            shipment: shipment,
            translations: translations, baseFont: regularFont,
            boldFont: boldFont, // Pass translations to the content builder
          ),
        ),
      );

      final pdfData = await pdf.save();
      onGenerated(pdfData);
    } catch (e) {
      debugPrint('Error generating shipping label: $e');
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
    required ShippingLabelLocalizations
        translations, // Add translations parameter
  }) {
    return pw.Column(
      children: [
        _buildHeader(logoImage, qrCode, euknetLogo, boldFont, translations),
        pw.SizedBox(height: 20.h),
        _buildShippingDetails(
          sender: sender,
          receiver: receiver,
          shipment: shipment,
          baseFont: baseFont,
          boldFont: boldFont,
          translations:
              translations, // Pass translations to the details builder
        ),
        pw.SizedBox(height: 20.h),
        _buildFooter(shipment, baseFont,
            translations), // Pass translations to the footer builder
      ],
    );
  }

  /// Build header with contact information and logos
  static pw.Widget _buildHeader(
    pw.MemoryImage logoImage,
    pw.MemoryImage qrCode,
    pw.MemoryImage euknetLogo,
    pw.Font boldFont,
    ShippingLabelLocalizations translations, // Add translations parameter
  ) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Image(logoImage, width: 200.w),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildContactInfo('Sulemany', ['0750 8155872', '0770 2120019'],
                boldFont, translations),
            _buildContactInfo('Hawler', ['07514142005', '0750 8957008'],
                boldFont, translations),
            _buildContactInfo(
                'Duhok', ['0750 3179286'], boldFont, translations),
            _buildContactInfo(
                'Karkuk', ['0771 4173401'], boldFont, translations),
            _buildContactInfo(
                'Baghdad', ['0770 2961701'], boldFont, translations),
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
    required ShippingLabelLocalizations
        translations, // Add translations parameter
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
                _buildDetailRow(translations.translations['sender_name']!,
                    sender.name, boldFont, translations),
                _buildDetailRow(translations.translations['receiver_name']!,
                    receiver.name, boldFont, translations),
                _buildDetailRow(translations.translations['receiver_phone']!,
                    receiver.phone, boldFont, translations),
                _buildDetailRow(translations.translations['item_details']!,
                    shipment.itemDetails, boldFont, translations),
                _buildDetailRow(translations.translations['item_number']!,
                    shipment.itemNumber, boldFont, translations),
                _buildDetailRow(translations.translations['weight_kg']!,
                    shipment.weight, boldFont, translations),
                _buildDetailRow(translations.translations['city']!,
                    receiver.city, boldFont, translations),
                _buildDetailRow(translations.translations['country']!,
                    receiver.country, boldFont, translations),
                _buildDetailRow(translations.translations['code']!,
                    shipment.code, boldFont, translations),
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
              shipment.branch.toUpperCase(),
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
    ShippingLabelLocalizations translations, // Add translations parameter
  ) {
    return pw.Row(
      children: [
        pw.Text(
          textDirection: translations.textDirection,
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
    ShippingLabelLocalizations translations, // Add translations parameter
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
              textDirection: translations.textDirection,
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
              textDirection: translations.textDirection,
              value,
              style: _createTextStyle(font: baseFont, fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }

  /// Build footer with shipment details
  static pw.Widget _buildFooter(ShipmentInfo shipment, pw.Font baseFont,
      ShippingLabelLocalizations translations) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          textDirection: translations.textDirection,
          '${translations.translations['date']!}: ${shipment.date}',
          style: _createTextStyle(font: baseFont, fontSize: 20),
        ),
        pw.Text(
          textDirection: translations.textDirection,
          '${translations.translations['time']!}: ${shipment.time}',
          style: _createTextStyle(font: baseFont, fontSize: 20),
        ),
        pw.Text(
          textDirection: translations.textDirection,
          '${translations.translations['volume_difference']!}: ${shipment.volumeDifference}',
          style: _createTextStyle(font: baseFont, fontSize: 20),
        ),
      ],
    );
  }
}

enum ShippingLabelLanguage { arabic, english, kurdish }

class ShippingLabelLocalizations {
  final ShippingLabelLanguage language;

  ShippingLabelLocalizations(this.language);

  pw.TextDirection get textDirection {
    switch (language) {
      case ShippingLabelLanguage.english:
        return pw.TextDirection.ltr;
      case ShippingLabelLanguage.arabic:
      case ShippingLabelLanguage.kurdish:
        return pw.TextDirection.rtl;
    }
  }

  Map<String, String> get translations => {
        // Company Info Section
        'company_name':
            _getTranslation('شركة ستيرس', 'Sters Company', 'کۆمپانیای ستێرس'),
        'company_slogan': _getTranslation(
            'الرائدة في مجال النقل الدولي',
            'Leader in International Transport',
            'پێشەنگ لە بواری گواستنەوەی نێودەوڵەتی'),
        'phone': _getTranslation('الهاتف:', 'Phone:', 'تەلەفۆن:'),
        'branch': _getTranslation('فرع:', 'Branch:', 'لق:'),

        // Header Section
        'shipping_label':
            _getTranslation('ملصق الشحن', 'Shipping Label', 'پلاکی گواستنەوە'),

        // Sender-Receiver Section
        'sender_info':
            _getTranslation('معلومات المرسل', 'Sender Info', 'زانیاری نێردەر'),
        'receiver_info': _getTranslation(
            'معلومات المستلم', 'Receiver Info', 'زانیاری وەرگر'),
        'sender_name':
            _getTranslation('اسم المرسل', 'Sender Name', 'ناوی نێردەر'),
        'receiver_name':
            _getTranslation('اسم المستلم', 'Receiver Name', 'ناوی وەرگر'),
        'receiver_phone': _getTranslation(
            'رقم هاتف المستلم', 'Receiver Phone', 'ژمارەی وەرگر'),
        'item_details': _getTranslation(
            'تفاصيل البضاعة', 'Item Details', 'زانیاری کاڵاکان'),
        'item_number':
            _getTranslation('رقم البضاعة', 'Item Number', 'ژمارەی کاڵا'),
        'weight_kg':
            _getTranslation('الوزن / كغم', 'Weight / Kg', 'کێش / کیلۆگرام'),
        'city': _getTranslation('المدينة', 'City', 'شار'),
        'country': _getTranslation('الدولة', 'Country', 'وڵات'),
        'code': _getTranslation('الكود', 'Code', 'کۆد'),

        // Footer Section
        'date': _getTranslation('التاريخ', 'Date', 'بەروار'),
        'time': _getTranslation('الوقت', 'Time', 'کات'),
        'volume_difference': _getTranslation(
            'الفرق في الحجم', 'Volume Difference', 'جیاوازیی قەبارە'),
      };

  String _getTranslation(String arabic, String english, String kurdish) {
    switch (language) {
      case ShippingLabelLanguage.arabic:
        return arabic;
      case ShippingLabelLanguage.english:
        return english;
      case ShippingLabelLanguage.kurdish:
        return kurdish;
    }
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
