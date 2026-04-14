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
  final String? myNickname;
  final String? peerNickname;

  const RelationSession({
    required this.myRelationCode,
    required this.peerRelationCode,
    required this.myPrivateKeyPem,
    required this.peerPublicKeyPem,
    this.uiColorHex,
    this.myNickname,
    this.peerNickname,
  });

  /// Serializes the session to a map using the current app schema.
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'myRelationCode': myRelationCode,
      'peerRelationCode': peerRelationCode,
      'myPrivateKeyPem': myPrivateKeyPem,
      'peerPublicKeyPem': peerPublicKeyPem,
      'uiColorHex': uiColorHex,
      'myNickname': myNickname,
      'peerNickname': peerNickname,
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
    final rawMyNickname = (map['myNickname'] ?? '').toString().trim();
    final myNickname = rawMyNickname.isEmpty ? null : rawMyNickname;
    final rawPeerNickname = (map['peerNickname'] ?? '').toString().trim();
    final peerNickname = rawPeerNickname.isEmpty ? null : rawPeerNickname;

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
      myNickname: myNickname,
      peerNickname: peerNickname,
    );
  }

  RelationSession copyWith({
    String? myRelationCode,
    String? peerRelationCode,
    String? myPrivateKeyPem,
    String? peerPublicKeyPem,
    String? uiColorHex,
    String? myNickname,
    String? peerNickname,
  }) {
    return RelationSession(
      myRelationCode: myRelationCode ?? this.myRelationCode,
      peerRelationCode: peerRelationCode ?? this.peerRelationCode,
      myPrivateKeyPem: myPrivateKeyPem ?? this.myPrivateKeyPem,
      peerPublicKeyPem: peerPublicKeyPem ?? this.peerPublicKeyPem,
      uiColorHex: uiColorHex ?? this.uiColorHex,
      myNickname: myNickname ?? this.myNickname,
      peerNickname: peerNickname ?? this.peerNickname,
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