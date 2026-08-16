import 'package:flutter/material.dart';

class BenchTrackLogo extends StatelessWidget {
  const BenchTrackLogo({
    super.key,
    this.width = 52,
    this.height,
    this.showText = false,
  });

  final double width;
  final double? height;
  final bool showText;

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      'assets/branding/benchtrack_logo.png',
      width: width,
      height: height ?? width,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => Container(
        width: width,
        height: height ?? width,
        decoration: BoxDecoration(
          color: const Color(0xFFE60012),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.memory_rounded, color: Colors.white),
      ),
    );

    if (!showText) return image;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        image,
        const SizedBox(width: 10),
        const Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'Bench',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              TextSpan(
                text: 'Track',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFE60012),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
