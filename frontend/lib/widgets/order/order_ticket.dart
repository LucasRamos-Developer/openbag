import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../models/order/order.dart';
import '../../utils/formatters.dart';

/// Comanda do pedido em PDF para impressora térmica de 80mm
Future<void> printOrderTicket(Order order, {required String restaurantName}) {
  return Printing.layoutPdf(
    name: 'Comanda ${order.displayCode ?? order.id}',
    format: PdfPageFormat.roll80,
    onLayout: (format) => buildOrderTicket(order, restaurantName: restaurantName, format: format),
  );
}

/// A fonte padrão do PDF (Helvetica/WinAnsi) só cobre Latin-1 e alguns sinais.
/// Emojis e outros caracteres (comuns em observações) viram "?" para a comanda nunca falhar.
String ticketSafe(String text) {
  const extras = '–—‘’“”•…€';
  return String.fromCharCodes(text.runes.map((r) => r <= 0xFF || extras.runes.contains(r) ? r : 0x3F))
      .replaceAll(RegExp(r'\?{2,}'), '?');
}

Future<Uint8List> buildOrderTicket(Order order, {required String restaurantName, PdfPageFormat format = PdfPageFormat.roll80}) {
  final doc = pw.Document(title: 'Comanda ${order.displayCode ?? ''}');
  const small = pw.TextStyle(fontSize: 8);
  final bold = pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold);

  pw.Widget line(String left, String right, {pw.TextStyle? style}) => pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [pw.Expanded(child: pw.Text(ticketSafe(left), style: style ?? small)), pw.Text(right, style: style ?? small)],
      );

  doc.addPage(pw.Page(
    pageFormat: format,
    build: (context) => pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Text(ticketSafe(restaurantName), textAlign: pw.TextAlign.center, style: bold),
        pw.SizedBox(height: 4),
        pw.Text(order.displayCode ?? '#${order.id}',
            textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
        pw.Text('Pedido ${order.orderNumber}', textAlign: pw.TextAlign.center, style: small),
        pw.Text(formatDateTime(order.createdAt), textAlign: pw.TextAlign.center, style: small),
        pw.Divider(),
        for (final item in order.items) ...[
          line('${item.quantity}x ${item.name}', formatMoney(item.totalPrice), style: bold),
          for (final c in item.customizations) pw.Text(ticketSafe('   ${c.groupName}: ${c.optionName}'), style: small),
          if (item.notes != null) pw.Text(ticketSafe('   OBS: ${item.notes}'), style: bold),
          pw.SizedBox(height: 3),
        ],
        if (order.notes != null) ...[
          pw.Divider(),
          pw.Text('OBSERVAÇÕES DO PEDIDO', style: bold),
          pw.Text(ticketSafe(order.notes!), style: small),
        ],
        pw.Divider(),
        line('Subtotal', formatMoney(order.subtotal)),
        line('Entrega', formatMoney(order.deliveryFee)),
        line('TOTAL', formatMoney(order.totalAmount), style: bold),
        pw.SizedBox(height: 4),
        pw.Text('Pagamento na entrega: ${order.paymentMethod.label}', style: small),
        if (order.changeFor != null)
          pw.Text('Troco para ${formatMoney(order.changeFor!)} (levar ${formatMoney(order.changeFor! - order.totalAmount)})',
              style: bold),
        pw.Divider(),
        pw.Text('ENTREGA', style: bold),
        if (order.customerName != null) pw.Text(ticketSafe(order.customerName!), style: small),
        if (order.customerPhone != null) pw.Text('Tel: ${order.customerPhone}', style: small),
        if (order.deliveryAddress != null) pw.Text(ticketSafe(order.deliveryAddress!), style: small),
        pw.SizedBox(height: 8),
        pw.Text('OpenBag · delivery justo', textAlign: pw.TextAlign.center, style: small),
      ],
    ),
  ));
  return doc.save();
}
