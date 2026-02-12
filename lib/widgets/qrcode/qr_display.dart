import 'package:flutter/material.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';

class QrDisplay extends StatelessWidget {
  final String data;
  final double size;

  const QrDisplay({super.key, required this.data, this.size = 250});

  @override
  Widget build(BuildContext context) {
    final qrCode = QrCode.fromData(
      data: data,
      errorCorrectLevel: QrErrorCorrectLevel.H,
    );
    final qrImage = QrImage(qrCode);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: SizedBox(
            width: size,
            height: size,
            child: PrettyQrView(
              qrImage: qrImage,
              decoration: const PrettyQrDecoration(
                shape: PrettyQrSmoothSymbol(
                  color: Colors.black,
                  roundFactor: 1,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Disclaimer Horizontal
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.info, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text(
              "This QR code is only valid for 2 minutes!",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
