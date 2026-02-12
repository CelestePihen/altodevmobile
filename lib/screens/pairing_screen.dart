import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class InitPairingScreen extends StatefulWidget {
  const InitPairingScreen({super.key});

  @override
  State<InitPairingScreen> createState() => _InitPairingScreenState();
}

class _InitPairingScreenState extends State<InitPairingScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 140,
        leading: TextButton.icon(
          onPressed: _onBackButtonPressed,
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          label: const Text('Go back', style: TextStyle(color: Colors.black, fontSize: 24)),
        ),
      ),
      body: Material(child: Placeholder()),
    );
  }

  void _onBackButtonPressed() {
    context.pop();
  }
}
