import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';

/// QR code de um texto/URL, sempre em preto sobre branco para ser lido por qualquer câmera
class AppQrCode extends StatelessWidget {
  final String data;
  final double size;

  const AppQrCode({super.key, required this.data, this.size = 160});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(size * 0.06),
      child: BarcodeWidget(
        barcode: Barcode.qrCode(errorCorrectLevel: BarcodeQRCorrectionLevel.medium),
        data: data,
        width: size,
        height: size,
        color: Colors.black,
        backgroundColor: Colors.white,
        drawText: false,
      ),
    );
  }
}
