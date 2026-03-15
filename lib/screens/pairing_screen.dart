import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/qrcode/qr_code_display.dart';
import '../widgets/qrcode/pairing_status_indicator.dart';
import '../widgets/modals/error_display.dart';

// InitPairingScreen class:
// StatefulWidget means it reacts to an user's taps/inputs
class InitPairingScreen extends StatefulWidget {
  const InitPairingScreen({super.key}); // Constructor

  @override
  State<InitPairingScreen> createState() => _InitPairingScreenState();
}

// _InitPairingScreenState class:
// It holds the state of the InitPairingScreen
class _InitPairingScreenState extends State<InitPairingScreen> {
  /// Is set to Null while QR code is being generated
  /// Shows a spinner while waiting for the QR code to be generated
  /// TODO [BACKEND]: Replace Future.delayed with real UUID + RSA key generation
  /// TODO [BACKEND]: From crypto/key_generator.dart for example, generate a private RSA key and store it via flutter_secure_storage
  String? _qrData;

  /// TODO [BACKEND]: Retrieve status from GET /pairing polling (see pairing_status_indicator.dart)
  final PairingStatus _status = PairingStatus.waiting;

  /// Timer that triggers the QR code expiry modal after 2 minutes
  Timer? _expiryTimer;

  // Constructor
  @override
  void initState() {
    super.initState();
    _startPairing();
  }

  /// Generates the QR data (mock) then starts the 2-minute expiry timer
  Future<void> _startPairing() async {
    _expiryTimer?.cancel();
    setState(() => _qrData = null);

    // MOCK: Simulates a 2-second QR code generation delay
    // TODO [BACKEND]: Replace with actual key generation + UUID retrieval
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    setState(() {
      _qrData = 'mocked-uuid::mocked-rsa-public-key';
    });

    // Start the 2-minute validity timer
    // TODO [BACKEND]: Replace with an actual 2-minute timer
    _expiryTimer = Timer(const Duration(seconds: 4), _onQrCodeExpired);
  }

  /// Called when the QR code has been displayed for 2 minutes without a scan
  void _onQrCodeExpired() {
    if (!mounted) return;
    showErrorDisplay(
      context: context,
      type: ErrorType.timeout,
      message:
          'Your QR code is no longer valid for security reasons.\nPlease generate a new one.',
      position: ModalPosition.center,
      onRetry: () {
        Navigator.of(context).pop(); // Dismiss modal
        _startPairing(); // Restart: new QR code + reset timer
      },
      onGoBack: () {
        Navigator.of(context).pop(); // Dismiss modal
        context.pop(); // Go back to HomeScreen
      },
    );
  }

  // Destructor
  @override
  void dispose() {
    _expiryTimer?.cancel();
    super.dispose();
  }

  // Build method:
  // It renders the InitPairingScreen
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
                            'Your QR code',
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
                            'People must scan it to create a new connection with you!',
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
                // -- QR Code or Spinner --
                Expanded(
                  flex: 2,
                  child: Center(
                    child: _qrData == null
                        ? const CircularProgressIndicator(color: Colors.white)
                        : QrCodeDisplay(data: _qrData!),
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
                        PairingStatusIndicator(status: _status),
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
