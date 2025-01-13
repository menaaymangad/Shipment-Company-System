import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

class LabelPDFPreviewDialog extends StatelessWidget {
  final File pdfFile;
  final String title;

  const LabelPDFPreviewDialog({
    super.key,
    required this.pdfFile,
    this.title = 'PDF Preview',
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Column(
        children: [
          AppBar(
            elevation: 1,
            iconTheme: const IconThemeData(color: Colors.black),
            backgroundColor: Colors.white,
            titleTextStyle: TextStyle(
                color: Colors.black,
                fontSize: 36.sp,
                fontWeight: FontWeight.bold),
            title: Text(title),
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.print,
                  color: Colors.black,
                ),
                onPressed: () async {
                  await _safePrintDocument(context);

                  Navigator.of(context).pop('print'); // Return 'print' result
                },
              ),
              IconButton(
                icon: const Icon(
                  Icons.download,
                  color: Colors.black,
                ),
                onPressed: () async {
                  Navigator.of(context).pop('save'); // Return 'save' result
                },
              ),
              IconButton(
                icon: const Icon(
                  Icons.close,
                  color: Colors.black,
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
          Expanded(
            child: PdfPreview(
              build: (format) => pdfFile.readAsBytesSync(),
              initialPageFormat: PdfPageFormat.a4,
              allowPrinting: true,
              allowSharing: true,
              canChangePageFormat: false,
              canChangeOrientation: false,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _safePrintDocument(BuildContext context) async {
    try {
      if (Platform.isWindows) {
        await Printing.layoutPdf(
          onLayout: (_) => pdfFile.readAsBytesSync(),
          name: 'Label',
          usePrinterSettings: true,
          format: PdfPageFormat.a4,
        );
      } else {
        await Printing.layoutPdf(
          onLayout: (_) => pdfFile.readAsBytesSync(),
          format: PdfPageFormat.a4,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Printing failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
