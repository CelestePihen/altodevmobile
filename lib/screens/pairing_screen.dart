import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../crypto/key_storage.dart';
import '../crypto/relation_storage.dart';
import '../crypto/relationship_keys.dart';
import '../models/relation_session.dart';
import '../services/pairing_service.dart';
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
  String? _qrData;

  PairingStatus _status = PairingStatus.waiting;
  Timer? _expiryTimer;
  Timer? _statusPollingTimer;
  String? _relationCode;

  bool _isFinalizing = false;

  // Constructor
  @override
  void initState() {
    super.initState();
    _startPairing();
  }

  void _startStatusPolling() {
    _statusPollingTimer?.cancel();

    _pollPairingStatus();

    _statusPollingTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _pollPairingStatus();
    });
  }

  Future<void> _pollPairingStatus() async {
    if (!mounted || _relationCode == null) return;
    
    final rawStatus = await PairingService.instance.getStatusRelation(relationCode: _relationCode!);

    final nextStatus = _rawStatusToPairingStatus(rawStatus);
    if (nextStatus == null) return;

    if (!mounted) return;
    if (nextStatus != _status) {
      setState(() {
        _status = nextStatus;
      });
    }

    // dès qu'un scan est détecté
    if (nextStatus != PairingStatus.waiting) {
      _expiryTimer?.cancel();
    }

    if (nextStatus == PairingStatus.connected) {
      _statusPollingTimer?.cancel();
      await _finalize();
      return;
    }

    // stop polling
    if (nextStatus == PairingStatus.finishing) {
      _statusPollingTimer?.cancel();
      if (mounted) context.go('/relation');
    }
  }

  Future<void> _finalize() async {
    if (!mounted || _relationCode == null || _isFinalizing) return;
    _isFinalizing = true;

    try {
      final response = await PairingService.instance.finalizeRelation(
        relationCode: _relationCode!
      );

      if (!mounted) return;

      if (response.isEmpty) {
        _isFinalizing = false;
        _startStatusPolling();
        return;
      }

      final peerRelationCode = (response['relationCodeB'] ?? '').trim();
      final peerPublicKeyPem = (response['publicKeyB'] ?? '').trim();

      if (peerRelationCode.isEmpty || peerPublicKeyPem.isEmpty) {
        _isFinalizing = false;
        _startStatusPolling();
        return;
      }

      final keyStorage = RelationshipKeyStorage(const FlutterSecureStorage());
      final myPrivateKeyPem = await keyStorage.readPrivateKeyPem(_relationCode!);

      if (myPrivateKeyPem == null || myPrivateKeyPem.trim().isEmpty) {
        _isFinalizing = false;
        _startStatusPolling();
        return;
      }

      final relationStorage = RelationStorage(const FlutterSecureStorage());
      await relationStorage.saveActiveSession(
        RelationSession(
          myRelationCode: _relationCode!,
          peerRelationCode: peerRelationCode,
          myPrivateKeyPem: myPrivateKeyPem,
          peerPublicKeyPem: peerPublicKeyPem,
        ),
      );

      if (!mounted) return;

      setState(() {
        _status = PairingStatus.finishing;
      });

      context.go('/relation');
    } finally {
      _isFinalizing = false;
    }
  }

  PairingStatus? _rawStatusToPairingStatus(String rawStatus) {
    switch ((rawStatus).trim().toLowerCase()) {
      case 'waiting':
        return PairingStatus.waiting;
      case 'completed':
        return PairingStatus.connected;
      case 'finalized':
        return PairingStatus.finishing;
      default:
        return null;
    }
  }

  /// Generates the QR data then starts the 2-minute expiry timer
  Future<void> _startPairing() async {
    _expiryTimer?.cancel();
    _statusPollingTimer?.cancel();
    setState(() {
      _qrData = null;
      _status = PairingStatus.waiting;
    });

    final relationShipKeyPair = generateRelationshipRsaKeyPair();

    final relationCode = Uuid().v4();
    _relationCode = relationCode.toString();

    await PairingService.instance.createPairingRelation(
      relationCode: _relationCode!,
      userPublicKey: relationShipKeyPair.publicKeyPem,
    );

    final storage = RelationshipKeyStorage(const FlutterSecureStorage());
    await storage.saveKeyPair(
        relationCode.toString(), publicKeyPem: relationShipKeyPair.publicKeyPem,
        privateKeyPem: relationShipKeyPair.privateKeyPem);

    if (!mounted) return;

    setState(() {
      _qrData = jsonEncode({
        'relationCode': relationCode,
        'publicKey': relationShipKeyPair.publicKeyPem,
      });
    });

    // Start the 2-minute validity timer
    _expiryTimer = Timer(const Duration(minutes: 2), _onQrCodeExpired);
    _startStatusPolling();
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
    _statusPollingTimer?.cancel();
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
