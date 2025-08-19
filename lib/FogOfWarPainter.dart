import 'package:amap_flutter_base/amap_flutter_base.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

class FogOfWarPainter extends CustomPainter {
  final List<LatLng> tracePoints;
  final LatLng centerLatLng;
  final double zoom;
  final Size screenSize;
  final double hexRadius; // 六边形基准半径
  final double opacity; // 迷雾透明度
  // 六边形网格锚点
  static LatLng? _originLatLng;

  FogOfWarPainter({
    required this.tracePoints,
    required this.centerLatLng,
    required this.zoom,
    required this.screenSize,
    this.hexRadius = 25,
    this.opacity = 0.9,
  }) {
    _originLatLng ??= centerLatLng;
  }

  // 经纬度 -> 世界坐标 (tile 像素坐标)
  Offset _latLngToWorld(LatLng latLng) {
    double scale = (256 << zoom.toInt()).toDouble();
    double worldX = (latLng.longitude + 180) / 360 * scale;
    double sinLat = math.sin(latLng.latitude * math.pi / 180);
    double worldY = (0.5 - math.log((1 + sinLat) / (1 - sinLat)) / (4 * math.pi)) * scale;
    return Offset(worldX, worldY);
  }

  // 世界坐标 -> 屏幕坐标
  Offset _worldToScreen(Offset world) {
    final centerWorld = _latLngToWorld(centerLatLng);
    final screenCenter = Offset(screenSize.width / 2, screenSize.height / 2);
    return world - centerWorld + screenCenter;
  }

  // 屏幕坐标 -> 世界坐标
  Offset _screenToWorld(Offset screen) {
    final centerWorld = _latLngToWorld(centerLatLng);
    final screenCenter = Offset(screenSize.width / 2, screenSize.height / 2);
    return screen + centerWorld - screenCenter;
  }

  // 经纬度 -> 屏幕坐标
  Offset _latLngToScreen(LatLng latLng) {
    return _worldToScreen(_latLngToWorld(latLng));
  }

  // 生成六边形顶点
  List<Offset> _hexagonPoints(Offset center, double r) {
    return List.generate(6, (i) {
      double angleRad = math.pi / 180 * (60 * i);
      return Offset(center.dx + r * math.cos(angleRad), center.dy + r * math.sin(angleRad));
    });
  }

  // 判断折线段是否与多边形相交
  bool _lineIntersectsPolygon(Offset p1, Offset p2, List<Offset> polygon) {
    for (int i = 0; i < polygon.length; i++) {
      Offset a = polygon[i];
      Offset b = polygon[(i + 1) % polygon.length];
      if (_lineSegmentsIntersect(p1, p2, a, b)) return true;
    }
    return false;
  }

  // 两线段相交检测
  bool _lineSegmentsIntersect(Offset p1, Offset p2, Offset q1, Offset q2) {
    double cross(Offset o, Offset a, Offset b) => (a.dx - o.dx) * (b.dy - o.dy) - (a.dy - o.dy) * (b.dx - o.dx);
    if ((cross(p1, p2, q1) * cross(p1, p2, q2) <= 0) && (cross(q1, q2, p1) * cross(q1, q2, p2) <= 0)) {
      return true;
    }
    return false;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final fogPaint = Paint()
      ..color = Colors.black.withOpacity(opacity)
      ..style = PaintingStyle.fill;

    final hexBaseRadius = hexRadius;
    final currentHexRadius = hexBaseRadius * math.pow(2, zoom - 14);
    final hexHeight = math.sqrt(3) * currentHexRadius;

    final originWorld = _latLngToWorld(_originLatLng!);
    final tracePointsScreen = tracePoints.map(_latLngToScreen).toList();

    // 计算屏幕对应的世界坐标范围（加缓冲区）
    final topLeftWorld = _screenToWorld(const Offset(0, 0));
    final bottomRightWorld = _screenToWorld(Offset(size.width, size.height));
    final xMin = topLeftWorld.dx - 1.5 * currentHexRadius;
    final xMax = bottomRightWorld.dx + 1.5 * currentHexRadius;
    final yMin = topLeftWorld.dy - hexHeight;
    final yMax = bottomRightWorld.dy + hexHeight;

    // 遍历屏幕可见区域六边形
    for (int col = -1000; col < 1000; col++) {
      double worldX = originWorld.dx + col * 1.5 * currentHexRadius;
      if (worldX < xMin) continue;
      if (worldX > xMax) break;

      for (int row = -1000; row < 1000; row++) {
        double worldY = originWorld.dy + row * hexHeight + (col % 2) * (hexHeight / 2);
        if (worldY < yMin) continue;
        if (worldY > yMax) break;

        Offset screenCenter = _worldToScreen(Offset(worldX, worldY));
        List<Offset> hexPoints = _hexagonPoints(screenCenter, currentHexRadius);
        Path hexPath = Path()..addPolygon(hexPoints, true);

        bool shouldDraw = true;

        // 轨迹点擦除
        if (tracePointsScreen.any((p) => hexPath.contains(p))) shouldDraw = false;

        // 轨迹折线擦除
        for (int i = 1; i < tracePointsScreen.length; i++) {
          if (_lineIntersectsPolygon(tracePointsScreen[i - 1], tracePointsScreen[i], hexPoints)) {
            shouldDraw = false;
            break;
          }
        }

        if (shouldDraw) canvas.drawPath(hexPath, fogPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant FogOfWarPainter oldDelegate) {
    return oldDelegate.tracePoints.length != tracePoints.length ||
        oldDelegate.centerLatLng != centerLatLng ||
        oldDelegate.zoom != zoom;
  }
}
