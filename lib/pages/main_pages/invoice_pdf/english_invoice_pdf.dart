import 'dart:io';
import 'package:app/pages/main_pages/invoice_pdf/invoice_pdf.dart';
import 'package:flutter/services.dart' show ByteData, Uint8List, rootBundle;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class EnglishPDFGenerator {
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
      print('Error loading Cairo font: $e');
      // Fallback to a Unicode-supported font
      return pw.Font.timesBold();
    }
  }

  static Future<pw.Font> loadRobotoFont() async {
    try {
      final fontData = await rootBundle.load('fonts/Roboto-Regular.ttf');
      return pw.Font.ttf(fontData);
    } catch (e) {
      print('Error loading Roboto font: $e');
      return pw.Font.helvetica();
    }
  }

  static Future<void> initializeFonts() async {
    try {
      // Load fonts
      final cairoBold = await loadCairoFont(isBold: true);
      final cairoRegular = await loadCairoFont(isBold: false);
      final robotoFont = await loadRobotoFont();

      // Update fallback list
      _fontFallback = [cairoBold, cairoRegular, robotoFont];
    } catch (e) {
      print('Error initializing fonts: $e');
    }
  }

  static pw.TextStyle getTextStyle({
    required pw.Font baseFont,
    required double fontSize,
    PdfColor? color,
    pw.FontWeight? fontWeight,
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
  }) async {
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

    // Build the PDF
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(5.r),
        build: (context) => pw.Container(
          decoration: pw.BoxDecoration(
            color: PdfColors.white,
            border: pw.Border.all(color: PdfColors.black),
          ),
          alignment: pw.Alignment.centerLeft, // English is LTR
          child: pw.Column(
            mainAxisSize: pw.MainAxisSize.max,
            crossAxisAlignment: pw.CrossAxisAlignment.start, // English is LTR
            children: [
              buildHeader(euknetLogo, stersLogo, boldFont, receiver),
              buildTitleBar(boldFont),
              buildCodeSection(shipment, regularFont),
              pw.SizedBox(height: 20.h),
              buildSenderReceiverAndCostsSection(
                sender,
                receiver,
                costs,
                regularFont,
                boldFont,
                qrCode,
              ),
              pw.SizedBox(height: 20.h),
              buildTermsAndConditionsSection(regularFont, boldFont),
            ],
          ),
        ),
      ),
    );

    // Save the PDF to a file
    final output = await getTemporaryDirectory();
    final file = File(
        '${output.path}/invoice_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  // Hardcoded English text for the header
  static pw.Widget buildHeader(
    pw.ImageProvider euknetLogo,
    pw.ImageProvider stersLogo,
    pw.Font boldFont,
    ReceiverInfo receiver,
  ) {
    return pw.Padding(
      padding: pw.EdgeInsets.symmetric(horizontal: 10.w),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Image(euknetLogo, width: 600.w, height: 60.h),
          pw.Column(
            children: [
              pw.Text(
                'Sters Company', // Hardcoded English text
                style: getTextStyle(baseFont: boldFont, fontSize: 24.sp),
              ),
              pw.SizedBox(height: 5.h),
              pw.Text(
                'Leader in International Transport', // Hardcoded English text
                style: getTextStyle(baseFont: boldFont, fontSize: 20.sp),
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
                        'Phone:', // Hardcoded English text
                        style:
                            getTextStyle(baseFont: boldFont, fontSize: 20.sp),
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
                        'Branch:', // Hardcoded English text
                        style:
                            getTextStyle(baseFont: boldFont, fontSize: 20.sp),
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

  // Hardcoded English text for the title bar
  static pw.Widget buildTitleBar(pw.Font boldFont) {
    return pw.Container(
      width: double.infinity,
      decoration: const pw.BoxDecoration(
        color: PdfColors.blue900,
      ),
      padding: pw.EdgeInsets.symmetric(vertical: 8.h),
      child: pw.Center(
        child: pw.Text(
          'Delivery Receipt and Transport Costs to Europe', // Hardcoded English text
          style: getTextStyle(
              baseFont: boldFont, fontSize: 20.sp, color: PdfColors.white),
        ),
      ),
    );
  }

  // Hardcoded English text for the code section
  static pw.Widget buildCodeSection(
      ShipmentDetails shipment, pw.Font regularFont) {
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
                'Code:', // Hardcoded English text
                style: getTextStyle(baseFont: regularFont, fontSize: 20.sp),
              ),
              pw.SizedBox(width: 10.w),
              pw.Container(
                padding: pw.EdgeInsets.only(left: 10.w),
                decoration: const pw.BoxDecoration(
                    border: pw.Border(
                        left: pw.BorderSide(color: PdfColors.black, width: 1))),
                child: pw.Text(
                  'Date: ${shipment.date}', // Hardcoded English text
                  style: getTextStyle(baseFont: regularFont, fontSize: 16.sp),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Hardcoded English text for the sender-receiver and costs section
  static pw.Widget buildSenderReceiverAndCostsSection(
    SenderInfo sender,
    ReceiverInfo receiver,
    CostSummary costs,
    pw.Font regularFont,
    pw.Font boldFont,
    pw.ImageProvider qrCode,
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
                    'Sender - Receiver Info', // Hardcoded English text
                    style: getTextStyle(baseFont: boldFont, fontSize: 24.sp),
                    textAlign: pw.TextAlign.center,
                  ),
                ),

                // Info Rows
                buildTableRow('Sender Name', sender.name, regularFont),
                buildTableRow('Sender Phone', sender.phone, regularFont),
                buildTableRow('Receiver Name', receiver.name, regularFont),
                buildTableRow('Receiver Phone', receiver.phone, regularFont),
                buildTableRow('Address', receiver.street, regularFont),
                buildTableRow('Postal Code', receiver.zipCode, regularFont),
                buildTableRow('City', receiver.city, regularFont),
                buildTableRow('Country', receiver.country, regularFont),

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
                    'Agent Info', // Hardcoded English text
                    style: getTextStyle(baseFont: boldFont, fontSize: 20.sp),
                    textAlign: pw.TextAlign.center,
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
                    'Transport Costs', // Hardcoded English text
                    style: getTextStyle(baseFont: boldFont, fontSize: 24.sp),
                    textAlign: pw.TextAlign.center,
                  ),
                ),

                // Cost Rows
                buildCostTableRow(
                    'Shipping Cost', costs.shippingCost, regularFont),
                buildCostTableRow('Empty Box Cost', '', regularFont),
                buildCostTableRow('Customs & Admin', '', regularFont),
                buildCostTableRow('Delivery Cost', '', regularFont),
                buildCostTableRow(
                    'Insurance Cost', costs.insuranceAmount, regularFont),
                buildCostTableRow('Total Cost', costs.totalCost, regularFont),
                buildCostTableRow('Amount Paid', costs.amountPaid, regularFont,
                    highlighted: true),
                buildCostTableRow('Amount Due', costs.amountDue, regularFont),
                buildCostTableRow('Amount Due in EUR', '', regularFont),

                // Insurance Section
                pw.Container(
                  padding: pw.EdgeInsets.all(8.r),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.end,
                    children: [
                      pw.Expanded(
                        child: buildCheckbox('No', regularFont),
                      ),
                      pw.SizedBox(width: 20.w),
                      pw.Expanded(
                        child: buildCheckbox('Yes', regularFont),
                      ),
                      pw.SizedBox(width: 40.w),
                      pw.Expanded(
                        child: pw.Text(
                          'Insurance', // Hardcoded English text
                          style: getTextStyle(
                              baseFont: regularFont, fontSize: 24.sp),
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
                          buildTableHeader('Number of Boxes', regularFont),
                          buildTableHeader('Weight (Kg)', regularFont),
                          buildTableHeader('Goods Details', regularFont),
                          buildTableHeader('Goods Value', regularFont),
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
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Helper methods for building table rows, headers, etc.
  static pw.Widget buildTableRow(String label, String value, pw.Font font) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.black, width: 0.5.w),
        ),
      ),
      padding: pw.EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.start, // English is LTR
        children: [
          pw.Expanded(
            flex: 3,
            child: pw.Padding(
              padding: pw.EdgeInsets.only(right: 8.w),
              child: pw.Text(
                value,
                style: getTextStyle(baseFont: font, fontSize: 20.sp),
              ),
            ),
          ),
          pw.Container(width: 1, color: PdfColors.black, height: 20.h),
          pw.Expanded(
            flex: 2,
            child: pw.Text(
              label,
              style: getTextStyle(baseFont: font, fontSize: 20.sp),
              textAlign: pw.TextAlign.left, // English is LTR
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget buildCostTableRow(
    String label,
    String value,
    pw.Font font, {
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
        mainAxisAlignment: pw.MainAxisAlignment.start, // English is LTR
        children: [
          pw.Expanded(
            child: pw.Center(
              child: pw.Text(
                'IQD', // Hardcoded currency for English
                style: getTextStyle(baseFont: font, fontSize: 20.sp),
                textAlign: pw.TextAlign.left, // English is LTR
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Padding(
              padding: pw.EdgeInsets.only(right: 8.w),
              child: pw.Text(
                value,
                style: getTextStyle(baseFont: font, fontSize: 20.sp),
              ),
            ),
          ),
          pw.Container(width: 1, color: PdfColors.black, height: 20.h),
          pw.Expanded(
            flex: 3,
            child: pw.Text(
              label,
              style: getTextStyle(baseFont: font, fontSize: 20.sp),
              textAlign: pw.TextAlign.left, // English is LTR
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
        textAlign: pw.TextAlign.left, // English is LTR
      ),
    );
  }

  static pw.Widget buildCheckbox(String label, pw.Font font) {
    return pw.Row(
      children: [
        pw.Container(
          width: 20.w,
          height: 20.h,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.black),
          ),
        ),
        pw.SizedBox(width: 5.w),
        pw.Text(
          label,
          style: getTextStyle(baseFont: font, fontSize: 16.sp),
        ),
      ],
    );
  }

  static pw.Widget buildTermsAndConditionsSection(
    pw.Font regularFont,
    pw.Font boldFont,
  ) {
    return pw.Container(
      alignment: pw.Alignment.centerLeft, // English is LTR
      decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.black, width: 0.5.w)),
      margin: pw.EdgeInsets.only(top: 20.h),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start, // English is LTR
        children: [
          // Title
          pw.Container(
            width: double.infinity,
            padding: pw.EdgeInsets.symmetric(vertical: 8.h),
            decoration: pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: PdfColors.black, width: 0.5.w),
              ),
            ),
            child: pw.Text(
              'Terms and Conditions', // Hardcoded English text
              style: getTextStyle(
                baseFont: boldFont,
                fontSize: 24.sp,
                color: PdfColors.red,
              ),
              textAlign: pw.TextAlign.center,
            ),
          ),

          // Main content
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Left side - Icons
              pw.Container(
                width: 200.w,
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
                          pw.Image(pw.MemoryImage(
                              Uint8List(0))), // Placeholder for icons
                          pw.SizedBox(height: 10.h),
                          pw.Image(pw.MemoryImage(
                              Uint8List(0))), // Placeholder for icons
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
                        child: pw.Image(pw.MemoryImage(
                            Uint8List(0))), // Placeholder for icons
                      ),
                    ),
                  ],
                ),
              ),

              // Right side - Terms text
              pw.Expanded(
                flex: 3,
                child: pw.Container(
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.black, width: 0.5.w),
                  ),
                  padding: pw.EdgeInsets.all(15.r),
                  child: pw.Column(
                    crossAxisAlignment:
                        pw.CrossAxisAlignment.start, // English is LTR
                    children: [
                      for (var i = 1; i <= 7; i++)
                        pw.Padding(
                          padding: pw.EdgeInsets.only(bottom: 10.h),
                          child: buildTermItem(
                            i.toString(),
                            'Term $i: Lorem ipsum dolor sit amet, consectetur adipiscing elit.', // Hardcoded English text
                            regularFont,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Footer
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
                    crossAxisAlignment:
                        pw.CrossAxisAlignment.start, // English is LTR
                    children: [
                      pw.Text(
                        'Email: info@euknet.com', // Hardcoded English text
                        style: getTextStyle(
                            baseFont: regularFont, fontSize: 20.sp),
                      ),
                      pw.Text(
                        'Website: www.euknet.com', // Hardcoded English text
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
                    'Main Office in Europe', // Hardcoded English text
                    style: getTextStyle(baseFont: boldFont, fontSize: 20.sp),
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
        textAlign: pw.TextAlign.left, // English is LTR
      ),
    );
  }

  // Optional: Method to preview or print the PDF
  static Future<void> printPDF(File pdfFile) async {
    try {
      await Printing.layoutPdf(
        onLayout: (format) => pdfFile.readAsBytesSync(),
      );
    } catch (e) {
      print('Printing Error: $e');
      throw Exception('Failed to print PDF: $e');
    }
  }
}
