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
  static const Map<String, String> kurdishToArabicMap = {
    '\u06B5': '\u0644', // ڵ -> ل
    '\u06CE': '\u0626', // ێ -> ئ
    '\u06D5': '\u0629', // ە -> ة
  };

  static Future<pw.Font> loadKurdishFontWithFallback() async {
    try {
      // Load primary Kurdish font
      final ByteData primaryFont =
          await rootBundle.load('fonts/NotoSansArabic-Regular.ttf');

      // Return the primary font, and use fontFallback in the TextStyle for fallback fonts
      return pw.Font.ttf(primaryFont);
    } catch (e) {
      if (kDebugMode) {
        print('Font loading error: $e');
      }
      return pw.Font.helvetica();
    }
  }

  static String processKurdishText(String input) {
    String processed = input;
    kurdishToArabicMap.forEach((kurdish, arabic) {
      processed = processed.replaceAll(kurdish, arabic);
    });
    return processed;
  }

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

  static Future<pw.Font> loadSymbolFont() async {
    try {
      final fontData =
          await rootBundle.load('fonts/NotoSansSymbols-Regular.ttf');
      return pw.Font.ttf(fontData);
    } catch (e) {
      return pw.Font.helvetica(); // Final fallback
    }
  }

  static Future<pw.Font> loadArabicFont() async {
    final fontData = await rootBundle.load('fonts/NotoSansArabic-Regular.ttf');
    return pw.Font.ttf(fontData);
  }

  static Future<pw.Font> loadKurdishFont() async {
    try {
      final ByteData fontData =
          await rootBundle.load('fonts/Amiri-Regular.ttf');
      fontData.buffer.asUint8List();
      return pw.Font.ttf(fontData);
    } catch (e) {
      // Fallback to a Unicode-supported font
      return pw.Font.timesBold();
    }
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

  static Future<pw.Font> loadSoraniFont() async {
    try {
      // Use a Sorani-specific font that supports these characters
      final fontData = await rootBundle.load('fonts/Rabar_021.ttf');
      return pw.Font.ttf(fontData);
    } catch (e) {
      // Fallback to a more comprehensive Unicode font
      return pw.Font.timesBold();
    }
  }

  static Future<pw.Font> loadFont() async {
    try {
      final ByteData fontData =
          await rootBundle.load('fonts/ScheherazadeNew-Regular.ttf');
      return pw.Font.ttf(fontData);
    } catch (e) {
      if (kDebugMode) {
        print('Error loading font: $e');
      }
      return pw.Font.helvetica(); // Fallback to Helvetica
    }
  }

  static Future<void> initializeFonts() async {
    try {
      // Load Arabic fonts
      final cairoBold = await loadCairoFont(isBold: true);
      final cairoRegular = await loadCairoFont(isBold: false);
      final arabicFont = await loadArabicFont();
      final kurdishFont = await loadKurdishFontWithFallback();
      final symbolFont = await loadSymbolFont(); // Add this
      final robotoFont = await loadRobotoFont();
      final soraniFont =
          await loadSoraniFont(); // Add this for Sorani language support
      final scheherazadeFont = await loadFont();
      // Update fallback list to include Roboto
      _fontFallback = [
        cairoBold,
        cairoRegular,
        arabicFont,
        kurdishFont,
        robotoFont,
        symbolFont,
        soraniFont,
        scheherazadeFont, // Add this for Sorani language support
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
    InvoiceLanguage? language, // Add language parameter
  }) {
    return pw.TextStyle(
      font: baseFont,
      fontSize: fontSize,
      color: color,
      fontWeight: fontWeight,
      fontFallback: _fontFallback,
      wordSpacing: 1.2,
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
    required bool isPostCity,
  }) async {
    final translations = InvoiceLocalizations(language);

    // Initialize the PDF document
    final pdf = pw.Document();
    await initializeFonts();

    // Load images
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
              buildCodeSection(shipment, regularFont, boldFont, translations),
              pw.SizedBox(height: 10.h),
              buildSenderReceiverAndCostsSection(
                sender,
                receiver,
                costs,
                regularFont,
                boldFont,
                qrCode,
                translations,
                shipment,
                isPostCity,
              ),
              pw.SizedBox(height: 10.h),
              termsAndConditions,
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
    final textDirection = translations.textDirection;
    final isRTL = textDirection == pw.TextDirection.ltr;

    // Phone number row with proper ordering
    final phoneRow = pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.center,
      children: isRTL
          ? [
              pw.Text(
                translations.translations['phone']!,
                style: getTextStyle(baseFont: boldFont, fontSize: 14.sp),
                textDirection: textDirection,
              ),
              pw.SizedBox(width: 5.w),
              pw.Text(
                '${receiver.phoneNo1}   -   ${receiver.phoneNo2}', // Use branch phone numbers
                style: getTextStyle(baseFont: boldFont, fontSize: 14.sp),
              ),
            ]
          : [
              pw.Text(
                '${receiver.phoneNo1}   -   ${receiver.phoneNo2}', // Use branch phone numbers
                style: getTextStyle(baseFont: boldFont, fontSize: 14.sp),
              ),
              pw.SizedBox(width: 5.w),
              pw.Text(
                translations.translations['phone']!,
                style: getTextStyle(baseFont: boldFont, fontSize: 14.sp),
                textDirection: textDirection,
              ),
            ],
    );

    // Branch row with proper ordering
    final branchRow = pw.Row(
      children: isRTL
          ? [
              pw.Text(
                translations.translations['branch']!,
                style: getTextStyle(baseFont: boldFont, fontSize: 14.sp),
                textDirection: textDirection,
              ),
              pw.SizedBox(width: 10.w),
              pw.Text(
                receiver.branch,
                style: getTextStyle(baseFont: boldFont, fontSize: 14.sp),
              ),
            ]
          : [
              pw.Text(
                receiver.branch,
                style: getTextStyle(baseFont: boldFont, fontSize: 14.sp),
              ),
              pw.SizedBox(width: 10.w),
              pw.Text(
                translations.translations['branch']!,
                style: getTextStyle(baseFont: boldFont, fontSize: 14.sp),
                textDirection: textDirection,
              ),
            ],
    );

    // Central column content remains the same but with explicit text direction
    final centralColumn = pw.Column(
      children: [
        pw.Text(
          translations.translations['company_name']!,
          style: getTextStyle(baseFont: boldFont, fontSize: 14.sp),
          textDirection: textDirection,
        ),
        pw.SizedBox(height: 5.h),
        pw.Text(
          translations.translations['company_slogan']!,
          style: getTextStyle(baseFont: boldFont, fontSize: 14.sp),
          textDirection: textDirection,
        ),
        pw.SizedBox(height: 5.h),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            phoneRow,
            pw.SizedBox(width: 60.w),
            branchRow,
          ],
        ),
      ],
    );

    return pw.Padding(
      padding: pw.EdgeInsets.symmetric(horizontal: 40.w),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: isRTL
            ? [
                pw.Image(stersLogo, width: 300.w, height: 80.h),
                centralColumn,
                pw.Image(euknetLogo, width: 700.w, height: 60.h),
              ]
            : [
                pw.Image(euknetLogo, width: 600.w, height: 60.h),
                centralColumn,
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
              baseFont: boldFont, fontSize: 14.sp, color: PdfColors.white),
          textDirection: translations.textDirection,
        ),
      ),
    );
  }

  // Updated buildCodeSection method to use translations
  static pw.Widget buildCodeSection(
      ShipmentDetails shipment,
      pw.Font regularFont,
      pw.Font boldFont,
      InvoiceLocalizations translations) {
    final textDirection = _getTextDirection(translations.language);

    return pw.Container(
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#FFB99B'),
        border: const pw.Border(
          bottom: pw.BorderSide(color: PdfColors.black, width: 1),
          top: pw.BorderSide(color: PdfColors.black, width: 1),
        ),
      ),
      padding: pw.EdgeInsets.symmetric(horizontal: 20.w, vertical: 5.h),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          if (textDirection == pw.TextDirection.ltr) ...[
            // For English: Code on the left, date on the right
            pw.Text(
              'Code:   ',
              style: getTextStyle(baseFont: regularFont, fontSize: 14.sp),
            ),
            pw.Center(
                child: pw.Text(
              ' ${shipment.codeNumber} - ${shipment.truckNumber}',
              style: getTextStyle(baseFont: boldFont, fontSize: 16.sp),
            )),
            pw.Row(
              children: [
                pw.Text(
                  translations.translations['code']!,
                  style: getTextStyle(baseFont: regularFont, fontSize: 14.sp),
                  textDirection: textDirection,
                ),
                pw.SizedBox(width: 10.w),
                pw.Container(
                  padding: pw.EdgeInsets.only(left: 10.w),
                  decoration: const pw.BoxDecoration(
                      border: pw.Border(
                          left:
                              pw.BorderSide(color: PdfColors.black, width: 1))),
                  child: pw.Text(
                    '${translations.translations['date']!} ${shipment.date} ',
                    style: getTextStyle(baseFont: regularFont, fontSize: 14.sp),
                    textDirection: textDirection,
                  ),
                ),
              ],
            ),
          ] else ...[
            // For Arabic and Kurdish: Date on the left, code on the right
            pw.Text(
              'Code:',
              style: getTextStyle(baseFont: regularFont, fontSize: 14.sp),
            ),
            pw.Center(
                child: pw.Text(
              ' ${shipment.codeNumber} - ${shipment.truckNumber}',
              style: getTextStyle(baseFont: boldFont, fontSize: 16.sp),
            )),
            pw.Row(
              children: [
                pw.Text(
                  translations.translations['code']!,
                  style: getTextStyle(baseFont: regularFont, fontSize: 14.sp),
                  textDirection: textDirection,
                ),
                pw.SizedBox(width: 10.w),
                pw.Container(
                  padding: pw.EdgeInsets.only(right: 10.w),
                  decoration: const pw.BoxDecoration(
                      border: pw.Border(
                          left:
                              pw.BorderSide(color: PdfColors.black, width: 1))),
                  child: pw.Text(
                    '${translations.translations['date']!} ${shipment.date}      ',
                    style: getTextStyle(baseFont: regularFont, fontSize: 14.sp),
                    textDirection: textDirection,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static pw.Widget buildSenderReceiverAndCostsSection(
    SenderInfo sender,
    ReceiverInfo receiver,
    CostSummary costs,
    pw.Font regularFont,
    pw.Font boldFont,
    pw.ImageProvider qrCode,
    InvoiceLocalizations translations,
    ShipmentDetails shipment,
    bool isPostCity, // Added parameter
  ) {
    return pw.Padding(
      padding: pw.EdgeInsets.symmetric(horizontal: 20.w),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Left side - Sender-Receiver Info
          pw.Expanded(
            flex: 1,
            child: pw.Container(
              height: 500.h,
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.black, width: 1.w),
                borderRadius: pw.BorderRadius.all(pw.Radius.circular(5.r)),
              ),
              child: pw.Column(
                children: [
                  // Header
                  _buildSectionHeader(
                    translations.translations['sender_receiver_info']!,
                    boldFont,
                    translations,
                  ),

                  // Common Info Rows
                  _buildCommonInfoRows(
                      sender, receiver, regularFont, translations),

                  // Conditional Address Section
                  if (isPostCity) ...[
                    // Post city specific rows
                    buildTableRow(
                      translations.translations['address']!,
                      receiver.street,
                      regularFont,
                      translations.language,
                    ),
                    buildTableRow(
                      translations.translations['postal_code']!,
                      receiver.zipCode,
                      regularFont,
                      translations.language,
                    ),
                  ],

                  // Common location info
                  buildTableRow(
                    translations.translations['city']!,
                    receiver.city,
                    regularFont,
                    translations.language,
                  ),
                  buildTableRow(
                    translations.translations['country']!,
                    receiver.country,
                    regularFont,
                    translations.language,
                  ),
                  if (!isPostCity) ...[
                    buildTablePostRow(
                      translations.translations['post_office_pickup']!,
                      regularFont,
                      translations.language,
                    ),
                  ],
                  // Agent Info and QR Code sections remain unchanged
                  _buildAgentSection(boldFont, qrCode, translations),
                ],
              ),
            ),
          ),

          pw.SizedBox(width: 15.w),

          // Right side - Costs Table (remains unchanged)
          _buildCostsSection(
              costs, regularFont, boldFont, translations, shipment),
        ],
      ),
    );
  }

  static pw.Widget buildCostTableRow(
    String label,
    String value,
    pw.Font font,
    InvoiceLanguage language, {
    bool isPaid = false,
    bool isRequiredAmount = false,
    bool isHomeDelivery = false,
    bool isInsuranceCost = false,
    String? requiredAmount,
  }) {
    final textDirection = language == InvoiceLanguage.english
        ? pw.TextDirection.ltr
        : pw.TextDirection.rtl;

    // Simplified color logic
    final rowColor = _getRowColor(
      value: value,
      isPaid: isPaid,
      isRequiredAmount: isRequiredAmount,
      isHomeDelivery: isHomeDelivery,
      isInsuranceCost: isInsuranceCost,
      requiredAmount: requiredAmount,
    );

    final currencyText = value.isNotEmpty
        ? (language == InvoiceLanguage.english ? 'IRQ' : 'دينار عراقي')
        : '';

    return pw.Container(
      decoration: pw.BoxDecoration(
        color: rowColor,
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.black, width: 1.w),
        ),
      ),
      padding: pw.EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
      child: pw.Row(
        mainAxisAlignment: textDirection == pw.TextDirection.rtl
            ? pw.MainAxisAlignment.end
            : pw.MainAxisAlignment.start,
        children: _buildRowChildren(
          label: label,
          value: value,
          currencyText: currencyText,
          font: font,
          textDirection: textDirection,
        ),
      ),
    );
  }

  static PdfColor? _getRowColor({
    required String value,
    required bool isPaid,
    required bool isRequiredAmount,
    required bool isHomeDelivery,
    required bool isInsuranceCost,
    String? requiredAmount,
  }) {
    if (isPaid && requiredAmount == '0.00') {
      return PdfColors.green; // Green only if required amount is 0
    }

    // Required amount and required amount in euro fields will be orange if not 0
    if (isRequiredAmount && value != '0.00') {
      return PdfColor.fromHex('#FFB99B');
    }
    if (isHomeDelivery && value != '0.00') return PdfColors.blue;
    if (isInsuranceCost && value != '0.00') return PdfColors.green;
    return null;
  }

  static List<pw.Widget> _buildRowChildren({
    required String label,
    required String value,
    required String currencyText,
    required pw.Font font,
    required pw.TextDirection textDirection,
  }) {
    final isLTR = textDirection == pw.TextDirection.ltr;

    final labelWidget = pw.Expanded(
      flex: isLTR ? 2 : 3,
      child: pw.Text(
        label,
        style: getTextStyle(baseFont: font, fontSize: 12.sp),
        textAlign: isLTR ? pw.TextAlign.left : pw.TextAlign.right,
        textDirection: textDirection,
      ),
    );

    final valueWidget = pw.Expanded(
      flex: 3,
      child: pw.Row(
        children: [
          if (!isLTR && value.isNotEmpty) ...[
            pw.Text(
              currencyText,
              style: getTextStyle(baseFont: font, fontSize: 12.sp),
              textDirection: textDirection,
            ),
            pw.Spacer(),
          ],
          pw.Text(
            value,
            style: getTextStyle(baseFont: font, fontSize: 14.sp),
            textDirection: textDirection,
          ),
          if (isLTR && value.isNotEmpty) ...[
            pw.Spacer(),
            pw.Text(
              currencyText,
              style: getTextStyle(baseFont: font, fontSize: 12.sp),
              textDirection: textDirection,
            ),
          ],
        ],
      ),
    );

    final divider = [
      pw.SizedBox(width: 10.w),
      pw.Container(
        width: 1,
        color: PdfColors.black,
        height: isLTR ? 14.h : 30.h,
      ),
      pw.SizedBox(width: 10.w),
    ];

    return isLTR
        ? [labelWidget, ...divider, valueWidget]
        : [valueWidget, ...divider, labelWidget];
  }

  static pw.Widget _buildCostsSection(
    CostSummary costs,
    pw.Font regularFont,
    pw.Font boldFont,
    InvoiceLocalizations translations,
    ShipmentDetails shipment,
  ) {
    return pw.Expanded(
      flex: 1,
      child: pw.Container(
        height: 500.h,
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.black, width: 1.w),
          borderRadius: pw.BorderRadius.all(pw.Radius.circular(5.r)),
        ),
        child: pw.Column(
          children: [
            _buildSectionHeader(
              translations.translations['transport_costs']!,
              boldFont,
              translations,
            ),
            ...buildCostRows(
              costs: costs,
              regularFont: regularFont,
              translations: translations,
            ),
            _buildInsuranceSection(regularFont, translations, costs),
            pw.Expanded(
              child: _buildShipmentDetailsTable(
                shipment,
                regularFont,
                translations,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static List<pw.Widget> buildCostRows({
    required CostSummary costs,
    required pw.Font regularFont,
    required InvoiceLocalizations translations,
  }) {
    return [
      buildCostTableRow(
        translations.translations['shipping_cost']!,
        costs.shippingCost,
        regularFont,
        translations.language,
      ),
      buildCostTableRow(
        translations.translations['empty_box_cost']!,
        costs.emptyBoxCost,
        regularFont,
        translations.language,
      ),
      buildCostTableRow(
        translations.translations['customs_admin']!,
        costs.customsAdmin,
        regularFont,
        translations.language,
      ),
      buildCostTableRow(
        translations.translations['delivery_cost']!,
        costs.deliveryCost,
        regularFont,
        translations.language,
        isHomeDelivery: true,
      ),
      buildCostTableRow(
        translations.translations['insurance_cost']!,
        costs.insuranceAmount,
        regularFont,
        translations.language,
        isInsuranceCost: true,
      ),
      buildCostTableRow(
        translations.translations['total_cost']!,
        costs.totalCost,
        regularFont,
        translations.language,
      ),
      buildCostTableRow(
        translations.translations['amount_paid']!,
        costs.amountPaid,
        regularFont,
        translations.language,
        isPaid: true,
        requiredAmount: costs.amountDue,
      ),
      buildCostTableRow(
        translations.translations['amount_due']!,
        costs.amountDue,
        regularFont,
        translations.language,
        isRequiredAmount: true,
      ),
      buildCostTableRow(
        translations.translations['amount_due_eur']!,
        costs.amountDueEur,
        regularFont,
        translations.language,
        isRequiredAmount: true,
      ),
    ];
  }

  static pw.Widget _buildInsuranceSection(
    pw.Font regularFont,
    InvoiceLocalizations translations,
    CostSummary costs,
  ) {
    final textDirection = translations.textDirection;

    return pw.Container(
      decoration: pw.BoxDecoration(
        color: costs.isInsuranceEnabled
            ? PdfColors.green
            : null, // Green if insurance is enabled
        border: pw.Border.all(color: PdfColors.black, width: 1.w),
      ),
      padding: pw.EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        children: [
          pw.Expanded(
            child: buildCheckbox(
              label: translations.translations['no']!,
              font: regularFont,
              textDirection: textDirection,
              checked: !costs
                  .isInsuranceEnabled, // Check "No" if insurance is disabled
            ),
          ),
          pw.SizedBox(width: 10.w),
          pw.Expanded(
            child: buildCheckbox(
              label: translations.translations['yes']!,
              font: regularFont,
              textDirection: textDirection,
              checked: costs
                  .isInsuranceEnabled, // Check "Yes" if insurance is enabled
            ),
          ),
          pw.SizedBox(width: 20.w),
          pw.Expanded(
            child: pw.Text(
              translations.translations['insurance']!,
              style: getTextStyle(baseFont: regularFont, fontSize: 14.sp),
              textDirection: textDirection,
            ),
          ),
        ],
      ),
    );
  }

  // Helper method for shipment details table
  static pw.Widget _buildShipmentDetailsTable(
    ShipmentDetails shipment,
    pw.Font regularFont,
    InvoiceLocalizations translations,
  ) {
    return pw.Table(
      children: [
        if (pw.TextDirection.ltr == translations.textDirection) ...[
          pw.TableRow(
            children: [
              buildTableHeader(
                translations.translations['number_of_boxes']!,
                regularFont,
                1,
              ),
              buildTableHeader(
                translations.translations['weight_kg']!,
                regularFont,
                1,
              ),
              buildTableHeader(
                translations.translations['goods_details']!,
                regularFont,
                2,
              ),
              buildTableHeader(
                translations.translations['goods_value']!,
                regularFont,
                1,
              ),
            ],
          ),
          pw.TableRow(
            children: [
              buildTableCell(shipment.boxNumber, regularFont),
              buildTableCell(shipment.totalWeight, regularFont),
              buildTableCell(shipment.description, regularFont),
              buildTableCell('', regularFont), // Goods value placeholder
            ],
          ),
        ] else ...[
          pw.TableRow(
            children: [
              buildTableHeader(
                translations.translations['goods_value']!,
                regularFont,
                1,
              ),
              buildTableHeader(
                translations.translations['goods_details']!,
                regularFont,
                2,
              ),
              buildTableHeader(
                translations.translations['weight_kg']!,
                regularFont,
                1,
              ),
              buildTableHeader(
                translations.translations['number_of_boxes']!,
                regularFont,
                1,
              ),
            ],
          ),
          pw.TableRow(
            children: [
              buildTableCell('', regularFont), // Goods value placeholder
              buildTableCell(shipment.description, regularFont),
              buildTableCell(shipment.totalWeight, regularFont),
              buildTableCell(shipment.boxNumber, regularFont),
            ],
          ),
        ],
      ],
    );
  }

  static pw.Widget _buildCommonInfoRows(
    SenderInfo sender,
    ReceiverInfo receiver,
    pw.Font regularFont,
    InvoiceLocalizations translations,
  ) {
    return pw.Column(
      children: [
        buildTableRow(
          translations.translations['sender_name']!,
          sender.name,
          regularFont,
          translations.language,
        ),
        buildTableRow(
          translations.translations['sender_phone']!,
          sender.phone,
          regularFont,
          translations.language,
        ),
        buildTableRow(
          translations.translations['receiver_name']!,
          receiver.name,
          regularFont,
          translations.language,
        ),
        buildTableRow(
          translations.translations['receiver_phone']!,
          receiver.phone,
          regularFont,
          translations.language,
        ),
      ],
    );
  }

  // Helper method for section headers
  static pw.Widget _buildSectionHeader(
    String title,
    pw.Font boldFont,
    InvoiceLocalizations translations,
  ) {
    return pw.Container(
      width: double.infinity,
      decoration: pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColors.black, width: 1.w),
          bottom: pw.BorderSide(color: PdfColors.black, width: 1.w),
        ),
      ),
      padding: pw.EdgeInsets.symmetric(vertical: 8.h),
      child: pw.Text(
        title,
        style: getTextStyle(baseFont: boldFont, fontSize: 16.sp),
        textAlign: pw.TextAlign.center,
        textDirection: translations.textDirection,
      ),
    );
  }

  // Helper method for agent section
  static pw.Widget _buildAgentSection(
    pw.Font boldFont,
    pw.ImageProvider qrCode,
    InvoiceLocalizations translations,
  ) {
    return pw.Column(
      children: [
        pw.Container(
          width: double.infinity,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.black, width: 1.w),
          ),
          padding: pw.EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
          child: pw.Text(
            translations.translations['agent_info']!,
            style: getTextStyle(baseFont: boldFont, fontSize: 14.sp),
            textAlign: pw.TextAlign.center,
            textDirection: translations.textDirection,
          ),
        ),
        pw.Container(
            padding: pw.EdgeInsets.all(10.r),
            child: pw.Row(children: [
              pw.Spacer(),
              pw.Image(qrCode, width: 120.w, height: 120.h),
            ])),
      ],
    );
  }

  // Updated buildTableRow method
  static pw.Widget buildTableRow(
    String label,
    String? value,
    pw.Font font,
    InvoiceLanguage language, // Pass the language here
  ) {
    final textDirection = _getTextDirection(language); // Get text direction

    // Process Kurdish text if the language is Kurdish
    if (language == InvoiceLanguage.kurdish) {
      label = processKurdishText(label);
      value = processKurdishText(value ?? ''); // Handle null
      // Handle null value
    }

    // Add currency suffix based on language
    String currencyText = '';
    if (value!.isNotEmpty) {
      currencyText =
          language == InvoiceLanguage.english ? 'IRQ' : 'دينار عراقي';
    }

    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.black, width: 1.w),
        ),
      ),
      padding: pw.EdgeInsets.symmetric(
        horizontal: 10.w,
        vertical: 2.h,
      ),
      child: pw.Row(
        mainAxisAlignment: textDirection == pw.TextDirection.rtl
            ? pw.MainAxisAlignment.end
            : pw.MainAxisAlignment.start,
        children: [
          if (textDirection == pw.TextDirection.ltr) ...[
            // For English: Label on the left, value on the right
            pw.Expanded(
              flex: 2,
              child: pw.Text(
                label,
                style: getTextStyle(baseFont: font, fontSize: 12.sp),
                textAlign: pw.TextAlign.left,
                textDirection: textDirection,
              ),
            ),
            pw.SizedBox(width: 10.w),
            pw.Container(width: 1, color: PdfColors.black, height: 30.h),
            pw.SizedBox(width: 10.w),
            pw.Expanded(
              flex: 3,
              child: pw.Row(
                children: [
                  pw.Text(
                    value,
                    style: getTextStyle(baseFont: font, fontSize: 14.sp),
                    textDirection: textDirection,
                  ),
                  if (value.isNotEmpty) ...[
                    pw.Spacer(), // Spacer between number and currency
                    pw.Text(
                      currencyText,
                      style: getTextStyle(baseFont: font, fontSize: 12.sp),
                      textDirection: textDirection,
                    ),
                  ],
                ],
              ),
            ),
          ] else ...[
            // For Arabic and Kurdish: Label on the right, value on the left
            pw.SizedBox(width: 40.w),
            pw.Expanded(
              flex: 3,
              child: pw.Row(
                children: [
                  pw.Center(
                    child: pw.Text(
                      value,
                      style: getTextStyle(baseFont: font, fontSize: 14.sp),
                      textDirection: textDirection,
                    ),
                  ),
                ],
              ),
            ),
            pw.Container(width: 1, color: PdfColors.black, height: 30.h),
            pw.SizedBox(width: 10.w),
            pw.Expanded(
              flex: 2,
              child: pw.Text(
                label,
                style: getTextStyle(baseFont: font, fontSize: 12.sp),
                textAlign: pw.TextAlign.right,
                textDirection: textDirection,
              ),
            ),
          ],
        ],
      ),
    );
  }

  static pw.Widget buildTablePostRow(
    String label,
    pw.Font font,
    InvoiceLanguage language, // Pass the language here
  ) {
    final textDirection = _getTextDirection(language); // Get text direction
    // Add currency suffix based on language

    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.black, width: 1.w),
        ),
      ),
      padding: pw.EdgeInsets.symmetric(
        horizontal: 10.w,
        vertical: 22.h,
      ),
      child: pw.Row(
        mainAxisAlignment: textDirection == pw.TextDirection.rtl
            ? pw.MainAxisAlignment.end
            : pw.MainAxisAlignment.start,
        children: [
          // Reorder elements based on language
          if (textDirection == pw.TextDirection.ltr) ...[
            // For English: Label on the left, value on the right
            pw.Spacer(),
            pw.Text(
              label,
              style: getTextStyle(baseFont: font, fontSize: 12.sp),
              textAlign: pw.TextAlign.center,
              textDirection: textDirection,
            ),
            pw.Spacer(),
          ] else ...[
            // For Arabic and Kurdish: Label on the right, value on the left
            pw.Spacer(),
            pw.Center(
              child: pw.Text(
                label,
                style: getTextStyle(baseFont: font, fontSize: 12.sp),
                textAlign: pw.TextAlign.center,
                textDirection: textDirection,
              ),
            ),
            pw.Spacer(),
          ],
        ],
      ),
    );
  }

  static pw.Widget buildTableCell(String text, pw.Font font) {
    return pw.Expanded(
        child: pw.Container(
      height: 81.h,
      padding: pw.EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 1.w),
        borderRadius: pw.BorderRadius.only(
          bottomLeft: pw.Radius.circular(5.r),
          bottomRight: pw.Radius.circular(5.r),
        ),
      ),
      alignment: pw.Alignment.center,
      child: pw.Text(
        text,
        style: getTextStyle(baseFont: font, fontSize: 12.sp),
        textAlign: pw.TextAlign.center, // Center-align the text
        maxLines: 3, // Allow text to wrap after 3 lines
        overflow: pw.TextOverflow.clip,
      ),
    ));
  }

  // Updated buildTableHeader method
  static pw.Widget buildTableHeader(String text, pw.Font font, int flex) {
    return pw.Expanded(
      flex: flex,
      child: pw.Container(
        padding: pw.EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.black, width: 1.w),
        ),
        child: pw.Text(
          text,
          style: getTextStyle(baseFont: font, fontSize: 12.sp),
          textAlign: pw.TextAlign.center,
          textDirection: pw.TextDirection.rtl,
          maxLines: 1, // Allow text to wrap after 2 lines
          overflow: pw.TextOverflow.clip,
        ),
      ),
    );
  }

  // Updated buildCheckbox method
  static pw.Widget buildCheckbox({
    required String label,
    required pw.Font font,
    required pw.TextDirection textDirection,
    bool checked = false,
    double checkboxSize = 15,
    double fontSize = 14,
    double spacing = 5,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          if (textDirection == pw.TextDirection.rtl) ...[
            pw.Text(
              label,
              style: pw.TextStyle(
                font: font,
                fontSize: fontSize.sp,
              ),
              textDirection: textDirection,
            ),
            pw.SizedBox(width: spacing.w),
          ],
          pw.Stack(
            alignment: pw.Alignment.center,
            children: [
              pw.Container(
                width: checkboxSize.w,
                height: checkboxSize.h,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(
                    color: PdfColors.black,
                    width: 1,
                  ),
                ),
              ),
              if (checked)
                pw.Text(
                  '×',
                  style: pw.TextStyle(
                    font: font,
                    fontSize: checkboxSize.sp *
                        0.8, // Adjust size relative to checkbox
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
            ],
          ),
          if (textDirection == pw.TextDirection.ltr) ...[
            pw.SizedBox(width: spacing),
            pw.Text(
              label,
              style: pw.TextStyle(
                font: font,
                fontSize: fontSize.sp,
              ),
              textDirection: textDirection,
            ),
          ],
        ],
      ),
    );
  }

  // Updated buildTermsAndConditionsSection method
  static Future<pw.Widget> buildTermsAndConditionsSection(
    pw.Font regularFont,
    pw.Font boldFont,
    InvoiceLocalizations translations,
  ) async {
    final textDirection = _getTextDirection(translations.language);
    final isRTL = textDirection == pw.TextDirection.ltr;

    // Load images
    final prohibitedIconsImage1 =
        pw.MemoryImage(await loadAssetImage('assets/icons/02.png'));
    final prohibitedIconsImage2 =
        pw.MemoryImage(await loadAssetImage('assets/icons/03.png'));
    final prohibitedIconsImage3 = pw.MemoryImage(
        await loadAssetImage('assets/icons/Sters Logo N-BG (1).png'));

    // Extract icons section to a separate widget for reusability
    final iconsSection = pw.Container(
      width: 100.w,
      child: pw.Column(
        children: [
          pw.Container(
            height: 300.h,
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black, width: 0.5.w),
            ),
            padding: pw.EdgeInsets.all(10.r),
            child: pw.Column(
              children: [
                pw.Expanded(
                  child: pw.Image(prohibitedIconsImage1, fit: pw.BoxFit.fill),
                ),
                pw.Expanded(
                  child: pw.Image(prohibitedIconsImage2, fit: pw.BoxFit.fill),
                ),
              ],
            ),
          ),
          pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black, width: 0.5.w),
            ),
            padding: pw.EdgeInsets.all(10.r),
            height: 172.h,
            child: pw.Center(
              child: pw.Image(prohibitedIconsImage3),
            ),
          ),
        ],
      ),
    );

    // Extract terms section to a separate widget
    final termsSection = pw.Expanded(
      child: pw.Container(
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.black, width: 0.5.w),
        ),
        padding: pw.EdgeInsets.all(8.r),
        child: pw.Column(
          crossAxisAlignment:
              isRTL ? pw.CrossAxisAlignment.end : pw.CrossAxisAlignment.start,
          children: [
            // Terms 1-2
            for (var i = 1; i <= 2; i++)
              pw.Padding(
                padding: pw.EdgeInsets.only(bottom: 2.h),
                child: buildTermItem(
                  i.toString(),
                  translations.translations['terms_$i']!,
                  regularFont,
                  textDirection,
                ),
              ),

            // Term 3 with its sub-items
            pw.Padding(
              padding: pw.EdgeInsets.only(bottom: 2.h),
              child: buildTermItem(
                '3',
                translations.translations['terms_3']!,
                regularFont,
                textDirection,
              ),
            ),

            // Sub-items 3a and 3b
            if (translations.translations.containsKey('terms_3a') &&
                translations.translations.containsKey('terms_3b'))
              pw.Padding(
                padding: pw.EdgeInsets.only(
                  left: isRTL ? 0 : 15.w,
                  right: isRTL ? 15.w : 0,
                ),
                child: pw.Column(
                  crossAxisAlignment: isRTL
                      ? pw.CrossAxisAlignment.end
                      : pw.CrossAxisAlignment.start,
                  children: [
                    buildTermItem(
                      'a',
                      translations.translations['terms_3a']!,
                      regularFont,
                      textDirection,
                    ),
                    buildTermItem(
                      'b',
                      translations.translations['terms_3b']!,
                      regularFont,
                      textDirection,
                    ),
                  ],
                ),
              ),

            // Terms 4-7
            for (var i = 4; i <= 7; i++)
              pw.Padding(
                padding: pw.EdgeInsets.only(bottom: 2.h),
                child: buildTermItem(
                  i.toString(),
                  translations.translations['terms_$i']!,
                  regularFont,
                  textDirection,
                ),
              ),
          ],
        ),
      ),
    );
    // Extract footer section to a separate widget
    final footerSection = pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 0.5.w),
      ),
      child: pw.Row(
        children: [
          if (textDirection == pw.TextDirection.ltr) ...[
            // Main Office Section - RTL First
            pw.Expanded(
              child: pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border(
                    left: pw.BorderSide(color: PdfColors.black, width: 0.5.w),
                  ),
                ),
                child: pw.Center(
                  child: pw.Text(
                    translations.translations['main_office_europe']!,
                    style: getTextStyle(baseFont: boldFont, fontSize: 12.sp),
                    textDirection: textDirection,
                    textAlign: pw.TextAlign.center,
                  ),
                ),
              ),
            ),

            // Contact Info Section - RTL Middle
            pw.Expanded(
              child: pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border(
                    left: pw.BorderSide(color: PdfColors.black, width: 0.5.w),
                  ),
                ),
                padding: pw.EdgeInsets.all(8.r),
                child: pw.Column(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Text(
                      'Email:   info@euknet.com',
                      style:
                          getTextStyle(baseFont: regularFont, fontSize: 12.sp),
                      textAlign: pw.TextAlign.center,
                      textDirection: textDirection,
                    ),
                    pw.SizedBox(height: 2.h),
                    pw.Text(
                      'Website:   www.euknet.com',
                      style:
                          getTextStyle(baseFont: regularFont, fontSize: 12.sp),
                      textAlign: pw.TextAlign.center,
                      textDirection: textDirection,
                    ),
                  ],
                ),
              ),
            ),

            // Notes Section - RTL Last
            pw.Expanded(
              child: pw.Container(
                padding: pw.EdgeInsets.all(8.r),
                child: pw.Row(
                  children: [
                    // Empty Container for Notes

                    // Notes Label
                    pw.Container(
                      padding: pw.EdgeInsets.symmetric(horizontal: 8.w),
                      child: pw.Text(
                        translations.translations['note']!,
                        style:
                            getTextStyle(baseFont: boldFont, fontSize: 14.sp),
                        textDirection: textDirection,
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Container(
                        height: 63.h,
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(
                            color: PdfColors.black,
                            width: 0.5.w,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            // Notes Section - LTR First
            pw.Expanded(
              child: pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border(
                    right: pw.BorderSide(color: PdfColors.black, width: 0.5.w),
                  ),
                ),
                padding: pw.EdgeInsets.all(8.r),
                child: pw.Row(
                  children: [
                    pw.Expanded(
                      child: pw.Container(
                        height: 63.h,
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(
                            color: PdfColors.black,
                            width: 0.5.w,
                          ),
                        ),
                      ),
                    ),
                    // Notes Label
                    pw.Container(
                      padding: pw.EdgeInsets.symmetric(horizontal: 8.w),
                      child: pw.Text(
                        translations.translations['note']!,
                        style:
                            getTextStyle(baseFont: boldFont, fontSize: 14.sp),
                        textDirection: textDirection,
                      ),
                    ),
                    // Empty Container for Notes
                  ],
                ),
              ),
            ),

            // Contact Info Section - LTR Middle
            pw.Expanded(
              child: pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border(
                    right: pw.BorderSide(color: PdfColors.black, width: 0.5.w),
                  ),
                ),
                padding: pw.EdgeInsets.all(8.r),
                child: pw.Column(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Text(
                      'Email:   info@euknet.com',
                      style:
                          getTextStyle(baseFont: regularFont, fontSize: 14.sp),
                      textAlign: pw.TextAlign.center,
                      textDirection: textDirection,
                    ),
                    pw.SizedBox(height: 4.h),
                    pw.Text(
                      'Website:   www.euknet.com',
                      style:
                          getTextStyle(baseFont: regularFont, fontSize: 14.sp),
                      textAlign: pw.TextAlign.center,
                      textDirection: textDirection,
                    ),
                  ],
                ),
              ),
            ),

            // Main Office Section - LTR Last
            pw.Expanded(
              child: pw.Container(
                padding: pw.EdgeInsets.all(8.r),
                child: pw.Center(
                  child: pw.Text(
                    translations.translations['main_office_europe']!,
                    style: getTextStyle(baseFont: boldFont, fontSize: 14.sp),
                    textDirection: textDirection,
                    textAlign: pw.TextAlign.center,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );

    return pw.Container(
      alignment: pw.Alignment.centerLeft,
      child: pw.Column(
        crossAxisAlignment:
            isRTL ? pw.CrossAxisAlignment.end : pw.CrossAxisAlignment.start,
        children: [
          _buildTitle(translations, boldFont, textDirection),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: isRTL
                ? [termsSection, iconsSection]
                : [iconsSection, termsSection],
          ),
          footerSection,
        ],
      ),
    );
  }

// Helper methods for building components
  static pw.Widget _buildTitle(InvoiceLocalizations translations,
      pw.Font boldFont, pw.TextDirection textDirection) {
    return pw.Container(
      width: double.infinity,
      padding: pw.EdgeInsets.symmetric(vertical: 2.h),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.black, width: 1.w),
        ),
      ),
      child: pw.Text(
        translations.translations['terms_and_conditions_title']!,
        style: getTextStyle(
          baseFont: boldFont,
          fontSize: 14.sp,
          color: PdfColors.red,
        ),
        textAlign: pw.TextAlign.center,
        textDirection: textDirection,
      ),
    );
  }

  static pw.Widget buildTermItem(String number, String text, pw.Font font,
      pw.TextDirection textDirection) {
    final isRTL = textDirection == pw.TextDirection.rtl;

    return pw.Container(
      margin: pw.EdgeInsets.only(bottom: 8.h),
      child: pw.Row(
        mainAxisAlignment:
            isRTL ? pw.MainAxisAlignment.end : pw.MainAxisAlignment.start,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: isRTL
            ? [
                pw.Expanded(
                  child: pw.Text(
                    text,
                    style: getTextStyle(baseFont: font, fontSize: 12.sp),
                    textDirection: textDirection,
                    textAlign: pw.TextAlign.right,
                  ),
                ),
                // pw.SizedBox(width: 4.w),
                pw.Text(
                  ' - $number',
                  style: getTextStyle(
                    baseFont: font,
                    fontSize: 12.sp,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textDirection: textDirection,
                ),
              ]
            : [
                pw.Text(
                  '$number - ',
                  style: getTextStyle(
                    baseFont: font,
                    fontSize: 12.sp,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textDirection: textDirection,
                ),
                pw.SizedBox(width: 4.w),
                pw.Expanded(
                  child: pw.Text(
                    text,
                    style: getTextStyle(baseFont: font, fontSize: 12.sp),
                    textDirection: textDirection,
                    textAlign: pw.TextAlign.left,
                  ),
                ),
              ],
      ),
    );
  }

  static pw.TextDirection _getTextDirection(InvoiceLanguage language) {
    switch (language) {
      case InvoiceLanguage.english:
        return pw.TextDirection.ltr; // Left-to-right for English
      case InvoiceLanguage.arabic:
      case InvoiceLanguage.kurdish:
        return pw.TextDirection.rtl; // Right-to-left for Arabic and Kurdish
    }
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
  final String phoneNo1; // Add branch phone numbers
  final String phoneNo2;

  ReceiverInfo({
    required this.name,
    required this.phone,
    required this.street,
    required this.apartment,
    required this.city,
    required this.country,
    required this.zipCode,
    required this.branch,
    required this.phoneNo1,
    required this.phoneNo2,
  });
}

class CostSummary {
  final String shippingCost;
  final String emptyBoxCost;
  final String customsAdmin;
  final String deliveryCost;
  final String insuranceAmount;
  final String totalCost;
  final String amountPaid;
  final String amountDue;
  final String amountDueEur;
  final bool isInsuranceEnabled;

  CostSummary({
    required this.shippingCost,
    required this.emptyBoxCost,
    required this.customsAdmin,
    required this.deliveryCost,
    required this.insuranceAmount,
    required this.totalCost,
    required this.amountPaid,
    required this.amountDue,
    required this.amountDueEur,
    required this.isInsuranceEnabled,
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
            _getTranslation('الرمز البريدى', 'Postal Code', 'کۆدی پۆستە'),
        'city': _getTranslation('المدينة', 'City', 'شار'),
        'country': _getTranslation('الدولة', 'Country', 'وڵات'),
        'agent_info':
            _getTranslation('معلومات الوكيل', 'Agent Info', 'زانیاری وەکیل'),
        'post_office_pickup': _getTranslation(
            'يتم استلام البريد من مكتب البريد ادناه',
            'Mail is received from the post office below.',
            'پۆست لە پۆستەخانەی خوارەوە وەرگیراوە'),
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
        'note': _getTranslation('ملاحظة', "Note", "تێبینی"),

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
          'کۆمپانیای ستێرس (EUKnet) تەنها کاڵا و ماددە یاساییەکان دەگوازێتەوە. ئەگەر هەر ماددەیەکی نایاسایی یان قەدەغەکراو لە ناو بارەکەی نێردەر بدۆزرێتەوە، نێردەر هەموو تاوانە دارایی و یاساییەکان لەلایەن دەسەڵاتە پەیوەندیدارەکانەوە دەگرێتە ئەستۆ، و نرخی گواستنەوە کە دراوە بە کۆمپانیای ستێرس ناگەڕێتەوە. نێردەر هەموو بەرپرسیاریەتی یاساییەکان دەگرێتە ئەستۆ، نەک کۆمپانیای ستێرس (EUKnet).',
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
