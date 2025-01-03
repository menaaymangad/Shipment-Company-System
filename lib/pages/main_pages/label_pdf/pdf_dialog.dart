import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

class PDFPreviewDialog extends StatelessWidget {
  final File pdfFile;
  final String title;

  const PDFPreviewDialog({
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
            title: Text(title),
            actions: [
              IconButton(
                icon: const Icon(Icons.print),
                onPressed: () async {
                  await _safePrintDocument(context);
                  
                  Navigator.of(context).pop('print'); // Return 'print' result
                },
              ),
              IconButton(
                icon: const Icon(Icons.download),
                onPressed: () async {
                  Navigator.of(context).pop('save'); // Return 'save' result
                },
              ),
              IconButton(
                icon: const Icon(Icons.close),
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
