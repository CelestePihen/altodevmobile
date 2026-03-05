import 'package:flutter/material.dart';

/// Position of the modal on the screen
enum InfoModalPosition { top, center, bottom }

/// Displays an icon, a title, a message body, and two optional action buttons
/// By default, only an "Ok" button is shown (closes the modal)
///
/// Example:
///   showInfoDisplay(
///     context: context,
///     title: 'QR Code scanned!',
///     message: 'UUID: ...\nPublic key: ...',
///     position: InfoModalPosition.center,
///     onConfirm: () { ... },
///     onCancel: () { ... },
///   );
class InfoDisplay extends StatelessWidget {
  final String title;
  final String message;
  final InfoModalPosition position;

  // Action callbacks — null means the button is not shown
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  const InfoDisplay({
    super.key,
    required this.title,
    required this.message,
    this.position = InfoModalPosition.center,
    this.onConfirm,
    this.onCancel,
  });

  // Returns the alignment matching the desired position
  Alignment _alignmentForPosition() {
    return switch (position) {
      InfoModalPosition.top => Alignment.topCenter,
      InfoModalPosition.center => Alignment.center,
      InfoModalPosition.bottom => Alignment.bottomCenter,
    };
  }

  // Returns the padding matching the desired position
  EdgeInsets _paddingForPosition() {
    return switch (position) {
      InfoModalPosition.top => const EdgeInsets.only(
        top: 80,
        left: 24,
        right: 24,
      ),
      InfoModalPosition.center => const EdgeInsets.symmetric(horizontal: 24),
      InfoModalPosition.bottom => const EdgeInsets.only(
        bottom: 80,
        left: 24,
        right: 24,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    // Whether at least one custom action is provided
    final bool hasCustomActions = onConfirm != null || onCancel != null;

    return Material(
      color: Colors.black54, // Semi-transparent backdrop
      child: Align(
        alignment: _alignmentForPosition(),
        child: Padding(
          padding: _paddingForPosition(),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 16,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // -- Icon --
                const Icon(
                  Icons.qr_code_scanner,
                  size: 48,
                  color: Color(0xff1976d2),
                ),
                const SizedBox(height: 16),

                // -- Title --
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),

                // -- Message body --
                // TODO [BACKEND]: Replace raw string with parsed UUID + public key fields
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xfff0f4ff),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    message,
                    textAlign: TextAlign.left,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // -- Buttons --
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    // "Ok" shown only if no custom actions
                    if (!hasCustomActions)
                      _InfoButton(
                        label: 'Ok',
                        isPrimary: true,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    if (onConfirm != null)
                      _InfoButton(
                        label: 'Confirm',
                        isPrimary: true,
                        onPressed: onConfirm!,
                      ),
                    if (onCancel != null)
                      _InfoButton(
                        label: 'Cancel',
                        isPrimary: false,
                        onPressed: onCancel!,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Internal button widget for the modal — primary (filled) or secondary (outlined)
class _InfoButton extends StatelessWidget {
  final String label;
  final bool isPrimary;
  final VoidCallback onPressed;

  const _InfoButton({
    required this.label,
    required this.isPrimary,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    if (isPrimary) {
      return ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xff1976d2),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
        child: Text(label, style: const TextStyle(fontSize: 16)),
      );
    }

    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xff1976d2),
        side: const BorderSide(color: Color(0xff1976d2), width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
      child: Text(label, style: const TextStyle(fontSize: 16)),
    );
  }
}

/// Helper function to show [InfoDisplay] as an overlay on top of the current screen
///
/// Example:
///   showInfoDisplay(
///     context: context,
///     title: 'QR Code scanned!',
///     message: 'UUID: ...\nPublic key: ...',
///     position: InfoModalPosition.center,
///     onConfirm: () { ... },
///     onCancel: () { ... },
///   );
Future<void> showInfoDisplay({
  required BuildContext context,
  required String title,
  required String message,
  InfoModalPosition position = InfoModalPosition.center,
  VoidCallback? onConfirm,
  VoidCallback? onCancel,
}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.transparent, // InfoDisplay handles its own backdrop
    pageBuilder: (_, __, ___) => InfoDisplay(
      title: title,
      message: message,
      position: position,
      onConfirm: onConfirm,
      onCancel: onCancel,
    ),
  );
}
