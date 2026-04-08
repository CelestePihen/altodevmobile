import 'dart:convert';

/// Stores the local relation context used by the relation screen:
/// - my relation code (used for polling/sending),
/// - peer relation code,
/// - my private key (for decryption),
/// - peer public key (for encryption).
///
/// Serialization contract:
/// - required keys: `myRelationCode`, `peerRelationCode`,
///   `myPrivateKeyPem`, `peerPublicKeyPem`
/// - nullable key: `uiColorHex`
///
/// Deserialization behavior:
/// - values are trimmed to avoid accidental whitespace mismatches
/// - empty optional color becomes `null`
/// - missing/empty required values throw a `FormatException`
class RelationSession {
  final String myRelationCode;
  final String peerRelationCode;
  final String myPrivateKeyPem;
  final String peerPublicKeyPem;
  final String? uiColorHex;

  const RelationSession({
    required this.myRelationCode,
    required this.peerRelationCode,
    required this.myPrivateKeyPem,
    required this.peerPublicKeyPem,
    this.uiColorHex,
  });

  /// Serializes the session to a map using the current app schema.
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'myRelationCode': myRelationCode,
      'peerRelationCode': peerRelationCode,
      'myPrivateKeyPem': myPrivateKeyPem,
      'peerPublicKeyPem': peerPublicKeyPem,
      'uiColorHex': uiColorHex,
    };
  }

  /// Rebuilds a session from a map loaded from storage.
  ///
  /// Throws [FormatException] when required fields are missing or empty.
  factory RelationSession.fromMap(Map<String, dynamic> map) {
    final myRelationCode = (map['myRelationCode'] ?? '').toString().trim();
    final peerRelationCode = (map['peerRelationCode'] ?? '').toString().trim();
    final myPrivateKeyPem = (map['myPrivateKeyPem'] ?? '').toString().trim();
    final peerPublicKeyPem = (map['peerPublicKeyPem'] ?? '').toString().trim();
    final rawUiColorHex = (map['uiColorHex'] ?? '').toString().trim();
    final uiColorHex = rawUiColorHex.isEmpty ? null : rawUiColorHex;

    if (myRelationCode.isEmpty ||
        peerRelationCode.isEmpty ||
        myPrivateKeyPem.isEmpty ||
        peerPublicKeyPem.isEmpty) {
      throw const FormatException('Invalid RelationSession payload');
    }

    return RelationSession(
      myRelationCode: myRelationCode,
      peerRelationCode: peerRelationCode,
      myPrivateKeyPem: myPrivateKeyPem,
      peerPublicKeyPem: peerPublicKeyPem,
      uiColorHex: uiColorHex,
    );
  }

  RelationSession copyWith({
    String? myRelationCode,
    String? peerRelationCode,
    String? myPrivateKeyPem,
    String? peerPublicKeyPem,
    String? uiColorHex,
  }) {
    return RelationSession(
      myRelationCode: myRelationCode ?? this.myRelationCode,
      peerRelationCode: peerRelationCode ?? this.peerRelationCode,
      myPrivateKeyPem: myPrivateKeyPem ?? this.myPrivateKeyPem,
      peerPublicKeyPem: peerPublicKeyPem ?? this.peerPublicKeyPem,
      uiColorHex: uiColorHex ?? this.uiColorHex,
    );
  }

  /// Serializes this session as JSON using [toMap].
  String toJson() => jsonEncode(toMap());

  /// Deserializes a JSON payload and delegates validation to [fromMap].
  factory RelationSession.fromJson(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('RelationSession JSON is not an object');
    }
    return RelationSession.fromMap(decoded);
  }
}