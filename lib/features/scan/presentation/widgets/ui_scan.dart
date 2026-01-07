import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../../../../core/theme/app_colors.dart';

// --- 1. PAINTER VẼ KHUNG ĐỎ + TIA LASER ---
class ScannerOverlayPainter extends CustomPainter {
  final double scanValue; // 0.0 -> 1.0

  ScannerOverlayPainter({required this.scanValue});

  @override
  void paint(Canvas canvas, Size size) {
    final double frameWidth = (size.width * 0.9).clamp(200.0, 500.0);
    final double frameHeight = frameWidth * 0.63;
    final double frameLeft = (size.width - frameWidth) / 2;
    final double frameTop = (size.height - frameHeight) / 2 - 60;

    final Rect scanRect =
        Rect.fromLTWH(frameLeft, frameTop, frameWidth, frameHeight);
    final RRect scanRRect =
        RRect.fromRectAndRadius(scanRect, const Radius.circular(16));

    // Vẽ nền tối đục lỗ
    final Path backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final Path cutoutPath = Path()..addRRect(scanRRect);
    final Path overlayPath = Path.combine(
      ui.PathOperation.difference,
      backgroundPath,
      cutoutPath,
    );

    final Paint backgroundPaint = Paint()
      ..color = Colors.black.withOpacity(0.7)
      ..style = PaintingStyle.fill;

    canvas.drawPath(overlayPath, backgroundPaint);

    // Vẽ 4 góc đỏ
    final Paint cornerPaint = Paint()
      ..color = AppColors.red
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    const double cornerLength = 30;
    const double radius = 16;

    // Góc trên-trái
    canvas.drawPath(
      Path()
        ..moveTo(frameLeft, frameTop + cornerLength)
        ..lineTo(frameLeft, frameTop + radius)
        ..arcToPoint(Offset(frameLeft + radius, frameTop),
            radius: const Radius.circular(radius))
        ..lineTo(frameLeft + cornerLength, frameTop),
      cornerPaint,
    );
    // Góc trên-phải
    canvas.drawPath(
      Path()
        ..moveTo(frameLeft + frameWidth - cornerLength, frameTop)
        ..lineTo(frameLeft + frameWidth - radius, frameTop)
        ..arcToPoint(Offset(frameLeft + frameWidth, frameTop + radius),
            radius: const Radius.circular(radius))
        ..lineTo(frameLeft + frameWidth, frameTop + cornerLength),
      cornerPaint,
    );
    // Góc dưới-phải
    canvas.drawPath(
      Path()
        ..moveTo(frameLeft + frameWidth, frameTop + frameHeight - cornerLength)
        ..lineTo(frameLeft + frameWidth, frameTop + frameHeight - radius)
        ..arcToPoint(
            Offset(frameLeft + frameWidth - radius, frameTop + frameHeight),
            radius: const Radius.circular(radius))
        ..lineTo(frameLeft + frameWidth - cornerLength, frameTop + frameHeight),
      cornerPaint,
    );
    // Góc dưới-trái
    canvas.drawPath(
      Path()
        ..moveTo(frameLeft + cornerLength, frameTop + frameHeight)
        ..lineTo(frameLeft + radius, frameTop + frameHeight)
        ..arcToPoint(Offset(frameLeft, frameTop + frameHeight - radius),
            radius: const Radius.circular(radius))
        ..lineTo(frameLeft, frameTop + frameHeight - cornerLength),
      cornerPaint,
    );

    // Vẽ viền nét đứt
    final Paint dashPaint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final Path dashPath = Path()..addRRect(scanRRect.deflate(6));
    _drawDashedPath(canvas, dashPath, dashPaint);

    // Vẽ tia Laser
    _drawScanLine(canvas, scanRect);
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    final ui.PathMetrics pathMetrics = path.computeMetrics();
    for (ui.PathMetric metric in pathMetrics) {
      double distance = 0.0;
      while (distance < metric.length) {
        final double length = 6.0;
        final double gap = 4.0;
        canvas.drawPath(
          metric.extractPath(distance, distance + length),
          paint,
        );
        distance += (length + gap);
      }
    }
  }

  void _drawScanLine(Canvas canvas, Rect scanRect) {
    final double yPos = scanRect.top + (scanRect.height * scanValue);

    final Paint linePaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(scanRect.left, yPos),
        Offset(scanRect.right, yPos),
        [
          AppColors.red.withOpacity(0.1),
          AppColors.red,
          AppColors.red.withOpacity(0.1)
        ],
        [0.0, 0.5, 1.0],
      );

    canvas.drawRect(
      Rect.fromLTWH(scanRect.left, yPos - 1, scanRect.width, 2),
      linePaint,
    );

    final Paint glowPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(scanRect.left, yPos),
        Offset(scanRect.right, yPos),
        [
          AppColors.red.withOpacity(0.0),
          AppColors.red.withOpacity(0.4),
          AppColors.red.withOpacity(0.0)
        ],
        [0.0, 0.5, 1.0],
      );

    canvas.drawRect(
      Rect.fromLTWH(scanRect.left, yPos - 8, scanRect.width, 16),
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant ScannerOverlayPainter oldDelegate) {
    return oldDelegate.scanValue != scanValue;
  }
}

// --- 2. WIDGET NÚT VUÔNG NHỎ ---
class ScanSquareButton extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final VoidCallback onTap;

  const ScanSquareButton({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor, size: 26),
      ),
    );
  }
}

// --- 3. WIDGET NÚT CHỤP ẢNH ---
class CaptureButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isProcessing;

  const CaptureButton({
    super.key,
    required this.onTap,
    this.isProcessing = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isProcessing ? null : onTap,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: AppColors.red,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.red.withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.white, width: 4),
        ),
        child: isProcessing
            ? const Padding(
                padding: EdgeInsets.all(18),
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 3),
              )
            : const Icon(Icons.camera_alt_rounded,
                color: Colors.white, size: 32),
      ),
    );
  }
}
