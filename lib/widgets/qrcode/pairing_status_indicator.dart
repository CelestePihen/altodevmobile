import 'package:flutter/material.dart';
import '../common/animated_dots.dart';

/// Possible pairing statuses when calling GET /pairing polling
/// TODO [BACKEND]: Map API response to the following enum
enum PairingStatus { waiting, connected, finishing }

/// Displays the current pairing status with animated dots for polling states
///
/// Example:
///   PairingStatusIndicator(status: PairingStatus.waiting)
class PairingStatusIndicator extends StatelessWidget {
  final PairingStatus status;

  const PairingStatusIndicator({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    // Static part of the label (dots are animated separately)
    final String label = switch (status) {
      PairingStatus.waiting   => 'Waiting for scan',
      PairingStatus.connected => 'Connection detected!',
      PairingStatus.finishing => 'Finishing',
    };

    // Whether the dots should be shown or not (only for waiting and finishing states)
    final bool showDots = switch (status) {
      PairingStatus.waiting   => true,
      PairingStatus.connected => false,
      PairingStatus.finishing => true,
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
        if (showDots)
          AnimatedDots(color: Colors.white, fontSize: 24),
        if (!showDots)
          // Keeps consistent height even without dots
          const SizedBox(height: 24),
      ],
    );
  }
}
