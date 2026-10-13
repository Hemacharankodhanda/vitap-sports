/// VIT-AP Sports — Bracket Connector Painter.
///
/// Draws rectilinear connecting paths between knockout matches across rounds,
/// with active advancement highlighting.
library;

import 'package:flutter/material.dart';

class BracketConnector {
  const BracketConnector({
    required this.startPoint,
    required this.endPoint,
    this.isActive = false,
  });

  final Offset startPoint;
  final Offset endPoint;
  final bool isActive;
}

class BracketConnectorPainter extends CustomPainter {
  const BracketConnectorPainter({
    required this.connectors,
    required this.defaultColor,
    required this.activeColor,
    this.strokeWidth = 1.5,
  });

  final List<BracketConnector> connectors;
  final Color defaultColor;
  final Color activeColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final defaultPaint = Paint()
      ..color = defaultColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final activePaint = Paint()
      ..color = activeColor
      ..strokeWidth = strokeWidth + 0.5
      ..style = PaintingStyle.stroke;

    for (final conn in connectors) {
      final p1 = conn.startPoint;
      final p2 = conn.endPoint;
      final midX = p1.dx + (p2.dx - p1.dx) / 2;

      final path = Path()
        ..moveTo(p1.dx, p1.dy)
        ..lineTo(midX, p1.dy)
        ..lineTo(midX, p2.dy)
        ..lineTo(p2.dx, p2.dy);

      canvas.drawPath(path, conn.isActive ? activePaint : defaultPaint);
    }
  }

  @override
  bool shouldRepaint(covariant BracketConnectorPainter oldDelegate) {
    return oldDelegate.connectors != connectors ||
        oldDelegate.defaultColor != defaultColor ||
        oldDelegate.activeColor != activeColor;
  }
}
