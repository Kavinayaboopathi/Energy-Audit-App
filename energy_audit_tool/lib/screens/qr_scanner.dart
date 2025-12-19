import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  String? scannedData;
  bool isScanned = false;
  final MobileScannerController controller = MobileScannerController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (isScanned) return; // prevent multiple triggers

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final String? code = barcode.rawValue;
      if (code != null) {
        setState(() {
          scannedData = code;
          isScanned = true;
        });
        controller.stop();
        Navigator.pop(context, scannedData);
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Scan Room QR Code',
          style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            flex: 4,
            child: Stack(
              children: [
                MobileScanner(
                  controller: controller,
                  onDetect: _onDetect,
                ),
                // green border overlay
                Center(
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.green,
                        width: 4,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: scannedData == null
                  ? const Text(
                      'Scan a QR code to begin',
                      style: TextStyle(fontSize: 16, color: Colors.black54),
                    )
                  : Text(
                      'Scanned: $scannedData',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.green),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
