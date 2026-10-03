import 'package:flutter/material.dart';

class FlowdeskLogo extends StatelessWidget {
  final double fontSize;
  final Color flowColor;
  final Color deskColor;

  const FlowdeskLogo({
    super.key,
    this.fontSize = 28,
    this.flowColor = const Color(0xFF42A5F5),
    this.deskColor = const Color(0xFF000000),
  });

  @override
  Widget build(BuildContext context) {
    // We use fontSize as a proxy for the height we want the logo to be
    double imageHeight = fontSize * 1.5;
    if (imageHeight < 30) imageHeight = 30; // Min height to be readable

    return Image.asset(
      'assets/images/edp_logo.png',
      height: imageHeight,
      fit: BoxFit.contain,
    );
  }
}
