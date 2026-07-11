import 'package:flutter/material.dart';

class GaugePainter extends CustomPainter {
  final double score; // ranges from -100 to 100 (or 0 to 100)
  final Color color;

  GaugePainter({required this.score, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Track Paint
    final trackPaint = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;
    canvas.drawCircle(center, radius - 4, trackPaint);

    // Active Arc Paint
    final activePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    // Normalize score (-100 to 100) to (0 to 100) for representation if needed
    // However, if the score is already 0 to 100 positive percentiles:
    final double normalized = score.clamp(0, 100);
    final sweepAngle = (normalized / 100.0) * 2 * 3.14159265;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 4),
      -3.14159265 / 2, // starts from top
      sweepAngle,
      false,
      activePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
