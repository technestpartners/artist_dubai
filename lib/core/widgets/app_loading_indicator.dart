import 'package:flutter/material.dart';

/// Standardized loading indicator matching the platform luxury theme.
class AppLoadingIndicator extends StatelessWidget {
  final Color color;
  final double size;
  final double strokeWidth;

  const AppLoadingIndicator({
    super.key,
    this.color = Colors.white,
    this.size = 32.0,
    this.strokeWidth = 2.5,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          strokeWidth: strokeWidth,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ),
    );
  }
}
