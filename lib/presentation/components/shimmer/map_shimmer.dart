import 'package:flutter/material.dart';
import 'package:ovorideuser/core/utils/my_color.dart';
import 'package:ovorideuser/presentation/components/shimmer/my_shimmer.dart';

class MapShimmer extends StatelessWidget {
  const MapShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background map shimmer
        Positioned.fill(
          child: MyShimmerWidget(
            child: Container(
              color: MyColor.colorWhite,
            ),
          ),
        ),
        // Faint road-like lines
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: RoadPainter(),
            ),
          ),
        ),
        // Loading Indicator in center (optional, but requested earlier)
        const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: MyColor.primaryColor,
          ),
        ),
      ],
    );
  }
}

class RoadPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = MyColor.colorGrey.withValues(alpha: 0.2)
      ..strokeWidth = 20
      ..style = PaintingStyle.stroke;

    final path = Path();
    // Some random road-like lines
    path.moveTo(0, size.height * 0.3);
    path.lineTo(size.width, size.height * 0.4);

    path.moveTo(size.width * 0.4, 0);
    path.lineTo(size.width * 0.5, size.height);

    path.moveTo(0, size.height * 0.7);
    path.lineTo(size.width, size.height * 0.6);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
