import 'package:flutter/material.dart';
import '../common/animated_dots.dart';

/// Possible scanning statuses — updated by MobileScanner callbacks
/// TODO [BACKEND]: After scan confirmed, map the decoded QR payload to the expected model
enum ScanningStatus { noQrCode, scanning, validQrCode }

/// Displays the current scanning status with animated dots for the scanning state
///
/// Example:
///   ScanningStatusIndicator(status: ScanningStatus.noQrCode)
class ScanningStatusIndicator extends StatelessWidget {
  final ScanningStatus status;

  const ScanningStatusIndicator({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    // Static part of the label (dots are animated separately)
    final String label = switch (status) {
      ScanningStatus.noQrCode => 'No QR code detected',
      ScanningStatus.scanning => 'Scanning',
      ScanningStatus.validQrCode => 'Valid QR code detected',
    };

    // Whether the dots should be shown or not (only for scanning state)
    final bool showDots = switch (status) {
      ScanningStatus.noQrCode => false,
      ScanningStatus.scanning => true,
      ScanningStatus.validQrCode => false,
    };

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontStyle: FontStyle.italic,
          ),
        ),
        if (showDots) AnimatedDots(color: Colors.white, fontSize: 24),
        if (!showDots) const SizedBox(height: 24),
      ],
    );
  }
}
