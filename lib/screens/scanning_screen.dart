import 'dart:async';

import 'package:altodevmobile/crypto/key_storage.dart';
import 'package:altodevmobile/crypto/relationship_keys.dart';
import 'package:altodevmobile/models/qr_scan_data.dart';
import 'package:altodevmobile/services/pairing_service.dart';
import 'package:altodevmobile/widgets/modals/error_display.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:uuid/uuid.dart';
import '../crypto/relation_storage.dart';
import '../models/relation_session.dart';
import '../widgets/qrcode/scanning_status_indicator.dart';
import '../widgets/modals/info_display.dart';

// ScanPairingScreen class:
// StatefulWidget means it reacts to an user's taps/inputs
class ScanPairingScreen extends StatefulWidget {
  const ScanPairingScreen({super.key}); // Constructor

  @override
  State<ScanPairingScreen> createState() => _ScanPairingScreenState();
}

// _ScanPairingScreenState class:
// It holds the state of the ScanPairingScreen
class _ScanPairingScreenState extends State<ScanPairingScreen> {
  /// Sets up the camera controller facing back
  final MobileScannerController _cameraController = MobileScannerController(
    facing: CameraFacing.back,
  );

  ScanningStatus _status = ScanningStatus.noQrCode;

  /// Prevents the modal from being shown multiple times for the same scan
  bool _hasScanned = false;

  Timer? _statusPollingTimer;
  String? _relationCode;
  bool _isPolling = false;

  String? _pendingMyRelationCode;
  String? _pendingPeerRelationCode;
  String? _pendingMyPrivateKeyPem;
  String? _pendingPeerPublicKeyPem;

  // Destructor
  @override
  void dispose() {
    _cameraController.dispose();
    _statusPollingTimer?.cancel();
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

      _showScannedDataModal(rawValue);
    });
  }

  /// Shows a modal with the scanned data
  void _showScannedDataModal(String rawValue) {
    QrScanData? scanData;
    String? errorMessage;

    try {
      scanData = QrScanData.fromJson(rawValue);
    } catch (e) {
      errorMessage = 'Invalid QR code format. Please try again.';
    }

    if (scanData == null) {
      // parsing error
      showErrorDisplay(context: context,
        type: ErrorType.unknown,
        message: errorMessage ?? "Could not parse QR code",
        onRetry: () {
          Navigator.of(context).pop();
          _resetScan();
        },
        onGoBack: () {
          Navigator.of(context).pop();
          _onBackButtonPressed();
        },
      );
      return;
    }

    showInfoDisplay(
      context: context,
      title: 'QR Code scanned!',
      message: 'Relation ${scanData.relationCode}',
      position: InfoModalPosition.center,
      onConfirm: () {
        Navigator.of(context).pop(); // Dismisses modal
        _triggerPairingConfirmation(scanData!); // Proceeds to pairing confirmation
      },
      onCancel: () {
        Navigator.of(context).pop(); // Dismisses modal
        _resetScan(); // Allows rescanning
      },
    );
  }

  Future<void> _triggerPairingConfirmation(QrScanData scanData) async {
    bool loadingShown = false;

    void closeLoading() {
      if (!mounted || !loadingShown) return;
      Navigator.of(context).pop();
      loadingShown = false;
    }

    try {
      if (!mounted) return;

      loadingShown = true;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );

      final keyPair = generateRelationshipRsaKeyPair();

      final relationCodeB = Uuid().v4().toString();

      final response = await PairingService.instance.matchRelation(
        relationCodeA: scanData.relationCode,
        relationCodeB: relationCodeB,
        publicKeyB: keyPair.publicKeyPem,
      );

      closeLoading();
      if (!mounted) return;

      if (response.isEmpty) {
        showErrorDisplay(
          context: context,
          type: ErrorType.unknown,
          message: 'Failed to connect to the server. Please try again.',
          onRetry: () {
            Navigator.of(context).pop();
            _resetScan();
          },
          onGoBack: () {
            Navigator.of(context).pop();
            _onBackButtonPressed();
          },
        );
        return;
      }

      final returnedRelationCodeA = (response['relationCodeA'] ?? '').trim();
      final publicKeyA = (response['publicKeyA'] ?? '').trim();

      if (returnedRelationCodeA.isEmpty || publicKeyA.isEmpty) {
        showErrorDisplay(
          context: context,
          type: ErrorType.unknown,
          message: 'Server returned an invalid pairing payload.',
          onRetry: () {
            Navigator.of(context).pop();
            _resetScan();
          },
          onGoBack: () {
            Navigator.of(context).pop();
            _onBackButtonPressed();
          },
        );
        return;
      }

      if (returnedRelationCodeA != scanData.relationCode) {
        showErrorDisplay(
          context: context,
          type: ErrorType.unknown,
          message: 'Pairing mismatch detected. Please scan again.',
          onRetry: () {
            Navigator.of(context).pop();
            _resetScan();
          },
          onGoBack: () {
            Navigator.of(context).pop();
            _onBackButtonPressed();
          },
        );
        return;
      }

      _pendingMyRelationCode = relationCodeB;
      _pendingPeerRelationCode = returnedRelationCodeA;
      _pendingMyPrivateKeyPem = keyPair.privateKeyPem;
      _pendingPeerPublicKeyPem = publicKeyA;

      final storage = RelationshipKeyStorage(const FlutterSecureStorage());
      await storage.saveKeyPair(
        relationCodeB,
        publicKeyPem: keyPair.publicKeyPem,
        privateKeyPem: keyPair.privateKeyPem,
      );

      if (!mounted) return;

      _relationCode = scanData.relationCode;
      _startStatusPolling();
    } catch (e) {
      closeLoading();
      if (!mounted) return;

      showErrorDisplay(
        context: context,
        type: ErrorType.unknown,
        message: 'Pairing failed: $e\nPlease try again.',
        position: ModalPosition.center,
        onRetry: () {
          Navigator.of(context).pop();
          _triggerPairingConfirmation(scanData);
        },
        onGoBack: () {
          Navigator.of(context).pop();
          _resetScan();
        },
      );
    }
  }

  void _startStatusPolling() {
    _statusPollingTimer?.cancel();
    _pollStatus();

    _statusPollingTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _pollStatus();
    });
  }

  Future<void> _pollStatus() async {
    if (!mounted || _relationCode == null || _isPolling) return;
    _isPolling = true;

    try {
      final raw = await PairingService.instance.getStatusRelation(
        relationCode: _relationCode!,
      );
      final status = raw.trim().toLowerCase();

      if (status == 'not_found') {
        _statusPollingTimer?.cancel();
        if (!mounted) return;
        showErrorDisplay(
          context: context,
          type: ErrorType.unknown,
          message: 'Pairing not found. Please scan again.',
          onRetry: () {
            Navigator.of(context).pop();
            _resetScan();
          },
          onGoBack: () {
            Navigator.of(context).pop();
            _onBackButtonPressed();
          },
        );
        return;
      }


      if (status == 'finalized') {
        _statusPollingTimer?.cancel();

        final myCode = _pendingMyRelationCode;
        final peerCode = _pendingPeerRelationCode;
        final myPriv = _pendingMyPrivateKeyPem;
        final peerPub = _pendingPeerPublicKeyPem;

        if (myCode == null || peerCode == null || myPriv == null || peerPub == null) {
          if (!mounted) return;
          showErrorDisplay(
            context: context,
            type: ErrorType.unknown,
            message: 'Missing relation session data. Please scan again.',
            onRetry: () {
              Navigator.of(context).pop();
              _resetScan();
            },
            onGoBack: () {
              Navigator.of(context).pop();
              _onBackButtonPressed();
            },
          );
          return;
        }

        final relationStorage = RelationStorage(const FlutterSecureStorage());
        await relationStorage.saveActiveSession(
          RelationSession(
            myRelationCode: myCode,
            peerRelationCode: peerCode,
            myPrivateKeyPem: myPriv,
            peerPublicKeyPem: peerPub,
          ),
        );

        if (mounted) context.go('/relation');
      }

    } finally {
      _isPolling = false;
    }
  }

  /// Resets the scan state to allow scanning a new QR code
  void _resetScan() {
    setState(() {
      _hasScanned = false;
      _status = ScanningStatus.noQrCode;
    });
  }

  // Build method:
  // It renders the ScanPairingScreen
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        // -- Top --
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
          // -- Background --
          width: double.infinity,
          decoration: const BoxDecoration(
            // -- Background gradient --
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
