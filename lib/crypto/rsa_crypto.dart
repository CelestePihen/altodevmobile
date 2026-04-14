import 'dart:convert';
import 'dart:typed_data';

import 'package:basic_utils/basic_utils.dart';
import 'package:pointycastle/api.dart' as pc;
import 'package:pointycastle/asymmetric/oaep.dart';
import 'package:pointycastle/asymmetric/rsa.dart';

String rsaEncryptToBase64({
  required String recipientPublicKeyPem,
  required String plaintext,
}) {
  final RSAPublicKey publicKey = CryptoUtils.rsaPublicKeyFromPem(recipientPublicKeyPem);

  final engine = OAEPEncoding(RSAEngine())
    ..init(true, pc.PublicKeyParameter<RSAPublicKey>(publicKey));

  final ciphertextBytes = engine.process(Uint8List.fromList(utf8.encode(plaintext)));
  return base64Encode(ciphertextBytes);
}

String rsaDecryptFromBase64({
  required String myPrivateKeyPem,
  required String ciphertextB64,
}) {
  final RSAPrivateKey privateKey = CryptoUtils.rsaPrivateKeyFromPem(myPrivateKeyPem);

  final engine = OAEPEncoding(RSAEngine())
    ..init(false, pc.PrivateKeyParameter<RSAPrivateKey>(privateKey));

  final clearBytes = engine.process(base64Decode(ciphertextB64));
  return utf8.decode(clearBytes);
}