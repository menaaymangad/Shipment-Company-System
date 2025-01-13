import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';

class InvoicePDFPreviewDialog extends StatefulWidget {
  final File pdfFile;
  final String title;

  const InvoicePDFPreviewDialog({
    super.key,
    required this.pdfFile,
    this.title = 'PDF Preview',
  });

  @override
  State<InvoicePDFPreviewDialog> createState() =>
      _InvoicePDFPreviewDialogState();
}

class _InvoicePDFPreviewDialogState extends State<InvoicePDFPreviewDialog> {
  final TextEditingController _copiesController =
      TextEditingController(text: '2'); // Default to 2 copy

  @override
  void dispose() {
    _copiesController.dispose();
    super.dispose();
  }

  bool _isPrinting = false; // Add this to your state

  Future<void> _safePrintDocument(BuildContext context) async {
    setState(() {
      _isPrinting = true; // Start printing
    });

    try {
      int copies = int.tryParse(_copiesController.text) ?? 2;
      if (copies < 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid number of copies. Defaulting to 2.'),
            backgroundColor: Colors.orange,
          ),
        );
        copies = 2;
      }

      for (int i = 0; i < copies; i++) {
        if (Platform.isWindows) {
          await Printing.layoutPdf(
            onLayout: (_) => widget.pdfFile.readAsBytesSync(),
            name: 'Invoice',
            usePrinterSettings: true,
            format: PdfPageFormat.a4,
          );
        } else {
          await Printing.layoutPdf(
            onLayout: (_) => widget.pdfFile.readAsBytesSync(),
            format: PdfPageFormat.a4,
          );
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Printed $copies copies successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Printing failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isPrinting = false; // Stop printing
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Column(
        children: [
          AppBar(
            elevation: 1,
            iconTheme: const IconThemeData(
              color: Colors.black,
            ),
            backgroundColor: Colors.white,
            title: Text(widget.title),
            titleTextStyle: TextStyle(
              color: Colors.black,
              fontSize: 36.sp,
              fontWeight: FontWeight.w500,
            ),
            actions: [
              // Disable the print button while printing
              _isPrinting
                  ? const CircularProgressIndicator()
                  : IconButton(
                      icon: const Icon(Icons.print),
                      onPressed: () => _safePrintDocument(context),
                    ),
              IconButton(
                icon: const Icon(Icons.download),
                onPressed: () async {
                  Navigator.of(context).pop('save');
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
          Padding(
            padding: EdgeInsets.all(16.0.r),
            child: TextField(
              controller: _copiesController,
              decoration: const InputDecoration(
                labelText: 'Number of Copies',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ),
          Expanded(
            child: PdfPreview(
              build: (format) => widget.pdfFile.readAsBytesSync(),
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
}
