import 'package:flutter/material.dart';

/// The four-colour Google "G", drawn rather than shipped as an asset.
///
/// Extracted from the login screen so the sign-in sheet and the login screen
/// render the identical mark — a flat blue letter "G" next to Google's name
/// looks broken, and Google's brand guidelines require the real logo.
class GoogleLogo extends StatelessWidget {
  const GoogleLogo({super.key, this.size = 20});

  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: CustomPaint(painter: _GoogleLogoPainter()),
  );
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;

    void arc(double start, double sweep, Color color) {
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r),
        start,
        sweep,
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = size.width * 0.18
          ..strokeCap = StrokeCap.butt,
      );
    }

    arc(-1.3, 1.7, const Color(0xFF4285F4)); // blue
    arc(0.4, 1.35, const Color(0xFFEA4335)); // red
    arc(1.75, 1.35, const Color(0xFFFBBC05)); // yellow
    arc(3.1, 0.85, const Color(0xFF34A853)); // green

    // Horizontal bar of the G
    canvas.drawLine(
      Offset(cx, cy),
      Offset(cx + r * 0.85, cy),
      Paint()
        ..color = const Color(0xFF4285F4)
        ..strokeWidth = size.width * 0.17
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}
