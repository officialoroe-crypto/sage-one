import 'package:flutter/material.dart';

/// SAGE ONE's app mark: an open S-shaped orbit around a blue sphere.
/// Kept as vector artwork so it stays crisp at every screen density.
class SageBrandMark extends StatelessWidget {
  const SageBrandMark({this.size = 88, super.key});

  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
        dimension: size,
        child: CustomPaint(
          painter: _SageBrandPainter(),
        ),
      );
}

class _SageBrandPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final center = Offset(size.width * .5, size.height * .5);

    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF167BFF).withValues(alpha: .23),
          const Color(0xFF0A2B78).withValues(alpha: .08),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: s * .48));
    canvas.drawCircle(center, s * .48, glow);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-.28);
    final orbit = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * .009
      ..color = const Color(0xFF52DFFF).withValues(alpha: .66);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: s * .94, height: s * .43),
      orbit,
    );
    canvas.restore();

    final path = Path()
      ..moveTo(size.width * .76, size.height * .20)
      ..cubicTo(size.width * .62, size.height * .08, size.width * .32,
          size.height * .08, size.width * .25, size.height * .24)
      ..cubicTo(size.width * .15, size.height * .43, size.width * .36,
          size.height * .43, size.width * .56, size.height * .49)
      ..cubicTo(size.width * .79, size.height * .56, size.width * .87,
          size.height * .61, size.width * .77, size.height * .77)
      ..cubicTo(size.width * .66, size.height * .94, size.width * .36,
          size.height * .94, size.width * .22, size.height * .80);

    final shadow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * .105
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = const Color(0xFF087DFF).withValues(alpha: .30)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * .055);
    canvas.drawPath(path, shadow);

    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * .083
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFEAFBFF), Color(0xFF69DFFF), Color(0xFF4A80FF)],
      ).createShader(Offset.zero & size);
    canvas.drawPath(path, stroke);

    final sphereCenter = Offset(size.width * .50, size.height * .49);
    final sphereRadius = s * .125;
    final sphereGlow = Paint()
      ..color = const Color(0xFF1689FF).withValues(alpha: .48)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * .07);
    canvas.drawCircle(sphereCenter, sphereRadius * 1.55, sphereGlow);

    final sphere = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-.38, -.42),
        colors: const [
          Color(0xFFBDF7FF),
          Color(0xFF4CB9FF),
          Color(0xFF176CFF),
          Color(0xFF07318F),
        ],
        stops: const [0, .24, .66, 1],
      ).createShader(Rect.fromCircle(center: sphereCenter, radius: sphereRadius));
    canvas.drawCircle(sphereCenter, sphereRadius, sphere);
    canvas.drawCircle(
      sphereCenter,
      sphereRadius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * .009
        ..color = const Color(0xFFB6F5FF).withValues(alpha: .9),
    );
    canvas.drawCircle(
      sphereCenter.translate(-sphereRadius * .28, -sphereRadius * .32),
      sphereRadius * .17,
      Paint()..color = Colors.white.withValues(alpha: .8),
    );
  }

  @override
  bool shouldRepaint(covariant _SageBrandPainter oldDelegate) => false;
}
