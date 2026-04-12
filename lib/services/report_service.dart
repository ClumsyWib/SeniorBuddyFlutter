import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class ReportService {
  /// Generates a professional, premium certificate and opens the platform print/save-as-pdf dialog.
  /// Build the PDF document for the certificate
  static Future<pw.Document> buildCertificatePdf({
    required String volunteerName,
    required String totalHours,
    required String totalTasks,
    required String joinDate,
  }) async {
    final pdf = pw.Document();

    // High-quality font loading
    final font = await PdfGoogleFonts.merriweatherRegular();
    final fontBold = await PdfGoogleFonts.merriweatherBold();
    final fontScript = await PdfGoogleFonts.greatVibesRegular();

    // Define Premium Colors
    final navyColor = PdfColor.fromInt(0xFF1A237E);
    final goldColor = PdfColor.fromInt(0xFFD4AF37);
    final darkGoldColor = PdfColor.fromInt(0xFFA67C00);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(0),
        build: (pw.Context context) {
          return pw.Stack(
            children: [
              // Background Frame Decoration
              pw.Container(
                width: double.infinity,
                height: double.infinity,
                margin: const pw.EdgeInsets.all(30),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: goldColor, width: 8),
                ),
              ),
              pw.Container(
                width: double.infinity,
                height: double.infinity,
                margin: const pw.EdgeInsets.all(45),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: navyColor, width: 2),
                ),
              ),

              // Corner Ornaments Placeholder
              _buildCornerOrnaments(goldColor),

              // Main Content
              pw.Padding(
                padding:
                    const pw.EdgeInsets.symmetric(horizontal: 80, vertical: 60),
                child: pw.Column(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    // Platform Branding
                    pw.Text(
                      'SENIOR BUDDY',
                      style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 32,
                        color: navyColor,
                        letterSpacing: 4,
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(vertical: 4),
                      child:
                          pw.Container(width: 80, height: 2, color: goldColor),
                    ),
                    pw.SizedBox(height: 15),

                    // Certificate Title
                    pw.Text(
                      'EXCELLENCE IN VOLUNTEER SERVICE',
                      style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 22,
                        color: PdfColors.grey900,
                        letterSpacing: 2,
                      ),
                    ),
                    pw.SizedBox(height: 35),

                    pw.Text(
                      'THIS CERTIFICATE IS OFFICIALLY PRESENTED TO',
                      style: pw.TextStyle(
                        font: font,
                        fontSize: 12,
                        color: PdfColors.grey700,
                        letterSpacing: 1,
                      ),
                    ),
                    pw.SizedBox(height: 20),

                    // Volunteer Name
                    pw.Text(
                      volunteerName,
                      style: pw.TextStyle(
                        font: fontScript,
                        fontSize: 54,
                        color: navyColor,
                      ),
                    ),
                    pw.Container(
                      width: 400,
                      height: 1.5,
                      color: goldColor,
                      margin: const pw.EdgeInsets.symmetric(vertical: 5),
                    ),
                    pw.SizedBox(height: 25),

                    // Achievement Text
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 40),
                      child: pw.RichText(
                        textAlign: pw.TextAlign.center,
                        text: pw.TextSpan(
                          style: pw.TextStyle(
                              font: font,
                              fontSize: 13,
                              color: PdfColors.grey800,
                              height: 1.6),
                          children: [
                            const pw.TextSpan(
                                text:
                                    'In recognition of outstanding dedication and exceptional service toward the well-being of our senior community. Successfully contributing '),
                            pw.TextSpan(
                                text: '$totalHours impact hours ',
                                style: pw.TextStyle(
                                    font: fontBold, color: navyColor)),
                            const pw.TextSpan(text: 'across '),
                            pw.TextSpan(
                                text: '$totalTasks completed tasks',
                                style: pw.TextStyle(
                                    font: fontBold, color: navyColor)),
                            const pw.TextSpan(
                                text:
                                    ' highlighting a commitment to compassion and care.'),
                          ],
                        ),
                      ),
                    ),

                    pw.Spacer(),

                    // Signature & Seal Row
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Column(
                          children: [
                            pw.Text(
                              DateFormat('MMMM dd, yyyy')
                                  .format(DateTime.now()),
                              style: pw.TextStyle(
                                  font: font,
                                  fontSize: 11,
                                  color: PdfColors.grey800),
                            ),
                            pw.Container(
                                width: 140,
                                height: 1,
                                color: PdfColors.grey400,
                                margin:
                                    const pw.EdgeInsets.symmetric(vertical: 4)),
                            pw.Text('DATE OF ISSUANCE',
                                style: pw.TextStyle(
                                    font: fontBold,
                                    fontSize: 8,
                                    color: goldColor)),
                          ],
                        ),

                        // Center Seal
                        pw.Container(
                          width: 80,
                          height: 80,
                          decoration: pw.BoxDecoration(
                            shape: pw.BoxShape.circle,
                            border: pw.Border.all(color: goldColor, width: 2),
                          ),
                          child: pw.Center(
                            child: pw.Container(
                              width: 70,
                              height: 70,
                              decoration: pw.BoxDecoration(
                                shape: pw.BoxShape.circle,
                                color: darkGoldColor.withOpacity(0.05),
                                border:
                                    pw.Border.all(color: goldColor, width: 1),
                              ),
                              child: pw.Center(
                                child: pw.Transform.rotate(
                                  angle: 0.2,
                                  child: pw.Text(
                                    'OFFICIAL\nVERIFIED',
                                    textAlign: pw.TextAlign.center,
                                    style: pw.TextStyle(
                                      font: fontBold,
                                      fontSize: 9,
                                      color: darkGoldColor,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        pw.Column(
                          children: [
                            pw.Text(
                              'Sahil Patel',
                              style: pw.TextStyle(
                                  font: fontScript,
                                  fontSize: 22,
                                  color: navyColor),
                            ),
                            pw.Container(
                                width: 140,
                                height: 1,
                                color: PdfColors.grey400,
                                margin:
                                    const pw.EdgeInsets.symmetric(vertical: 4)),
                            pw.Text('AUTHORIZED SIGNATURE',
                                style: pw.TextStyle(
                                    font: fontBold,
                                    fontSize: 8,
                                    color: goldColor)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
    return pdf;
  }

  /// Generates a professional certificate and opens the platform print dialog.
  static Future<void> generateVolunteerCertificate({
    required String volunteerName,
    required String totalHours,
    required String totalTasks,
    required String joinDate,
  }) async {
    final pdf = await buildCertificatePdf(
      volunteerName: volunteerName,
      totalHours: totalHours,
      totalTasks: totalTasks,
      joinDate: joinDate,
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Certificate_${volunteerName.replaceAll(' ', '_')}',
    );
  }

  static pw.Widget _buildCornerOrnaments(PdfColor color) {
    return pw.Stack(
      children: [
        // Top Left
        pw.Positioned(
          top: 35,
          left: 35,
          child: pw.Container(width: 30, height: 30, decoration: pw.BoxDecoration(border: pw.Border(top: pw.BorderSide(color: color, width: 4), left: pw.BorderSide(color: color, width: 4)))),
        ),
        // Top Right
        pw.Positioned(
          top: 35,
          right: 35,
          child: pw.Container(width: 30, height: 30, decoration: pw.BoxDecoration(border: pw.Border(top: pw.BorderSide(color: color, width: 4), right: pw.BorderSide(color: color, width: 4)))),
        ),
        // Bottom Left
        pw.Positioned(
          bottom: 35,
          left: 35,
          child: pw.Container(width: 30, height: 30, decoration: pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: color, width: 4), left: pw.BorderSide(color: color, width: 4)))),
        ),
        // Bottom Right
        pw.Positioned(
          bottom: 35,
          right: 35,
          child: pw.Container(width: 30, height: 30, decoration: pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: color, width: 4), right: pw.BorderSide(color: color, width: 4)))),
        ),
      ],
    );
  }
}

extension on PdfColor {
  PdfColor? withOpacity(double d) {}
}
