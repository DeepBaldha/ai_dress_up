import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CircularProgressImage extends StatelessWidget {
  final double progress; // 0–100
  final String imagePath;
  final bool isProcessing;
  final VoidCallback onSeeResult;

  const CircularProgressImage({
    super.key,
    required this.progress,
    required this.imagePath,
    required this.isProcessing,
    required this.onSeeResult,
  });

  @override
  Widget build(BuildContext context) {
    final double percent = (progress.clamp(0, 100)) / 100;

    if (!isProcessing) {
      return GestureDetector(
        onTap: onSeeResult,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            "See Result",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    // ------------------------
    // SHOW PROGRESS RING
    // ------------------------
    return SizedBox(
      width: 200.w,
      height: 200.w,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(200.w, 200.w),
            painter: RingPainter(
              progress: percent,
              fillColor: Colors.white,
              backgroundColor: Colors.white.withOpacity(0.2),
            ),
          ),

          // The image inside
          ClipOval(
            child: Image.asset(
              imagePath,
              width: 160.w,
              height: 160.w,
              fit: BoxFit.cover,
            ),
          ),

          // Percentage text
          Text(
            "${(percent * 100).toInt()}%",
            style: TextStyle(
              color: Colors.white,
              fontSize: 45.sp,
              fontWeight: FontWeight.bold,
            ),
          )
        ],
      ),
    );
  }
}


class RingPainter extends CustomPainter {
  final double progress;
  final Color fillColor;
  final Color backgroundColor;

  RingPainter({
    required this.progress,
    required this.fillColor,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = 12.0;
    final radius = size.width / 2;

    // Background arc
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Filled arc
    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCircle(center: center, radius: radius - strokeWidth);

    canvas.drawArc(rect, -90 * 3.1416 / 180, 360 * 3.1416 / 180, false, bgPaint);
    canvas.drawArc(rect, -90 * 3.1416 / 180, 360 * progress * 3.1416 / 180, false, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

