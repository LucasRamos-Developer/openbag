import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../constants/app_constants.dart';
import '../../utils/formatters.dart';
import '../order/order_ticket.dart' show ticketSafe;
import 'verification_badge_card.dart';

/// Placa de verificação em PDF (A6), pronta para imprimir e plastificar ou colar na bag
Future<Uint8List> buildBadgePdf(VerificationBadgeData data) async {
  pw.ImageProvider? photo;
  if (data.photoUrl != null) {
    try {
      photo = await networkImage(AppConstants.fileUrl(data.photoUrl!));
    } catch (_) {
      // Sem a foto a placa ainda é gerada, com as iniciais
    }
  }

  final primary = PdfColor.fromInt(data.verified ? 0xFF00A76F : 0xFFFF6F00);
  const grey = PdfColor.fromInt(0xFF637381);
  final initials = data.fullName
      .trim()
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .take(2)
      .map((w) => w[0].toUpperCase())
      .join();

  final doc = pw.Document(title: 'Placa de verificação - ${data.fullName}', author: 'OpenBag');
  doc.addPage(pw.Page(
    pageFormat: PdfPageFormat.a6,
    margin: const pw.EdgeInsets.all(16),
    build: (context) => pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: primary, width: 2),
        borderRadius: pw.BorderRadius.circular(12),
      ),
      child: pw.Column(
        children: [
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: pw.BoxDecoration(
              color: primary,
              borderRadius: const pw.BorderRadius.only(topLeft: pw.Radius.circular(10), topRight: pw.Radius.circular(10)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(data.verified ? 'ENTREGADOR VERIFICADO' : 'VERIFICAÇÃO PENDENTE',
                    style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10)),
                pw.Text('OpenBag', style: const pw.TextStyle(color: PdfColors.white, fontSize: 10)),
              ],
            ),
          ),
          pw.SizedBox(height: 12),
          pw.ClipRRect(
            horizontalRadius: 12,
            verticalRadius: 12,
            child: pw.Container(
              width: 90,
              height: 90,
              // O PDF não tem transparência aqui: tom claro opaco atrás das iniciais
              color: PdfColor.fromInt(data.verified ? 0xFFE0F5EC : 0xFFFFF1E0),
              alignment: pw.Alignment.center,
              child: photo != null
                  ? pw.Image(photo, width: 90, height: 90, fit: pw.BoxFit.cover)
                  : pw.Text(initials, style: pw.TextStyle(fontSize: 32, fontWeight: pw.FontWeight.bold, color: primary)),
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 12),
            child: pw.Text(ticketSafe(data.fullName),
                textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
          ),
          if (data.associationName != null)
            pw.Text(
              ticketSafe([
                data.associationName!,
                if (data.memberNumber != null) 'Associado nº ${data.memberNumber}',
              ].join(' · ')),
              textAlign: pw.TextAlign.center,
              style: const pw.TextStyle(fontSize: 9, color: grey),
            ),
          if (data.vehicleLine.isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 4),
              child: pw.Text(ticketSafe(data.vehicleLine), style: const pw.TextStyle(fontSize: 9)),
            ),
          pw.Spacer(),
          pw.BarcodeWidget(
            barcode: pw.Barcode.qrCode(),
            data: data.publicUrl,
            width: 110,
            height: 110,
          ),
          pw.SizedBox(height: 4),
          pw.Text('Escaneie para ver o perfil', style: const pw.TextStyle(fontSize: 8)),
          pw.Text(data.publicUrl.replaceFirst(RegExp(r'^https?://'), ''),
              style: const pw.TextStyle(fontSize: 7, color: grey)),
          if (data.memberSince != null)
            pw.Text('No OpenBag desde ${formatDate(data.memberSince)}', style: const pw.TextStyle(fontSize: 7, color: grey)),
          pw.SizedBox(height: 10),
        ],
      ),
    ),
  ));
  return doc.save();
}

/// Converte a primeira página do PDF da placa em PNG
Future<Uint8List> badgePdfToPng(Uint8List pdf, {double dpi = 220}) async {
  final raster = await Printing.raster(pdf, pages: [0], dpi: dpi).first;
  return raster.toPng();
}
