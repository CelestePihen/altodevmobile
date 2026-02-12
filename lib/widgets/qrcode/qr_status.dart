import 'package:flutter/material.dart';

class QrStatus extends StatelessWidget {
  final String status;

  const QrStatus({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        status,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}
