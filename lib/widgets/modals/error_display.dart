import 'package:flutter/material.dart';

/// Position of the modal on the screen
enum ModalPosition { top, center, bottom }

/// Type of error - determines the icon displayed above the message
enum ErrorType { timeout, network, unknown, permission }

/// Displays an icon, a message, and up to 4 optional action buttons
/// By default, only an "Ok" button is shown (closes the modal)
///
/// Example:
///   showErrorDisplay(
///     context: context,
///     type: ErrorType.timeout,
///     message: 'Your QR code has expired for security reasons.',
///     position: ModalPosition.center,
///     onRetry: () { ... },
///     onGoBack: () { ... },
///   );
class ErrorDisplay extends StatelessWidget {
  final ErrorType type;
  final String message;
  final ModalPosition position;

  // Action callbacks — null means the button is not shown
  final VoidCallback? onOk;
  final VoidCallback? onRetry;
  final VoidCallback? onGoBack;
  final VoidCallback? onCancel;

  const ErrorDisplay({
    super.key,
    required this.type,
    required this.message,
    this.position = ModalPosition.center,
    this.onOk,
    this.onRetry,
    this.onGoBack,
    this.onCancel,
  });

  // Returns the icon associated to the error type
  IconData _iconForType() {
    return switch (type) {
      ErrorType.timeout => Icons.access_time,
      ErrorType.network => Icons.wifi_off,
      ErrorType.unknown => Icons.error_outline,
      ErrorType.permission => Icons.lock_outline,
    };
  }

  // Returns the alignment matching the desired position
  Alignment _alignmentForPosition() {
    return switch (position) {
      ModalPosition.top => Alignment.topCenter,
      ModalPosition.center => Alignment.center,
      ModalPosition.bottom => Alignment.bottomCenter,
    };
  }

  // Returns the padding matching the desired position
  EdgeInsets _paddingForPosition() {
    return switch (position) {
      ModalPosition.top => const EdgeInsets.only(top: 80, left: 24, right: 24),
      ModalPosition.center => const EdgeInsets.symmetric(horizontal: 24),
      ModalPosition.bottom => const EdgeInsets.only(
        bottom: 80,
        left: 24,
        right: 24,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    // Whether at least one custom action is provided
    final bool hasCustomActions =
        onRetry != null || onGoBack != null || onCancel != null;

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
                Icon(_iconForType(), size: 48, color: const Color(0xff1976d2)),
                const SizedBox(height: 16),

                // -- Message --
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 24),

                // -- Buttons --
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    // "Ok" shown only if no custom actions OR explicitly provided
                    if (!hasCustomActions || onOk != null)
                      _ModalButton(
                        label: 'Ok',
                        isPrimary: true,
                        onPressed: onOk ?? () => Navigator.of(context).pop(),
                      ),
                    if (onRetry != null)
                      _ModalButton(
                        label: 'Retry',
                        isPrimary: true,
                        onPressed: onRetry!,
                      ),
                    if (onGoBack != null)
                      _ModalButton(
                        label: 'Go back',
                        isPrimary: false,
                        onPressed: onGoBack!,
                      ),
                    if (onCancel != null)
                      _ModalButton(
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
class _ModalButton extends StatelessWidget {
  final String label;
  final bool isPrimary;
  final VoidCallback onPressed;

  const _ModalButton({
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

/// Helper function to show [ErrorDisplay] as an overlay on top of the current screen
///
/// Example:
///   showErrorDisplay(
///     context: context,
///     type: ErrorType.timeout,
///     message: 'Your QR code has expired for security reasons.',
///     position: ModalPosition.center,
///     onRetry: _restartPairing,
///     onGoBack: () => context.pop(),
///   );
Future<void> showErrorDisplay({
  required BuildContext context,
  required ErrorType type,
  required String message,
  ModalPosition position = ModalPosition.center,
  VoidCallback? onOk,
  VoidCallback? onRetry,
  VoidCallback? onGoBack,
  VoidCallback? onCancel,
}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.transparent, // ErrorDisplay handles its own backdrop
    pageBuilder: (_, _, _) => ErrorDisplay(
      type: type,
      message: message,
      position: position,
      onOk: onOk,
      onRetry: onRetry,
      onGoBack: onGoBack,
      onCancel: onCancel,
    ),
  );
}
