import 'package:flutter/material.dart';
import '../models/batch.dart';
import '../core/theme/app_theme.dart';

/// Renders the price journey (fair-price band + bid history) as a simple
/// line chart with dots for each price point. Used on both buyer batch
/// detail and seller dashboard/batch screens — keep it dependency-light
/// (custom paint, no chart package) so it renders identically everywhere.
class PriceGraph extends StatelessWidget {
  final List<PricePoint> points;
  final double fairMin;
  final double fairMax;
  final double height;

  const PriceGraph({
    super.key,
    required this.points,
    required this.fairMin,
    required this.fairMax,
    this.height = 160,
  });

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return SizedBox(
        height: height,
        child: const Center(
          child: Text('No price history yet', style: TextStyle(color: AppColors.textMuted)),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: height,
          width: double.infinity,
          child: CustomPaint(
            painter: _PriceGraphPainter(
              points: points,
              fairMin: fairMin,
              fairMax: fairMax,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _legendDot(AppColors.accent.withValues(alpha: 0.25), 'Fair price band'),
            const SizedBox(width: 16),
            _legendDot(AppColors.primary, 'Price journey'),
          ],
        ),
      ],
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
      ],
    );
  }
}

class _PriceGraphPainter extends CustomPainter {
  final List<PricePoint> points;
  final double fairMin;
  final double fairMax;

  _PriceGraphPainter({required this.points, required this.fairMin, required this.fairMax});

  @override
  void paint(Canvas canvas, Size size) {
    final prices = points.map((p) => p.price).toList()
      ..add(fairMin)
      ..add(fairMax);
    final minY = prices.reduce((a, b) => a < b ? a : b) * 0.95;
    final maxY = prices.reduce((a, b) => a > b ? a : b) * 1.05;
    final range = (maxY - minY).clamp(1, double.infinity);

    double yFor(double price) => size.height - ((price - minY) / range) * size.height;
    double xFor(int i) => points.length == 1 ? size.width / 2 : (i / (points.length - 1)) * size.width;

    // fair price band
    final bandPaint = Paint()..color = AppColors.accent.withValues(alpha: 0.15);
    final bandTop = yFor(fairMax);
    final bandBottom = yFor(fairMin);
    canvas.drawRect(Rect.fromLTRB(0, bandTop, size.width, bandBottom), bandPaint);

    // line
    final linePaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final path = Path();
    for (int i = 0; i < points.length; i++) {
      final pt = Offset(xFor(i), yFor(points[i].price));
      if (i == 0) {
        path.moveTo(pt.dx, pt.dy);
      } else {
        path.lineTo(pt.dx, pt.dy);
      }
    }
    canvas.drawPath(path, linePaint);

    // dots
    final dotPaint = Paint()..color = AppColors.primaryDark;
    for (int i = 0; i < points.length; i++) {
      canvas.drawCircle(Offset(xFor(i), yFor(points[i].price)), 4, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _PriceGraphPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.fairMin != fairMin ||
        oldDelegate.fairMax != fairMax;
  }
}
