import 'dart:math';
import 'dart:typed_data';

import 'package:basic_utils/basic_utils.dart';
import 'package:pointycastle/api.dart' as pc;
import 'package:pointycastle/key_generators/api.dart' as pc;
import 'package:pointycastle/key_generators/rsa_key_generator.dart';
import 'package:pointycastle/random/fortuna_random.dart';

FortunaRandom _secureRandom() {
  final random = FortunaRandom();
  final seed = Uint8List(32);
  final r = Random.secure();
  for (var i = 0; i < seed.length; i++) {
    seed[i] = r.nextInt(256);
  }
  random.seed(pc.KeyParameter(seed));
  return random;
}

/// Génère une paire RSA (pédago) et renvoie les clés en PEM.
/// À appeler *une fois par relation*.
({String publicKeyPem, String privateKeyPem}) generateRelationshipRsaKeyPair({
  int bitLength = 2048,
}) {
  final generator = RSAKeyGenerator()
    ..init(
      pc.ParametersWithRandom(
        pc.RSAKeyGeneratorParameters(BigInt.parse('65537'), bitLength, 64),
        _secureRandom(),
      ),
    );
  final pair = generator.generateKeyPair();
  final publicKey = pair.publicKey;
  final privateKey = pair.privateKey;

  return (
    publicKeyPem: CryptoUtils.encodeRSAPublicKeyToPem(publicKey),
    privateKeyPem: CryptoUtils.encodeRSAPrivateKeyToPem(privateKey),
  );
}
