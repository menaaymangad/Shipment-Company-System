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

  static Future<void> initializeFonts() async {
    try {
      // Load Arabic fonts
      final cairoBold = await loadCairoFont(isBold: true);
      final cairoRegular = await loadCairoFont(isBold: false);

      // Add to fallback list
      _fontFallback = [cairoBold, cairoRegular];
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
  }) {
    return pw.TextStyle(
      font: baseFont,
      fontSize: fontSize.sp,
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
    await initializeFonts();
    final pdf = pw.Document();

    // Load images
    final euknetLogo = pw.MemoryImage(
        await loadAssetImage('assets/icons/EUKnet Logo Invoice.png'));
    final stersLogo = pw.MemoryImage(
        await loadAssetImage('assets/icons/Sters Logo N-BG.png'));
    final qrCode =
        pw.MemoryImage(await loadAssetImage('assets/icons/Sters QR.png'));

    final termsSection =
        await buildTermsAndConditionsSection(regularFont, boldFont);

    pdf.addPage(
      
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(5),
        build: (context) => pw.Container(
          decoration: pw.BoxDecoration(
            color: PdfColors.white,
            border: pw.Border.all(color: PdfColors.black),
          ),
          child: pw.Column(
            children: [
              buildHeader(euknetLogo, stersLogo, boldFont, receiver),
              buildTitleBar(boldFont),
              buildCodeSection(shipment, regularFont),
              pw.SizedBox(height: 20.h),
              buildSenderReceiverAndCostsSection(
                  sender, receiver, costs, regularFont, boldFont, qrCode),
              pw.SizedBox(height: 20.h),
              pw.Expanded(child: termsSection),
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

  static pw.Widget buildHeader(pw.ImageProvider euknetLogo,
      pw.ImageProvider stersLogo, pw.Font boldFont, ReceiverInfo receiver) {
    return pw.Padding(
      padding: pw.EdgeInsets.symmetric(horizontal: 20.w),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Image(euknetLogo, width: 600.w, height: 100.h),
          pw.Column(
            children: [
              pw.Text(
                'شركة ستيرس',
                style: getTextStyle(baseFont: boldFont, fontSize: 24),
                textDirection: pw.TextDirection.rtl,
                textScaleFactor: 2,
              ),
              pw.SizedBox(height: 10.h),
              pw.Text(
                'الرائدة في مجال النقل الدولي',
                style: getTextStyle(baseFont: boldFont, fontSize: 20),
                textDirection: pw.TextDirection.rtl,
              ),
              pw.SizedBox(height: 10.h),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Row(
                    children: [
                      pw.Text(
                        '07702961701\n07721001999',
                        style: getTextStyle(baseFont: boldFont, fontSize: 20),
                      ),
                      pw.SizedBox(width: 10.w),
                      pw.Text(
                        'الهاتف:',
                        style: getTextStyle(baseFont: boldFont, fontSize: 20),
                        textDirection: pw.TextDirection.rtl,
                      ),
                    ],
                  ),
                  pw.SizedBox(width: 60.w),
                  pw.Row(
                    children: [
                      pw.Text(
                        receiver.branch,
                        style: getTextStyle(baseFont: boldFont, fontSize: 20),
                      ),
                      pw.SizedBox(width: 10.w),
                      pw.Text(
                        'فرع:',
                        style: getTextStyle(baseFont: boldFont, fontSize: 20),
                        textDirection: pw.TextDirection.rtl,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          pw.Image(stersLogo, width: 100.w),
        ],
      ),
    );
  }

  static pw.Widget buildTitleBar(pw.Font boldFont) {
    return pw.Container(
      width: double.infinity,
      decoration: const pw.BoxDecoration(
        color: PdfColors.blue900,
      ),
      padding: pw.EdgeInsets.symmetric(vertical: 8.h),
      child: pw.Center(
        child: pw.Text(
          'وصل تسليم ودفع تكاليف النقل الى اوروبا',
          style: getTextStyle(
              baseFont: boldFont, fontSize: 20, color: PdfColors.white),
          textDirection: pw.TextDirection.rtl,
        ),
      ),
    );
  }

  static pw.Widget buildCodeSection(
      ShipmentDetails shipment, pw.Font regularFont) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex(
            '#FFB99B'), // Light orange color matching the image
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
            style: getTextStyle(baseFont: regularFont, fontSize: 20),
          ),
          pw.Row(
            children: [
              // Left side - English

              // Center - Arabic
              pw.Text(
                'كود الاستلام :',
                style: getTextStyle(baseFont: regularFont, fontSize: 20),
                textDirection: pw.TextDirection.rtl,
              ),
              pw.SizedBox(width: 10.w),
              // Right side - Date
              pw.Container(
                padding: pw.EdgeInsets.only(left: 10.w),
                decoration: const pw.BoxDecoration(
                    border: pw.Border(
                        left: pw.BorderSide(color: PdfColors.black, width: 1))),
                child: pw.Text(
                  'التاريخ: ${shipment.date}',
                  style: getTextStyle(baseFont: regularFont, fontSize: 16),
                  textDirection: pw.TextDirection.rtl,
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
      pw.ImageProvider qrCode) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Left side - Sender-Receiver Info
        pw.Expanded(
          child: pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black, width: 1),
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
                  padding: const pw.EdgeInsets.symmetric(vertical: 8),
                  child: pw.Text(
                    'معلومات المرسل - المستلم',
                    style: getTextStyle(baseFont: boldFont, fontSize: 16),
                    textAlign: pw.TextAlign.center,
                    textDirection: pw.TextDirection.rtl,
                  ),
                ),

                // Info Rows
                buildTableRow('اسم المرسل', sender.name, regularFont),
                buildTableRow('رقم هاتف المرسل', sender.phone, regularFont),
                buildTableRow('اسم المستلم', receiver.name, regularFont),
                buildTableRow('رقم هاتف المستلم', receiver.phone, regularFont),
                buildTableRow('العنوان الكامل (الشارع - رقم الدار)',
                    receiver.street, regularFont),
                buildTableRow(
                    'الرمز البريدي للمدينة', receiver.zipCode, regularFont),
                buildTableRow('المدينة', receiver.city, regularFont),
                buildTableRow('الدولة', receiver.country, regularFont),

                // Agent Info Header
                pw.Container(
                  height: 95.h,
                  width: double.infinity,
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                        top: pw.BorderSide(color: PdfColors.black, width: 1)),
                  ),
                  padding: const pw.EdgeInsets.symmetric(vertical: 8),
                  child: pw.Text(
                    'معلومات الوكيل',
                    style: getTextStyle(baseFont: boldFont, fontSize: 16),
                    textAlign: pw.TextAlign.center,
                    textDirection: pw.TextDirection.rtl,
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
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black, width: 1),
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
                  padding: const pw.EdgeInsets.symmetric(vertical: 8),
                  child: pw.Text(
                    'تكاليف النقل',
                    style: getTextStyle(baseFont: boldFont, fontSize: 16),
                    textAlign: pw.TextAlign.center,
                    textDirection: pw.TextDirection.rtl,
                  ),
                ),

                // Cost Rows
                buildCostTableRow(
                    'كلفة النقل', costs.shippingCost, regularFont),
                buildCostTableRow('قيمة الكارتون الفارغ', '', regularFont),
                buildCostTableRow('الكمرك والاداريات', '', regularFont),
                buildCostTableRow(
                    'كلفة التوصيل الى عنوان المستلم', '', regularFont),
                buildCostTableRow(
                    'كلفة التأمين', costs.insuranceAmount, regularFont),
                buildCostTableRow(
                    'الكلفة الكلية', costs.totalCost, regularFont),
                buildCostTableRow(
                    'المبلغ المدفوع', costs.amountPaid, regularFont,
                    highlighted: true),
                buildCostTableRow(
                    'المبلغ المطلوب', costs.amountDue, regularFont),
                buildCostTableRow(
                    'المبلغ المطلوب دفعه في اوروبا', '', regularFont),

                // Insurance Section
                pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.end,
                    children: [
                      pw.Expanded(
                        child: buildCheckbox('كلا', regularFont),
                      ),
                      pw.SizedBox(width: 20.w),
                      pw.Expanded(
                        child: buildCheckbox('نعم', regularFont),
                      ),
                      pw.SizedBox(width: 40.w),
                      pw.Expanded(
                        child: pw.Text(
                          'تأمين البضاعة :',
                          style:
                              getTextStyle(baseFont: regularFont, fontSize: 16),
                          textDirection: pw.TextDirection.rtl,
                        ),
                      ),
                    ],
                  ),
                ),

                // Bottom Table
                pw.Table(
                  border: pw.TableBorder.all(),
                  children: [
                    pw.TableRow(
                      children: [
                        buildTableHeader('عدد الكراتين', regularFont),
                        buildTableHeader('الوزن / كغم', regularFont),
                        buildTableHeader('تفاصيل البضاعة', regularFont),
                        buildTableHeader('قيمة البضاعة', regularFont),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Container(height: 80.h),
                        pw.Container(height: 80.h),
                        pw.Container(height: 80.h),
                        pw.Container(height: 80.h),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Update these methods in your PDFGenerator class

  static pw.Widget buildTableRow(String label, String value, pw.Font font) {
    return pw.Container(
      decoration: const pw.BoxDecoration(
        border: pw.Border(
            bottom: pw.BorderSide(color: PdfColors.black, width: 0.5)),
      ),
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.end, // Right to left alignment
        children: [
          pw.Expanded(
            flex: 3,
            child: pw.Padding(
              padding: const pw.EdgeInsets.only(right: 8),
              child: pw.Text(
                value,
                style: getTextStyle(baseFont: font, fontSize: 16),
                textDirection: pw.TextDirection.rtl,
              ),
            ),
          ),
          pw.Container(width: 1, color: PdfColors.black, height: 20.h),
          pw.Expanded(
            flex: 2,
            child: pw.Text(
              label,
              style: getTextStyle(baseFont: font, fontSize: 16),
              textAlign: pw.TextAlign.right,
              textDirection: pw.TextDirection.rtl,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget buildCostTableRow(String label, String value, pw.Font font,
      {bool highlighted = false}) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        color: highlighted ? PdfColor.fromHex('#FFB99B') : null,
        border: const pw.Border(
            bottom: pw.BorderSide(color: PdfColors.black, width: 0.5)),
      ),
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.end, // Right to left alignment
        children: [
          pw.Expanded(
            child: pw.Center(
              child: pw.Text(
                'دينار عراقي',
                style: getTextStyle(baseFont: font, fontSize: 12),
                textAlign: pw.TextAlign.right,
                textDirection: pw.TextDirection.rtl,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Padding(
              padding: const pw.EdgeInsets.only(right: 8),
              child: pw.Text(
                value,
                style: getTextStyle(baseFont: font, fontSize: 14),
                textDirection: pw.TextDirection.rtl,
              ),
            ),
          ),
          pw.Container(width: 1, color: PdfColors.black, height: 20.h),
          pw.Expanded(
            flex: 3,
            child: pw.Text(
              label,
              style: getTextStyle(baseFont: font, fontSize: 14),
              textAlign: pw.TextAlign.right,
              textDirection: pw.TextDirection.rtl,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget buildTableHeader(String text, pw.Font font) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        text,
        style: getTextStyle(baseFont: font, fontSize: 16),
        textAlign: pw.TextAlign.right,
        textDirection: pw.TextDirection.rtl,
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
          style: getTextStyle(
            baseFont: font,
            fontSize: 16,
          ),
          textDirection: pw.TextDirection.rtl,
        ),
      ],
    );
  }

  static Future<pw.Widget> buildTermsAndConditionsSection(
    pw.Font regularFont,
    pw.Font boldFont,
  ) async {
    // Load prohibited items icons
    final prohibitedIconsImage1 =
        pw.MemoryImage(await loadAssetImage('assets/icons/02.png'));
    final prohibitedIconsImage2 =
        pw.MemoryImage(await loadAssetImage('assets/icons/03.png'));
    final prohibitedIconsImage3 = pw.MemoryImage(
        await loadAssetImage('assets/icons/Sters Logo N-BG (1).png'));

    return pw.Container(
      decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.black, width: 0.5)),
      margin: const pw.EdgeInsets.only(top: 20),
      child: pw.Column(
        children: [
          // Red title bar
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(vertical: 8),
            child: pw.Text(
              'يرجى قراءة النقاط ادناه ثم بعد القراءة والموافقة يرجى التوقيع اسفل الوصل',
              style: getTextStyle(
                  baseFont: boldFont, fontSize: 20, color: PdfColors.red),
              textAlign: pw.TextAlign.center,
              textDirection: pw.TextDirection.rtl,
            ),
          ),

          // Main content container
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Column(
                children: [
                  pw.Container(
                    decoration: pw.BoxDecoration(
                        border:
                            pw.Border.all(color: PdfColors.black, width: 0.5)),
                    padding: pw.EdgeInsets.symmetric(
                        horizontal: 20.w, vertical: 10.h),
                    width: 300.w,
                    child: pw.Column(
                      children: [
                        // First row of icons
                        pw.Image(prohibitedIconsImage1),
                        // Second row of icons
                        pw.Image(prohibitedIconsImage2),
                      ],
                    ),
                  ),
                  pw.Container(
                    decoration: pw.BoxDecoration(
                        border:
                            pw.Border.all(color: PdfColors.black, width: 0.5)),
                    padding: pw.EdgeInsets.symmetric(
                        horizontal: 20.w, vertical: 10.h),
                    width: 300.w,
                    height: 210.h,
                    child: pw.Center(
                      child: pw.Image(prohibitedIconsImage3),
                    ),
                  ),
                ],
              ),
              // Left side - Combined icons from both images

              // Right side - Terms text
              pw.Expanded(
                child: pw.Container(
                  decoration: pw.BoxDecoration(
                      border:
                          pw.Border.all(color: PdfColors.black, width: 0.5)),
                  padding: const pw.EdgeInsets.all(10),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      buildTermItem(
                        '1',
                        'شركة ستيرس (EUKnet) تقوم فقط بشحن ونقل البضائع والمواد المسموح بها قانونيا، وفي حال وجود اي مادة مخالفة او غير مسموحة من الناحية القانونية داخل بضاعة المرسل، فان المرسل يتحمل كافة الغرامات المالية والقانونية من الجهات المختصة ولا ترجع للمرسل مبلغ كلفة النقل المدفوعة ل شركة ستيرس . المرسل يتحمل كل المسؤولية القانونية وليست شركة ستيرس (EUKnet)',
                        regularFont,
                      ),
                      buildTermItem(
                        '2',
                        'يجب على المرسل اعطاء العنوان ورقم هاتف المستلم بشكل صحيح وكامل، بخلاف ذلك فان شركة ستيرس (EUKnet) ليست مسؤولة عن اي تأخير او ضياع المواد بسبب عنوان خاطئ او غير كامل.',
                        regularFont,
                      ),
                      buildTermItem(
                        '3',
                        'في حال حدوث أي ضرر بالمواد فإن شركة ستيرس تقوم بالتعويض لصاحبها على الشكل التالي:',
                        regularFont,
                      ),
                      pw.Padding(
                        padding: pw.EdgeInsets.only(right: 20.w),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.end,
                          children: [
                            buildTermItem(
                              'أ',
                              'العملاء الذين قاموا بالتأمين الاضافي على المواد والبضائع المرسلة وذلك بدفع نسبة عن قيمة البضاعة فإن الشركة مسؤولة عن التعويض الكامل لصاحبها.',
                              regularFont,
                            ),
                            buildTermItem(
                              'ب',
                              'العملاء الذين لم يقوموا بالتامين الاضافي على المواد والبضائع فان الشركة تعوض فقط مبلغ اجرة النقل لصاحبها واعادة كلفة النقل المستلمة الى صاحبها.',
                              regularFont,
                            ),
                          ],
                        ),
                      ),
                      buildTermItem(
                        '4',
                        'يجب على المرسل التقيد بالتعليمات الموجهة من قبل موظفينا، والموجودة على حائط الشركة.',
                        regularFont,
                      ),
                      buildTermItem(
                        '5',
                        'في حالة وجود (السكائر، الفصيل للاكل، الادوية،الذهب،الفضة، كرستال، المشروبات الكحولية، السلاح بانواعه والمعدات العسكرية، المواد المخدرة، التحفيات والقطع الاثرية) داخل اغراضكم (المرسل) فان الشخص المرسل يتحمل كل المسؤولية القانونية وليست شركة ستيرس (EUKnet).',
                        regularFont,
                      ),
                      buildTermItem(
                        '6',
                        'شركة ستيرس (EUKnet) غير مسؤولة في حالة فرض الرسوم الكمركية في اية نقطة حدودية، بل صاحب البضاعة ملزم بدفع هذه الرسومات.',
                        regularFont,
                      ),
                      buildTermItem(
                        '7',
                        'المرسل قرأ هذه الشروط العامة وفهمها وتوقيعه يعتبر موافقة صريحة عليها.',
                        regularFont,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Footer with contact information
          pw.Container(
            decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.black, width: 0.5)),
            padding:
                const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Expanded(
                  child: pw.Container(),
                ),
                pw.Container(
                  padding: pw.EdgeInsets.symmetric(horizontal: 20.w),
                  decoration: const pw.BoxDecoration(
                    border: pw.Border.symmetric(
                      // horizontal:
                      //     pw.BorderSide(color: PdfColors.black, width: 0.5),
                      vertical:
                          pw.BorderSide(color: PdfColors.black, width: 0.5),
                    ),
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      'الملاحظات',
                      style: getTextStyle(baseFont: boldFont, fontSize: 16),
                      textDirection: pw.TextDirection.rtl,
                    ),
                  ),
                ),
                pw.SizedBox(width: 10.w),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Email: info@euknet.com',
                        style:
                            getTextStyle(baseFont: regularFont, fontSize: 14)),
                    pw.Text('Website: www.euknet.com',
                        style:
                            getTextStyle(baseFont: regularFont, fontSize: 14)),
                  ],
                ),
                pw.Container(
                  width: 150,
                  child: pw.Text(
                    'المكتب الرئيسي للشركة في اوروبا',
                    style: getTextStyle(baseFont: boldFont, fontSize: 14),
                    textDirection: pw.TextDirection.rtl,
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
      margin: const pw.EdgeInsets.only(bottom: 5),
      child: pw.Text(
        '$number - $text',
        style: getTextStyle(baseFont: font, fontSize: 17),
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
      print('Printing Error: $e');
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
