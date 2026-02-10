# Alto - Secure Pairing App

A mobile app that allows two users to establish a secure connection via a QR Code pairing system.

![https://github.com/CelestePihen/altodevmobile](https://img.shields.io/badge/github-Alto-blue?logo=github) ![](https://img.shields.io/badge/Flutter-blue?logo=flutter) ![](https://img.shields.io/badge/Dart-blue?logo=flutter) ![](https://img.shields.io/badge/Springboot-white?logo=spring)

## Description

...

## Structure

Here's the project structure:

```
repo/
├── README.md
├── CONTRIBUTING.md
├── lib/
│   ├── main.dart
│   ├── screens/
│   │   ├── home_screen.dart
│   │   ├── init_pairing_screen.dart
│   │   ├── scan_pairing_screen.dart
│   │   └── relation_screen.dart
│   ├── services/
│   │   ├── pairing_service.dart
│   │   ├── element_service.dart
│   │   └── api_client.dart
│   ├── widgets/
│   │   ├── common/
│   │   └── relation/
│   ├── crypto/
│   │   ├── key_generator.dart
│   │   ├── rsa_crypto.dart
│   │   └── key_storage.dart
│   └── models/
│       ├── pairing.dart
│       └── element.dart
└── pubspec.yaml
```

## Dependencies

List of dependencies used for this application:

* `qr_flutter`: QR code generator
* `mobile_scanner`: QR code scanner
* `pointycastle`: Cryptography library for RSA
* `basic_utils`: PEM keys manipulator
* `flutter_secure_storage`: Secure storage for private keys
* `dio`: HTTP client for API calls

## Features

List of implemented features below:

...

## Upgrades

List of possible upgrades to implement:

...

## Authors

* [@ThFoxY](https://github.com/ThFoxY): ![](https://img.shields.io/badge/Frontend-yellow) ![](https://img.shields.io/badge/Unit_tests-gray) ![](https://img.shields.io/badge/Docs-blue) ![](https://img.shields.io/badge/Reviewer-magenta)

* [@CelestePihen](https://github.com/CelestePihen) ![](https://img.shields.io/badge/Backend-yellow) ![](https://img.shields.io/badge/API-gray) ![](https://img.shields.io/badge/Reviewer-magenta)

## Contributing

To contribute, please read the following docs: [Contributing here](CONTRIBUTING.md)