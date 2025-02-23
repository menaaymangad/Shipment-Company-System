import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:typed_data';

import 'package:app/models/city_model.dart';

class ShippingLabelGenerator {
  static Future<pw.Font> loadFont({bool isBold = false}) async {
    try {
      final fontPath =
          isBold ? 'fonts/Roboto-Bold.ttf' : 'fonts/Roboto-Regular.ttf';
      final fontData = await rootBundle.load(fontPath);
      return pw.Font.ttf(fontData);
    } catch (e) {
      return isBold ? pw.Font.timesBold() : pw.Font.times();
    }
  }

  static Future<pw.MemoryImage?> _loadAssetImage(String assetPath) async {
    try {
      final ByteData data = await rootBundle.load(assetPath);
      return pw.MemoryImage(data.buffer.asUint8List());
    } catch (e) {
      print('Error loading asset image $assetPath: $e');
      return null;
    }
  }

  static Future<Uint8List> generateShippingLabel({
    required SenderDetails sender,
    required ReceiverDetails receiver,
    required ShipmentInfo shipment,
    required City selectedCity,
  }) async {
    final pdf = pw.Document();
    final regularFont = await loadFont();
    final boldFont = await loadFont(isBold: true);

    // Load logos and images
    final euknetLogo = await _loadAssetImage('assets/icons/EUKnet Logo.png');
    final stersLogo = await _loadAssetImage('assets/icons/Sters Logo N-BG.png');
    final stersQr = await _loadAssetImage('assets/icons/Sters QR.png');
    final flagImage = await _loadAssetImage(selectedCity.circularFlag);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        margin: const pw.EdgeInsets.all(0),
        build: (context) => pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.black, width: 1),
          ),
          child: pw.Padding(
            padding: const pw.EdgeInsets.all(8),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                // Header Section
                _buildHeaderSection(euknetLogo, stersLogo, stersQr, boldFont),
                pw.SizedBox(height: 10),

                // Main Content
                pw.Expanded(
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // Shipping Details
                      pw.Expanded(
                        flex: 7,
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            // From Section
                            _buildFromSection(
                                sender, shipment, regularFont, boldFont),
                            pw.SizedBox(height: 15),

                            // To Section
                            _buildToSection(receiver, regularFont, boldFont),

                            // Barcode Section (placeholder)
                            pw.SizedBox(height: 15),
                            _buildBarcodeSection(shipment.code, regularFont),
                          ],
                        ),
                      ),

                      // Flag Section
                      pw.SizedBox(width: 10),
                      pw.Container(
                        width: 100,
                        child: pw.Column(
                          children: [
                            if (flagImage != null)
                              pw.Image(flagImage, width: 80, height: 80),
                            pw.SizedBox(height: 10),
                            pw.Text(
                              selectedCity.cityName.toUpperCase(),
                              style: pw.TextStyle(
                                font: boldFont,
                                fontSize: 12,
                              ),
                              textAlign: pw.TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Footer
                _buildFooterSection(regularFont),
              ],
            ),
          ),
        ),
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildHeaderSection(
    pw.MemoryImage? euknetLogo,
    pw.MemoryImage? stersLogo,
    pw.MemoryImage? stersQr,
    pw.Font boldFont,
  ) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 0.5),
      ),
      padding: const pw.EdgeInsets.all(8),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          // EUKNET Side
          pw.Row(
            children: [
              if (euknetLogo != null)
                pw.Image(euknetLogo, width: 50, height: 50),
              pw.SizedBox(width: 8),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'EUKNET Transport B.V.',
                    style: pw.TextStyle(font: boldFont, fontSize: 12),
                  ),
                  pw.Text(
                    'De Stigter 98\n1351 AH Almere\nThe Netherlands\n'
                    'Tel 1: 0031-(0)36 5342869\n'
                    'Tel 2: 0031-(0)36 5342869\n'
                    'Email: info@euknet.com\n'
                    'Web: www.euknet.com',
                    style: pw.TextStyle(fontSize: 8),
                  ),
                ],
              ),
            ],
          ),

          // STERS Side
          pw.Row(
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'STERS TRANSPORT',
                    style: pw.TextStyle(font: boldFont, fontSize: 12),
                  ),
                  pw.Text(
                    'Sulemany: 0770 2120019\n'
                    'Hawler: 0756141200\n'
                    'Duhok: 0750 8957008\n'
                    'Karkuk: 0771 4173401\n'
                    'Baghdad: 0770 2961701',
                    style: pw.TextStyle(fontSize: 8),
                    textAlign: pw.TextAlign.right,
                  ),
                ],
              ),
              pw.SizedBox(width: 8),
              pw.Column(
                children: [
                  if (stersLogo != null)
                    pw.Image(stersLogo, width: 30, height: 30),
                  pw.SizedBox(height: 4),
                  if (stersQr != null) pw.Image(stersQr, width: 40, height: 40),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFromSection(
    SenderDetails sender,
    ShipmentInfo shipment,
    pw.Font regularFont,
    pw.Font boldFont,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('From', boldFont),
        _buildFormField('Sender Name', sender.name, regularFont),
        _buildFormField(
            'Number of Parcels', '${shipment.itemNumber} Boxes', regularFont),
        _buildFormField('Weight (Kg)', shipment.weight, regularFont),
        _buildFormField('Item Details', shipment.itemDetails, regularFont),
      ],
    );
  }

  static pw.Widget _buildToSection(
    ReceiverDetails receiver,
    pw.Font regularFont,
    pw.Font boldFont,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('To', boldFont),
        _buildFormField('Receiver Name', receiver.name, regularFont),
        _buildFormField('Address', receiver.address, regularFont),
        _buildFormField('City', receiver.city, regularFont),
        _buildFormField('Country', receiver.country, regularFont),
        _buildFormField('Phone', receiver.phone, regularFont),
      ],
    );
  }

  static pw.Widget _buildBarcodeSection(String code, pw.Font regularFont) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Tracking Code:',
            style: pw.TextStyle(font: regularFont, fontSize: 10),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            code,
            style: pw.TextStyle(font: regularFont, fontSize: 12),
          ),
          // Add actual barcode here if needed
        ],
      ),
    );
  }

  static pw.Widget _buildFooterSection(pw.Font regularFont) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 10),
      child: pw.Text(
        'This shipping label is valid for 30 days from the date of issue.',
        style: pw.TextStyle(font: regularFont, fontSize: 8),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static pw.Widget _buildSectionHeader(String title, pw.Font boldFont) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      decoration: pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black)),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          font: boldFont,
          fontSize: 11,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  static pw.Widget _buildFormField(
      String label, String value, pw.Font regularFont) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      decoration: pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300)),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 90,
            child: pw.Text(
              '$label:',
              style: pw.TextStyle(font: regularFont, fontSize: 9),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(font: regularFont, fontSize: 9),
            ),
          ),
        ],
      ),
    );
  }
}

// Updated Data Models
class SenderDetails {
  final String name;

  const SenderDetails({required this.name});
}

class ReceiverDetails {
  final String name;
  final String phone;
  final String city;
  final String country;
  final String address;

  const ReceiverDetails({
    required this.name,
    required this.phone,
    required this.city,
    required this.country,
    required this.address,
  });
}

class ShipmentInfo {
  final String itemNumber;
  final String weight;
  final String itemDetails;
  final String code;

  const ShipmentInfo({
    required this.itemNumber,
    required this.weight,
    required this.itemDetails,
    required this.code,
  });
}
