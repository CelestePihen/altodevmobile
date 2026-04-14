import 'dart:convert';

/// Model for data extracted from the scanned QR code
class QrScanData {
  final String relationCode;
  final String publicKey;

  QrScanData({
    required this.relationCode,
    required this.publicKey,
  });

  /// Parse Json string from QR code into QrScanData
  /// Launch an exception if the format is invalid
  factory QrScanData.fromJson(String jsonString) {
    try {
      final json = jsonDecode(jsonString);

      final relationCode = json['relationCode'] as String?;
      final publicKey = json['publicKey'] as String?;

      if (relationCode == null || relationCode.isEmpty) {
        throw FormatException('Missing or empty relationCode');
      }
      if (publicKey == null || publicKey.isEmpty) {
        throw FormatException('Missing or empty publicKey');
      }

      return QrScanData(
        relationCode: relationCode,
        publicKey: publicKey,
      );
    } catch (e) {
      throw FormatException('Invalid QR code format: $e');
    }
  }
}
