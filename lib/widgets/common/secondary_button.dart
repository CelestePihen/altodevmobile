import 'package:flutter/material.dart';
import 'button_types.dart';
export 'button_types.dart';

class SecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final ButtonSize size;
  final IconData? icon;

  const SecondaryButton({
    super.key,
    required this.text,
    this.size = ButtonSize.M,
    required this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final Map<ButtonSize, double> heights = {
      ButtonSize.S: 32.0,
      ButtonSize.M: 48.0,
      ButtonSize.L: 64.0,
    };

    final double height = heights[size]!;
    final double minWidth = height * 3;
    final double fontSize = height * 0.35;
    final double iconSize = height * 0.4;

    final ButtonStyle style = OutlinedButton.styleFrom(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      side: const BorderSide(color: Colors.black, width: 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(height * 0.2),
      ),
      padding: EdgeInsets.symmetric(horizontal: height * 0.3),
      minimumSize: Size(minWidth, height),
    );

    return OutlinedButton(
      onPressed: onPressed,
      style: style,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: iconSize),
              SizedBox(width: height * 0.15),
            ],
            Text(
              text,
              style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
