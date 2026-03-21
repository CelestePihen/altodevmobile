import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class RelationshipKeyStorage {
  final FlutterSecureStorage _storage;

  RelationshipKeyStorage(this._storage);

  String _pubKey(String relationId) => 'rel:$relationId:pubPem';
  String _privKey(String relationId) => 'rel:$relationId:privPem';

  Future<void> saveKeyPair(
      String relationId, {
        required String publicKeyPem,
        required String privateKeyPem,
      }) async {
    await _storage.write(key: _pubKey(relationId), value: publicKeyPem);
    await _storage.write(key: _privKey(relationId), value: privateKeyPem);
  }

  Future<String?> readPublicKeyPem(String relationId) =>
      _storage.read(key: _pubKey(relationId));

  Future<String?> readPrivateKeyPem(String relationId) =>
      _storage.read(key: _privKey(relationId));
}