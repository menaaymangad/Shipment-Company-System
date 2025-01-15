import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show ByteData, rootBundle;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PDFGenerator {
  // Add a list of fallback fonts
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

  static pw.TextStyle getTextStyle({
    required pw.Font baseFont,
    required double fontSize,
    PdfColor? color,
    pw.FontWeight? fontWeight,
    pw.TextDirection? textDirection,
  }) {
    return pw.TextStyle(
      font: baseFont,
      fontSize: fontSize,
      color: color,
      fontWeight: fontWeight,
      fontFallback: _fontFallback,
    );
  }

  static Future<Uint8List> loadAssetImage(String assetPath) async {
    final ByteData data = await rootBundle.load(assetPath);
    return data.buffer.asUint8List();
  }

  static Future<File> generateInvoice({
    required ShipmentDetails shipment,
    required SenderInfo sender,
    required ReceiverInfo receiver,
    required CostSummary costs,
    required pw.Font regularFont,
    required pw.Font boldFont,
    required InvoiceLanguage language,
  }) async {
    final translations = InvoiceLocalizations(language);

    // Initialize the PDF document
    final pdf = pw.Document();
    await initializeFonts();

    // Load images (keeping the existing image loading code)
    final euknetLogo = pw.MemoryImage(
        await loadAssetImage('assets/icons/EUKnet Logo Invoice.png'));
    final stersLogo = pw.MemoryImage(
        await loadAssetImage('assets/icons/Sters Logo N-BG.png'));
    final qrCode =
        pw.MemoryImage(await loadAssetImage('assets/icons/Sters QR.png'));

    // Await the terms and conditions section before adding it to the PDF
    final termsAndConditions = await buildTermsAndConditionsSection(
        regularFont, boldFont, translations);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(5.r),
        build: (context) => pw.Container(
          decoration: pw.BoxDecoration(
            color: PdfColors.white,
            border: pw.Border.all(color: PdfColors.black),
          ),
          alignment: translations.textDirection == pw.TextDirection.rtl
              ? pw.Alignment.centerRight
              : pw.Alignment.centerLeft,
          child: pw.Column(
            mainAxisSize: pw.MainAxisSize.max,
            crossAxisAlignment:
                translations.textDirection == pw.TextDirection.rtl
                    ? pw.CrossAxisAlignment.end
                    : pw.CrossAxisAlignment.start,
            children: [
              buildHeader(
                  euknetLogo, stersLogo, boldFont, receiver, translations),
              buildTitleBar(boldFont, translations),
              buildCodeSection(shipment, regularFont, translations),
              pw.SizedBox(height: 20.h),
              buildSenderReceiverAndCostsSection(
                sender,
                receiver,
                costs,
                regularFont,
                boldFont,
                qrCode,
                translations,
              ),
              pw.SizedBox(height: 20.h),
              termsAndConditions, // Use the awaited result here
            ],
          ),
        ),
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File(
        '${output.path}/invoice_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  // Updated buildHeader method to use translations
  static pw.Widget buildHeader(
      pw.ImageProvider euknetLogo,
      pw.ImageProvider stersLogo,
      pw.Font boldFont,
      ReceiverInfo receiver,
      InvoiceLocalizations translations) {
    return pw.Padding(
      padding: pw.EdgeInsets.symmetric(horizontal: 10.w),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Image(euknetLogo, width: 600.w, height: 60.h),
          pw.Column(
            children: [
              pw.Text(
                translations.translations['company_name']!,
                style: getTextStyle(baseFont: boldFont, fontSize: 24.sp),
                textDirection: translations.textDirection,
              ),
              pw.SizedBox(height: 5.h),
              pw.Text(
                translations.translations['company_slogan']!,
                style: getTextStyle(baseFont: boldFont, fontSize: 20.sp),
                textDirection: translations.textDirection,
              ),
              pw.SizedBox(height: 5.h),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Row(
                    children: [
                      pw.Text(
                        '07702961701\t07721001999',
                        style:
                            getTextStyle(baseFont: boldFont, fontSize: 20.sp),
                      ),
                      pw.SizedBox(width: 5.w),
                      pw.Text(
                        translations.translations['phone']!,
                        style:
                            getTextStyle(baseFont: boldFont, fontSize: 20.sp),
                        textDirection: translations.textDirection,
                      ),
                    ],
                  ),
                  pw.SizedBox(width: 60.w),
                  pw.Row(
                    children: [
                      pw.Text(
                        receiver.branch,
                        style:
                            getTextStyle(baseFont: boldFont, fontSize: 20.sp),
                      ),
                      pw.SizedBox(width: 10.w),
                      pw.Text(
                        translations.translations['branch']!,
                        style:
                            getTextStyle(baseFont: boldFont, fontSize: 20.sp),
                        textDirection: translations.textDirection,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          pw.Image(stersLogo, width: 100.w, height: 60.h),
        ],
      ),
    );
  }

// Updated buildTitleBar method to use translations
  static pw.Widget buildTitleBar(
      pw.Font boldFont, InvoiceLocalizations translations) {
    return pw.Container(
      width: double.infinity,
      decoration: const pw.BoxDecoration(
        color: PdfColors.blue900,
      ),
      padding: pw.EdgeInsets.symmetric(vertical: 8.h),
      child: pw.Center(
        child: pw.Text(
          translations.translations['delivery_receipt']!,
          style: getTextStyle(
              baseFont: boldFont, fontSize: 20.sp, color: PdfColors.white),
          textDirection: translations.textDirection,
        ),
      ),
    );
  }

// Updated buildCodeSection method to use translations
  static pw.Widget buildCodeSection(ShipmentDetails shipment,
      pw.Font regularFont, InvoiceLocalizations translations) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#FFB99B'),
        border: const pw.Border(
          bottom: pw.BorderSide(color: PdfColors.black, width: 1),
          top: pw.BorderSide(color: PdfColors.black, width: 1),
        ),
      ),
      padding: pw.EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Code:     ${shipment.codeNumber}',
            style: getTextStyle(baseFont: regularFont, fontSize: 20.sp),
          ),
          pw.Row(
            children: [
              pw.Text(
                translations.translations['code']!,
                style: getTextStyle(baseFont: regularFont, fontSize: 20.sp),
                textDirection: translations.textDirection,
              ),
              pw.SizedBox(width: 10.w),
              pw.Container(
                padding: pw.EdgeInsets.only(left: 10.w),
                decoration: const pw.BoxDecoration(
                    border: pw.Border(
                        left: pw.BorderSide(color: PdfColors.black, width: 1))),
                child: pw.Text(
                  '${translations.translations['date']!} ${shipment.date}',
                  style: getTextStyle(baseFont: regularFont, fontSize: 16.sp),
                  textDirection: translations.textDirection,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  // Add these methods to your PDFGenerator class

  static pw.Widget buildSenderReceiverAndCostsSection(
    SenderInfo sender,
    ReceiverInfo receiver,
    CostSummary costs,
    pw.Font regularFont,
    pw.Font boldFont,
    pw.ImageProvider qrCode,
    InvoiceLocalizations translations, // Add translations parameter
  ) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Left side - Sender-Receiver Info
        pw.Expanded(
          child: pw.Container(
            height: 800.h,
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black, width: 1),
            ),
            child: pw.Column(
              children: [
                // Header
                pw.Container(
                  width: double.infinity,
                  decoration: pw.BoxDecoration(
                    border: pw.Border(
                        bottom:
                            pw.BorderSide(color: PdfColors.black, width: 3.w)),
                  ),
                  padding: pw.EdgeInsets.symmetric(vertical: 8.h),
                  child: pw.Text(
                    translations.translations[
                        'sender_receiver_info']!, // Localized header
                    style: getTextStyle(baseFont: boldFont, fontSize: 24.sp),
                    textAlign: pw.TextAlign.center,
                    textDirection: translations.textDirection,
                  ),
                ),

                // Info Rows
                buildTableRow(translations.translations['sender_name']!,
                    sender.name, regularFont, translations.textDirection),
                buildTableRow(translations.translations['sender_phone']!,
                    sender.phone, regularFont, translations.textDirection),
                buildTableRow(translations.translations['receiver_name']!,
                    receiver.name, regularFont, translations.textDirection),
                buildTableRow(translations.translations['receiver_phone']!,
                    receiver.phone, regularFont, translations.textDirection),
                buildTableRow(translations.translations['address']!,
                    receiver.street, regularFont, translations.textDirection),
                buildTableRow(translations.translations['postal_code']!,
                    receiver.zipCode, regularFont, translations.textDirection),
                buildTableRow(translations.translations['city']!, receiver.city,
                    regularFont, translations.textDirection),
                buildTableRow(translations.translations['country']!,
                    receiver.country, regularFont, translations.textDirection),

                // Agent Info Header
                pw.Container(
                  height: 95.h,
                  width: double.infinity,
                  decoration: pw.BoxDecoration(
                    border: pw.Border(
                        top: pw.BorderSide(color: PdfColors.black, width: 5.w)),
                  ),
                  padding: pw.EdgeInsets.symmetric(vertical: 8.h),
                  child: pw.Text(
                    translations
                        .translations['agent_info']!, // Localized agent info
                    style: getTextStyle(baseFont: boldFont, fontSize: 20.sp),
                    textAlign: pw.TextAlign.center,
                    textDirection: translations.textDirection,
                  ),
                ),

                // QR Code
                pw.Container(
                  padding: pw.EdgeInsets.all(10.r),
                  child: pw.Image(qrCode, width: 120.w, height: 120.h),
                ),
              ],
            ),
          ),
        ),

        pw.SizedBox(width: 15.w),

        // Right side - Costs Table
        pw.Expanded(
          child: pw.Container(
            height: 800.h,
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black, width: 3.w),
            ),
            child: pw.Column(
              children: [
                // Header
                pw.Container(
                  width: double.infinity,
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                        bottom:
                            pw.BorderSide(color: PdfColors.black, width: 1)),
                  ),
                  padding: pw.EdgeInsets.symmetric(vertical: 8.h),
                  child: pw.Text(
                    translations
                        .translations['transport_costs']!, // Localized header
                    style: getTextStyle(baseFont: boldFont, fontSize: 24.sp),
                    textAlign: pw.TextAlign.center,
                    textDirection: translations.textDirection,
                  ),
                ),

                // Cost Rows
                buildCostTableRow(
                    translations.translations['shipping_cost']!,
                    costs.shippingCost,
                    regularFont,
                    translations.textDirection),
                buildCostTableRow(translations.translations['empty_box_cost']!,
                    '', regularFont, translations.textDirection),
                buildCostTableRow(translations.translations['customs_admin']!,
                    '', regularFont, translations.textDirection),
                buildCostTableRow(translations.translations['delivery_cost']!,
                    '', regularFont, translations.textDirection),
                buildCostTableRow(
                    translations.translations['insurance_cost']!,
                    costs.insuranceAmount,
                    regularFont,
                    translations.textDirection),
                buildCostTableRow(translations.translations['total_cost']!,
                    costs.totalCost, regularFont, translations.textDirection),
                buildCostTableRow(
                    translations.translations['amount_paid']!,
                    costs.amountPaid,
                    regularFont,
                    highlighted: true,
                    translations.textDirection),
                buildCostTableRow(translations.translations['amount_due']!,
                    costs.amountDue, regularFont, translations.textDirection),
                buildCostTableRow(translations.translations['amount_due_eur']!,
                    '', regularFont, translations.textDirection),

                // Insurance Section
                pw.Container(
                  padding: pw.EdgeInsets.all(8.r),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.end,
                    children: [
                      pw.Expanded(
                        child: buildCheckbox(translations.translations['no']!,
                            regularFont, translations.textDirection),
                      ),
                      pw.SizedBox(width: 20.w),
                      pw.Expanded(
                        child: buildCheckbox(translations.translations['yes']!,
                            regularFont, translations.textDirection),
                      ),
                      pw.SizedBox(width: 40.w),
                      pw.Expanded(
                        child: pw.Text(
                          translations.translations['insurance']!,
                          style: getTextStyle(
                              baseFont: regularFont, fontSize: 24.sp),
                          textDirection: translations.textDirection,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.Flexible(
                  child: pw.Table(
                    border: pw.TableBorder.all(),
                    children: [
                      pw.TableRow(
                        children: [
                          buildTableHeader(
                              translations.translations['number_of_boxes']!,
                              regularFont),
                          buildTableHeader(
                              translations.translations['weight_kg']!,
                              regularFont),
                          buildTableHeader(
                              translations.translations['goods_details']!,
                              regularFont),
                          buildTableHeader(
                              translations.translations['goods_value']!,
                              regularFont),
                        ],
                      ),
                      pw.TableRow(
                        children: [
                          pw.Container(),
                          pw.Container(),
                          pw.Container(),
                          pw.Container(height: 125.h),
                        ],
                      ),
                    ],
                  ),
                ),
                // Bottom Table
              ],
            ),
          ),
        ),
      ],
    );
  }
  // Update these methods in your PDFGenerator class

  static pw.Widget buildTableRow(
    String label,
    String value,
    pw.Font font,
    pw.TextDirection textDirection,
  ) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.black, width: 0.5.w),
        ),
      ),
      padding: pw.EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      child: pw.Row(
        mainAxisAlignment: textDirection == pw.TextDirection.rtl
            ? pw.MainAxisAlignment.end
            : pw.MainAxisAlignment.start,
        children: [
          pw.Expanded(
            flex: 3,
            child: pw.Padding(
              padding: pw.EdgeInsets.only(
                right: textDirection == pw.TextDirection.rtl ? 0 : 8.w,
                left: textDirection == pw.TextDirection.rtl ? 8.w : 0,
              ),
              child: pw.Text(
                value,
                style: getTextStyle(baseFont: font, fontSize: 20.sp),
                textDirection: textDirection,
              ),
            ),
          ),
          pw.Container(width: 1, color: PdfColors.black, height: 20.h),
          pw.Expanded(
            flex: 2,
            child: pw.Text(
              label,
              style: getTextStyle(baseFont: font, fontSize: 20.sp),
              textAlign: textDirection == pw.TextDirection.rtl
                  ? pw.TextAlign.right
                  : pw.TextAlign.left,
              textDirection: textDirection,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget buildCostTableRow(
    String label,
    String value,
    pw.Font font,
    pw.TextDirection textDirection, {
    bool highlighted = false,
  }) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        color: highlighted ? PdfColor.fromHex('#FFB99B') : null,
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.black, width: 0.5.w),
        ),
      ),
      padding: pw.EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      child: pw.Row(
        mainAxisAlignment: textDirection == pw.TextDirection.rtl
            ? pw.MainAxisAlignment.end
            : pw.MainAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Center(
              child: pw.Text(
                'دينار عراقي',
                style: getTextStyle(baseFont: font, fontSize: 20.sp),
                textAlign: textDirection == pw.TextDirection.rtl
                    ? pw.TextAlign.right
                    : pw.TextAlign.left,
                textDirection: textDirection,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Padding(
              padding: pw.EdgeInsets.only(
                right: textDirection == pw.TextDirection.rtl ? 0 : 8.w,
                left: textDirection == pw.TextDirection.rtl ? 8.w : 0,
              ),
              child: pw.Text(
                value,
                style: getTextStyle(baseFont: font, fontSize: 20.sp),
                textDirection: textDirection,
              ),
            ),
          ),
          pw.Container(width: 1, color: PdfColors.black, height: 20.h),
          pw.Expanded(
            flex: 3,
            child: pw.Text(
              label,
              style: getTextStyle(baseFont: font, fontSize: 20.sp),
              textAlign: textDirection == pw.TextDirection.rtl
                  ? pw.TextAlign.right
                  : pw.TextAlign.left,
              textDirection: textDirection,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget buildTableHeader(String text, pw.Font font) {
    return pw.Container(
      padding: pw.EdgeInsets.all(5.r),
      child: pw.Text(
        text,
        style: getTextStyle(baseFont: font, fontSize: 24.sp),
        textAlign: pw.TextAlign.right,
        textDirection: pw.TextDirection.rtl,
      ),
    );
  }

  static pw.Widget buildCheckbox(
    String label,
    pw.Font font,
    pw.TextDirection textDirection,
  ) {
    return pw.Row(
      children: [
        if (textDirection == pw.TextDirection.rtl) ...[
          pw.Text(
            label,
            style: getTextStyle(baseFont: font, fontSize: 16.sp),
            textDirection: textDirection,
          ),
          pw.SizedBox(width: 5.w),
        ],
        pw.Container(
          width: 20.w,
          height: 20.h,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.black),
          ),
        ),
        if (textDirection == pw.TextDirection.ltr) ...[
          pw.SizedBox(width: 5.w),
          pw.Text(
            label,
            style: getTextStyle(baseFont: font, fontSize: 16.sp),
            textDirection: textDirection,
          ),
        ],
      ],
    );
  }

  static Future<pw.Widget> buildTermsAndConditionsSection(
    pw.Font regularFont,
    pw.Font boldFont,
    InvoiceLocalizations translations,
  ) async {
    if (kDebugMode) {
      print('Building Terms and Conditions Section');
      print('Language: ${translations.language}');
      print('Terms 1: ${translations.translations['terms_1']}');
    }
    // Load images
    final prohibitedIconsImage1 =
        pw.MemoryImage(await loadAssetImage('assets/icons/02.png'));
    final prohibitedIconsImage2 =
        pw.MemoryImage(await loadAssetImage('assets/icons/03.png'));
    final prohibitedIconsImage3 = pw.MemoryImage(
        await loadAssetImage('assets/icons/Sters Logo N-BG (1).png'));

    return pw.Container(
      alignment: pw.Alignment.centerLeft,
      decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.black, width: 0.5.w)),
      margin: pw.EdgeInsets.only(top: 20.h),
      child: pw.Column(
        // crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        crossAxisAlignment: translations.textDirection == pw.TextDirection.rtl
            ? pw.CrossAxisAlignment.end
            : pw.CrossAxisAlignment.start, // Added this line
        children: [
          // Title with improved styling
          pw.Container(
            width: double.infinity,
            padding: pw.EdgeInsets.symmetric(vertical: 8.h),
            decoration: pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: PdfColors.black, width: 0.5.w),
              ),
            ),
            child: pw.Text(
              translations.translations['terms_and_conditions_title']!,
              style: getTextStyle(
                baseFont: boldFont,
                fontSize: 24.sp,
                color: PdfColors.red,
              ),
              textAlign: pw.TextAlign.center,
              textDirection: translations.textDirection,
            ),
          ),

          // Main content with improved layout
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Left side - Icons with fixed width
              pw.Container(
                width: 200.w, // Fixed width for consistency
                child: pw.Column(
                  children: [
                    pw.Container(
                      decoration: pw.BoxDecoration(
                        border:
                            pw.Border.all(color: PdfColors.black, width: 0.5.w),
                      ),
                      padding: pw.EdgeInsets.all(10.r),
                      child: pw.Column(
                        children: [
                          pw.Image(prohibitedIconsImage1),
                          pw.SizedBox(height: 10.h),
                          pw.Image(prohibitedIconsImage2),
                        ],
                      ),
                    ),
                    pw.Container(
                      decoration: pw.BoxDecoration(
                        border:
                            pw.Border.all(color: PdfColors.black, width: 0.5.w),
                      ),
                      padding: pw.EdgeInsets.all(10.r),
                      height: 200.h,
                      child: pw.Center(
                        child: pw.Image(prohibitedIconsImage3),
                      ),
                    ),
                  ],
                ),
              ),

              // Right side - Terms text with improved spacing
              pw.Expanded(
                flex: 3, // Give more space to the terms
                child: pw.Container(
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.black, width: 0.5.w),
                  ),
                  padding: pw.EdgeInsets.all(15.r),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      for (var i = 1; i <= 7; i++)
                        pw.Padding(
                          padding: pw.EdgeInsets.only(bottom: 10.h),
                          child: buildTermItem(
                            i.toString(),
                            translations.translations['terms_$i']!,
                            regularFont,
                          ),
                        ),
                      // Sub-items for term 3 with proper indentation
                      if (translations.translations.containsKey('terms_3a') &&
                          translations.translations.containsKey('terms_3b'))
                        pw.Padding(
                          padding: pw.EdgeInsets.only(right: 20.w),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.end,
                            children: [
                              buildTermItem(
                                'أ',
                                translations.translations['terms_3a']!,
                                regularFont,
                              ),
                              pw.SizedBox(height: 5.h),
                              buildTermItem(
                                'ب',
                                translations.translations['terms_3b']!,
                                regularFont,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Footer with improved layout
          pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border(
                top: pw.BorderSide(color: PdfColors.black, width: 0.5.w),
              ),
            ),
            padding: pw.EdgeInsets.all(15.r),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Expanded(
                  flex: 2,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        '${translations.translations['email']!} info@euknet.com',
                        style: getTextStyle(
                            baseFont: regularFont, fontSize: 20.sp),
                      ),
                      pw.Text(
                        '${translations.translations['website']!} www.euknet.com',
                        style: getTextStyle(
                            baseFont: regularFont, fontSize: 20.sp),
                      ),
                    ],
                  ),
                ),
                pw.Container(
                  padding: pw.EdgeInsets.symmetric(horizontal: 20.w),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.symmetric(
                      vertical:
                          pw.BorderSide(color: PdfColors.black, width: 0.5.w),
                    ),
                  ),
                  child: pw.Text(
                    translations.translations['main_office_europe']!,
                    style: getTextStyle(baseFont: boldFont, fontSize: 20.sp),
                    textDirection: translations.textDirection,
                    textAlign: pw.TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Improved term item builder
  static pw.Widget buildTermItem(String number, String text, pw.Font font) {
    return pw.Container(
      margin: pw.EdgeInsets.only(bottom: 8.h),
      child: pw.RichText(
        text: pw.TextSpan(
          children: [
            pw.TextSpan(
              text: '$number - ',
              style: getTextStyle(
                baseFont: font,
                fontSize: 24.sp,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.TextSpan(
              text: text,
              style: getTextStyle(baseFont: font, fontSize: 16.sp),
            ),
          ],
        ),
        textDirection: pw.TextDirection.rtl,
        textAlign: pw.TextAlign.right,
      ),
    );
  }

  // Optional: Method to preview or print the PDF
  static Future<void> printPDF(File pdfFile) async {
    try {
      if (Platform.isWindows) {
        // Windows-specific printing with more robust error handling
        await Printing.layoutPdf(
          onLayout: (format) => pdfFile.readAsBytesSync(),
          name: 'Invoice',
          usePrinterSettings: true,
        );
      } else {
        // Default printing for other platforms
        await Printing.layoutPdf(
          onLayout: (format) => pdfFile.readAsBytesSync(),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Printing Error: $e');
      }
      // Consider adding more specific error handling
      throw Exception('Failed to print PDF: $e');
    }
  }
}

// Data classes for better organization
class ShipmentDetails {
  final String date;
  final String truckNumber;
  final String codeNumber;
  final String boxNumber;
  final String totalWeight;
  final String description;

  ShipmentDetails({
    required this.date,
    required this.truckNumber,
    required this.codeNumber,
    required this.boxNumber,
    required this.totalWeight,
    required this.description,
  });
}

class SenderInfo {
  final String name;
  final String phone;
  final String id;

  SenderInfo({
    required this.name,
    required this.phone,
    required this.id,
  });
}

class ReceiverInfo {
  final String name;
  final String phone;
  final String street;
  final String apartment;
  final String city;
  final String country;
  final String zipCode;
  final String branch;
  ReceiverInfo({
    required this.name,
    required this.phone,
    required this.street,
    required this.apartment,
    required this.city,
    required this.country,
    required this.zipCode,
    required this.branch,
  });
}

class CostSummary {
  final String shippingCost;
  final String insuranceAmount;
  final String totalCost;
  final String amountPaid;
  final String amountDue;
  final String totalCostEur;
  final String amountDueEur;

  CostSummary({
    required this.shippingCost,
    required this.insuranceAmount,
    required this.totalCost,
    required this.amountPaid,
    required this.amountDue,
    required this.totalCostEur,
    required this.amountDueEur,
  });
}

class InvoiceLocalizations {
  final InvoiceLanguage language;

  InvoiceLocalizations(this.language);

  pw.TextDirection get textDirection {
    switch (language) {
      case InvoiceLanguage.english:
        return pw.TextDirection.ltr;
      case InvoiceLanguage.arabic:
      case InvoiceLanguage.kurdish:
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
        'delivery_receipt': _getTranslation(
            'وصل تسليم ودفع تكاليف النقل الى اوروبا',
            'Delivery Receipt and Transport Costs to Europe',
            'پسوولەی گەیاندن و پارەدانی تێچووی گواستنەوە بۆ ئەوروپا'),
        'code':
            _getTranslation('كود الاستلام :', 'Receipt Code:', 'کۆدی وەرگرتن:'),
        'date': _getTranslation('التاريخ:', 'Date:', 'بەروار:'),

        // Sender-Receiver Section
        'sender_receiver_info': _getTranslation('معلومات المرسل - المستلم',
            'Sender - Receiver Info', 'زانیاری نێردەر - وەرگر'),
        'sender_name':
            _getTranslation('اسم المرسل', 'Sender Name', 'ناوی نێردەر'),
        'sender_phone':
            _getTranslation('رقم هاتف المرسل', 'Sender Phone', 'ژمارەی نێردەر'),
        'receiver_name':
            _getTranslation('اسم المستلم', 'Receiver Name', 'ناوی وەرگر'),
        'receiver_phone': _getTranslation(
            'رقم هاتف المستلم', 'Receiver Phone', 'ژمارەی وەرگر'),
        'address': _getTranslation(
            'العنوان الكامل', 'Full Address', 'ناونیشانی تەواو'),
        'postal_code':
            _getTranslation('الرمز البريدي', 'Postal Code', 'کۆدی پۆستە'),
        'city': _getTranslation('المدينة', 'City', 'شار'),
        'country': _getTranslation('الدولة', 'Country', 'وڵات'),
        'agent_info':
            _getTranslation('معلومات الوكيل', 'Agent Info', 'زانیاری وەکیل'),

        // Costs Section
        'transport_costs': _getTranslation(
            'تكاليف النقل', 'Transport Costs', 'تێچووی گواستنەوە'),
        'shipping_cost':
            _getTranslation('كلفة النقل', 'Shipping Cost', 'تێچووی گواستنەوە'),
        'empty_box_cost': _getTranslation(
            'قيمة الكارتون الفارغ', 'Empty Box Cost', 'نرخی سندوقی بەتاڵ'),
        'customs_admin': _getTranslation(
            'الكمرك والاداريات', 'Customs & Administration', 'گومرگ و کارگێڕی'),
        'delivery_cost': _getTranslation(
            'كلفة التوصيل الى عنوان المستلم',
            'Delivery Cost to Receiver Address',
            'تێچووی گەیاندن بۆ ناونیشانی وەرگر'),
        'insurance_cost':
            _getTranslation('كلفة التأمين', 'Insurance Cost', 'تێچووی دڵنیایی'),
        'total_cost':
            _getTranslation('الكلفة الكلية', 'Total Cost', 'کۆی گشتی تێچوو'),
        'amount_paid':
            _getTranslation('المبلغ المدفوع', 'Amount Paid', 'بڕی پارەی دراو'),
        'amount_due': _getTranslation(
            'المبلغ المطلوب', 'Amount Due', 'بڕی پارەی داواکراو'),
        'amount_due_eur': _getTranslation('المبلغ المطلوب دفعه في اوروبا',
            'Amount Due in EUR', 'بڕی پارەی داواکراو بە یورۆ'),

        // Insurance Section
        'insurance': _getTranslation('تأمين البضاعة', 'Insurance', 'دڵنیایی'),
        'yes': _getTranslation('نعم', 'Yes', 'بەڵێ'),
        'no': _getTranslation('كلا', 'No', 'نەخێر'),

        // Footer Section
        'footer_notes': _getTranslation('الملاحظات', 'Notes', 'تێبینییەکان'),
        'contact_info': _getTranslation(
            'معلومات الاتصال', 'Contact Info', 'زانیاری پەیوەندی'),
        'main_office': _getTranslation(
            'المكتب الرئيسي', 'Main Office', 'نووسینگەی سەرەکی'),
        'email': _getTranslation('البريد الالكتروني:', 'Email:', 'ئیمەیڵ:'),
        'website': _getTranslation('الموقع الالكتروني:', 'Website:', 'ماڵپەڕ:'),

        // Goods Details Section
        'number_of_boxes': _getTranslation(
            'عدد الكراتين', 'Number of Boxes', 'ژمارەی سندوقەکان'),
        'weight_kg':
            _getTranslation('الوزن / كغم', 'Weight / Kg', 'کێش / کیلۆگرام'),
        'goods_details': _getTranslation(
            'تفاصيل البضاعة', 'Goods Details', 'زانیاری کاڵاکان'),
        'goods_value':
            _getTranslation('قيمة البضاعة', 'Goods Value', 'نرخی کاڵاکان'),
        // Terms and Conditions Section
        'terms_and_conditions_title': _getTranslation(
          'يرجى قراءة النقاط ادناه ثم بعد القراءة والموافقة يرجى التوقيع اسفل الوصل',
          'Please read the points below, and after reading and agreeing, please sign below the receipt.',
          'تکایە خاڵەکانی خوارەوە بخوێنەوە، و دوای خوێندنەوە و ڕازیبوون، تکایە لەژێر پسوولەکە واژۆ بکە.',
        ),
        'terms_1': _getTranslation(
          'شركة ستيرس (EUKnet) تقوم فقط بشحن ونقل البضائع والمواد المسموح بها قانونيا، وفي حال وجود اي مادة مخالفة او غير مسموحة من الناحية القانونية داخل بضاعة المرسل، فان المرسل يتحمل كافة الغرامات المالية والقانونية من الجهات المختصة ولا ترجع للمرسل مبلغ كلفة النقل المدفوعة ل شركة ستيرس . المرسل يتحمل كل المسؤولية القانونية وليست شركة ستيرس (EUKnet)',
          'Sters Company (EUKnet) only ships and transports goods and materials that are legally permitted. If any illegal or prohibited materials are found in the sender\'s shipment, the sender will bear all financial and legal penalties from the relevant authorities, and the shipping cost paid to Sters Company will not be refunded. The sender bears full legal responsibility, not Sters Company (EUKnet).',
          'کۆمپانیای ستێرس (EUKnet) تەنها کاڵا و маێریاڵە یاساییەکان دەگوازێتەوە. ئەگەر هەر ماددەیەکی نایاسایی یان قەدەغەکراو لە ناو بارەکەی نێردەر بدۆزرێتەوە، نێردەر هەموو تاوانە دارایی و یاساییەکان لەلایەن دەسەڵاتە پەیوەندیدارەکانەوە دەگرێتە ئەستۆ، و نرخی گواستنەوە کە دراوە بە کۆمپانیای ستێرس ناگەڕێتەوە. نێردەر هەموو بەرپرسیاریەتی یاساییەکان دەگرێتە ئەستۆ، نەک کۆمپانیای ستێرس (EUKnet).',
        ),
        'terms_2': _getTranslation(
          'يجب على المرسل اعطاء العنوان ورقم هاتف المستلم بشكل صحيح وكامل، بخلاف ذلك فان شركة ستیرس (EUKnet) ليست مسؤولة عن اي تأخير او ضياع المواد بسبب عنوان خاطئ او غير كامل.',
          'The sender must provide the correct and complete address and phone number of the recipient. Otherwise, Sters Company (EUKnet) is not responsible for any delay or loss of materials due to an incorrect or incomplete address.',
          'نێردەر دەبێت ناونیشان و ژمارەی تەلەفۆنی وەرگرەکە بە شێوەیەکی دروست و تەواو پێشکەش بکات. بەبێ ئەوە، کۆمپانیای ستێرس (EUKnet) بەرپرسیار نییە لە هەر دواخستنێک یان لەدەستدانی کاڵاکان بەهۆی ناونیشانی هەڵە یان ناتەواو.',
        ),
        'terms_3': _getTranslation(
          'في حال حدوث أي ضرر بالمواد فإن شركة ستيرس تقوم بالتعويض لصاحبها على الشكل التالي:',
          'In case of any damage to the materials, Sters Company will compensate the owner as follows:',
          'لە ڕوودانی هەر زیانێک بە کاڵاکان، کۆمپانیای ستێرس بەم شێوەیە خەسارەتەکە جبر دەکاتەوە:',
        ),
        'terms_3a': _getTranslation(
          'العملاء الذين قاموا بالتأمين الاضافي على المواد والبضائع المرسلة وذلك بدفع نسبة عن قيمة البضاعة فإن الشركة مسؤولة عن التعويض الكامل لصاحبها.',
          'Customers who have purchased additional insurance for the shipped materials and goods by paying a percentage of the goods\' value, the company is responsible for full compensation to the owner.',
          'ئەو کڕیارانەی کە بیمەی زیادەیان کڕیوە بۆ کاڵا و بەڵامە گواستراوەکان بە دانانی ڕێژەیەک لە نرخی کاڵاکان، کۆمپانیاکە بەرپرسیارە لە جبرکردنەوەی تەواو بۆ خاوەنەکە.',
        ),
        'terms_3b': _getTranslation(
          'العملاء الذين لم يقوموا بالتامين الاضافي على المواد والبضائع فان الشركة تعوض فقط مبلغ اجرة النقل لصاحبها واعادة كلفة النقل المستلمة الى صاحبها.',
          'Customers who have not purchased additional insurance for the materials and goods, the company will only compensate the shipping cost to the owner and refund the received shipping cost to the owner.',
          'ئەو کڕیارانەی کە بیمەی زیادەیان نەکڕیوە بۆ کاڵا و بەڵامەکان، کۆمپانیاکە تەنها نرخی گواستنەوە جبر دەکاتەوە بۆ خاوەنەکە و نرخی گواستنەوەی وەرگیراو دەگەڕێنێتەوە بۆ خاوەنەکە.',
        ),
        'terms_4': _getTranslation(
          'يجب على المرسل التقيد بالتعليمات الموجهة من قبل موظفينا، والموجودة على حائط الشركة.',
          'The sender must adhere to the instructions provided by our staff, which are posted on the company\'s wall.',
          'نێردەر دەبێت ڕێنماییەکانی ستافی ئێمە بەجێبھێنێت، کە لەسەر دیواری کۆمپانیاکە دانراون.',
        ),
        'terms_5': _getTranslation(
          'في حالة وجود (السكائر، الفصيل للاكل، الادوية،الذهب،الفضة، كرستال، المشروبات الكحولية، السلاح بانواعه والمعدات العسكرية، المواد المخدرة، التحفيات والقطع الاثرية) داخل اغراضكم (المرسل) فان الشخص المرسل يتحمل كل المسؤولية القانونية وليست شركة ستيرس (EUKnet).',
          'If the shipment contains (cigarettes, food items, medicines, gold, silver, crystal, alcoholic beverages, weapons of any kind, military equipment, narcotics, antiques, and artifacts), the sender bears full legal responsibility, not Sters Company (EUKnet).',
          'ئەگەر بارەکە لە ناوەڕۆکیدا (جگەرە، خواردن، دەرمان، زێڕ، زیو، کریستاڵ، خواردنەوەی ئەلکحولی، چەک، ئامێری سەربازی، ماددە بێهۆشکەرەکان، کەلوپەلی کۆن و بەنرخ) هەبێت، نێردەر هەموو بەرپرسیاریەتی یاساییەکان دەگرێتە ئەستۆ، نەک کۆمپانیای ستێرس (EUKnet).',
        ),
        'terms_6': _getTranslation(
          'شركة ستيرس (EUKnet) غير مسؤولة في حالة فرض الرسوم الكمركية في اية نقطة حدودية، بل صاحب البضاعة ملزم بدفع هذه الرسومات.',
          'Sters Company (EUKnet) is not responsible for any customs duties imposed at any border point; the owner of the goods is obligated to pay these fees.',
          'کۆمپانیای ستێرس (EUKnet) بەرپرسیار نییە لە هەر پارەی گومرگی لە هەر خاڵێکی سنووریدا؛ خاوەنی کاڵاکان بەرپرسیارە لە دانانی ئەو پارانە.',
        ),
        'terms_7': _getTranslation(
          'المرسل قرأ هذه الشروط العامة وفهمها وتوقيعه يعتبر موافقة صريحة عليها.',
          'The sender has read, understood, and signed these general terms and conditions, which constitutes explicit agreement to them.',
          'نێردەر ئەم مەرجە گشتیانەی خوێندووە و تێگەیشتووە و واژۆی کردووە، کە ئەمە ڕەزامەندی ڕوونە لەسەریان.',
        ),

        'main_office_europe': _getTranslation(
          'المكتب الرئيسي للشركة في اوروبا',
          'The company\'s main office in Europe',
          'نووسینگەی سەرەکی کۆمپانیاکە لە ئەوروپا',
        ),
      };

  String _getTranslation(String arabic, String english, String kurdish) {
    switch (language) {
      case InvoiceLanguage.arabic:
        return arabic;
      case InvoiceLanguage.english:
        return english;
      case InvoiceLanguage.kurdish:
        return kurdish;
    }
  }
}

// Enums and Models
enum InvoiceLanguage { arabic, english, kurdish }
