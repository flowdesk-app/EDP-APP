import 'package:flutter/material.dart';

class FlowdeskLogo extends StatelessWidget {
  final double fontSize;
  final Color flowColor;
  final Color deskColor;

  const FlowdeskLogo({
    super.key,
    this.fontSize = 28,
    this.flowColor = const Color(0xFF42A5F5), // Or 0xFF29B6F6
    this.deskColor = const Color(0xFF000000), // Or 0xFF202124
  });

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
          fontFamily: 'Roboto',
        ),
        children: [
          TextSpan(
            text: 'Flow',
            style: TextStyle(color: const Color(0xFF29B6F6)),
          ),
          TextSpan(
            text: 'desk',
            style: TextStyle(color: const Color(0xFF202124)),
          ),
        ],
      ),
    );
  }
}
