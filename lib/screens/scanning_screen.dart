import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../widgets/qrcode/scanning_status_indicator.dart';
import '../widgets/modals/info_display.dart';

class ScanPairingScreen extends StatefulWidget {
  const ScanPairingScreen({super.key});

  @override
  State<ScanPairingScreen> createState() => _ScanPairingScreenState();
}

class _ScanPairingScreenState extends State<ScanPairingScreen> {
  final MobileScannerController _cameraController = MobileScannerController(
    facing: CameraFacing.back,
  );

  ScanningStatus _status = ScanningStatus.noQrCode;

  /// Prevents the modal from being shown multiple times for the same scan
  bool _hasScanned = false;

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  /// Called each time MobileScanner detects a barcode capture event
  void _onDetect(BarcodeCapture capture) {
    if (_hasScanned) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) {
      setState(() => _status = ScanningStatus.noQrCode);
      return;
    }

    final String? rawValue = barcodes.first.rawValue;
    if (rawValue == null || rawValue.isEmpty) {
      setState(() => _status = ScanningStatus.noQrCode);
      return;
    }

    // A QR code is found — update status to scanning
    setState(() {
      _status = ScanningStatus.scanning;
      _hasScanned = true;
    });

    // Small delay to show "Scanning..." before displaying the modal
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() => _status = ScanningStatus.validQrCode);

      // TODO [BACKEND]: Validate rawValue format (expected: uuid::publicKey or JSON)
      // TODO [BACKEND]: Parse rawValue into a structured model (see models/)
      // TODO [BACKEND]: If invalid format, show ErrorDisplay instead of InfoDisplay
      _showScannedDataModal(rawValue);
    });
  }

  void _showScannedDataModal(String rawValue) {
    showInfoDisplay(
      context: context,
      title: 'QR Code scanned!',
      // TODO [BACKEND]: Replace rawValue display with parsed UUID + public key
      message: rawValue,
      position: InfoModalPosition.center,
      onConfirm: () {
        Navigator.of(context).pop(); // Dismiss modal
        // TODO [BACKEND]: Trigger the pairing confirmation call here
        // TODO [BACKEND]: Navigate to relation screen on success
      },
      onCancel: () {
        Navigator.of(context).pop(); // Dismiss modal
        _resetScan(); // Allow rescanning
      },
    );
  }

  /// Resets the scan state to allow scanning a new QR code
  void _resetScan() {
    setState(() {
      _hasScanned = false;
      _status = ScanningStatus.noQrCode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 140,
        leading: TextButton.icon(
          onPressed: _onBackButtonPressed,
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          label: const Text(
            'Go back',
            style: TextStyle(color: Colors.white, fontSize: 24),
          ),
        ),
      ),
      body: Material(
        child: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomCenter,
              colors: <Color>[
                Color(0xff0d47a1),
                Color(0xff1976d2),
                Color(0xff42a5f5),
              ],
              tileMode: TileMode.clamp,
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // -- Header --
                Expanded(
                  flex: 1,
                  child: Center(
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 60),
                          child: Text(
                            'Scan a QR code',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 42,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(40, 0, 40, 0),
                          child: Text(
                            'Scan a nearby QR code to pair with people!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 20,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // -- Camera viewer --
                Expanded(
                  flex: 2,
                  child: Center(
                    child: Container(
                      width: 280,
                      height: 280,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white, width: 2.5),
                      ),
                      clipBehavior: Clip.hardEdge,
                      child: MobileScanner(
                        controller: _cameraController,
                        onDetect: _onDetect,
                        // TODO [BACKEND]: Handle camera permission errors via ErrorDisplay(ErrorType.permission)
                        errorBuilder: (context, error) {
                          return Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white54,
                                  size: 48,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Camera unavailable',
                                  style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),

                // -- Status indicator --
                Expanded(
                  flex: 1,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 40,
                        ),
                        const SizedBox(height: 16),
                        ScanningStatusIndicator(status: _status),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onBackButtonPressed() {
    context.pop();
  }
}
