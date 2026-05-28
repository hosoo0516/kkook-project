import 'package:flutter/material.dart';

import '../theme/kkook_theme.dart';

class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
  });

  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF1F2937),
          side: const BorderSide(color: KkookColors.border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _GoogleLogo(),
                  const SizedBox(width: 10),
                  const Text(
                    'Google',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
      ),
    );
  }
}

class _GoogleLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final center = Offset(w / 2, h / 2);
    final radius = w / 2;

    final paint = Paint()..style = PaintingStyle.stroke..strokeWidth = 2.2;

    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -0.4,
      1.2,
      false,
      paint,
    );
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0.9,
      1.1,
      false,
      paint,
    );
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      2.1,
      1.0,
      false,
      paint,
    );
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      3.3,
      1.0,
      false,
      paint,
    );

    paint.style = PaintingStyle.fill;
    paint.color = const Color(0xFF4285F4);
    canvas.drawRect(Rect.fromLTWH(w / 2, h / 2 - 1, w / 2, 2), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
