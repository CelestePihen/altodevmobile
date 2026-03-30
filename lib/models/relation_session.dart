import 'dart:convert';

/// Stores the local relation context used by the relation screen:
/// - my relation code (used for polling/sending),
/// - peer relation code,
/// - my private key (for decryption),
/// - peer public key (for encryption).
class RelationSession {
  final String myRelationCode;
  final String peerRelationCode;
  final String myPrivateKeyPem;
  final String peerPublicKeyPem;

  const RelationSession({
    required this.myRelationCode,
    required this.peerRelationCode,
    required this.myPrivateKeyPem,
    required this.peerPublicKeyPem,
  });

  Map<String, String> toMap() {
    return <String, String>{
      'myRelationCode': myRelationCode,
      'peerRelationCode': peerRelationCode,
      'myPrivateKeyPem': myPrivateKeyPem,
      'peerPublicKeyPem': peerPublicKeyPem,
    };
  }

  factory RelationSession.fromMap(Map<String, dynamic> map) {
    final myRelationCode = (map['myRelationCode'] ?? '').toString().trim();
    final peerRelationCode = (map['peerRelationCode'] ?? '').toString().trim();
    final myPrivateKeyPem = (map['myPrivateKeyPem'] ?? '').toString().trim();
    final peerPublicKeyPem = (map['peerPublicKeyPem'] ?? '').toString().trim();

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
    );
  }

  String toJson() => jsonEncode(toMap());

  factory RelationSession.fromJson(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('RelationSession JSON is not an object');
    }
    return RelationSession.fromMap(decoded);
  }
}