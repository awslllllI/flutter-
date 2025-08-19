import 'dart:math';
import 'package:amap_flutter_base/amap_flutter_base.dart';


/// 地球半径（Web Mercator 投影用）
const double earthRadius = 6378137.0;

/// 经纬度 -> Web Mercator (米)
Point mercatorProjection(LatLng latlng) {
  final x = earthRadius * latlng.longitude * pi / 180;
  final y = earthRadius *
      log(tan(pi / 4 + (latlng.latitude * pi / 180) / 2));
  return Point(x, y);
}

/// Web Mercator -> 经纬度
LatLng inverseMercator(Point p) {
  final lon = p.x / earthRadius * 180 / pi;
  final lat =
      (2 * atan(exp(p.y / earthRadius)) - pi / 2) * 180 / pi;
  return LatLng(lat, lon);
}

/// 通过六边形边长（米）和中心点经纬度，计算六边形六个顶点
List<LatLng> hexagonFromCenter(LatLng center, double hexSizeMeters) {
  final centerXY = mercatorProjection(center);
  final List<LatLng> vertices = [];

  for (int i = 0; i < 6; i++) {
    final angle = pi / 6 + i * pi / 3; // 30° 起始，间隔 60°
    final dx = hexSizeMeters * cos(angle);
    final dy = hexSizeMeters * sin(angle);
    final vertexXY = Point(centerXY.x + dx, centerXY.y + dy);
    vertices.add(inverseMercator(vertexXY));
  }

  return vertices;
}

/// 根据一个点，找到其所在的六边形中心（网格对齐）
LatLng hexCenterFromPoint(LatLng point, double hexSizeMeters) {
  final p = mercatorProjection(point);

  // 六边形网格的宽高
  final w = sqrt(3) * hexSizeMeters;
  final h = 2 * hexSizeMeters;

  // 对齐到六边形网格
  final q = (p.x * 2/3) / hexSizeMeters;
  final r = (-p.x / 3 + sqrt(3)/3 * p.y) / hexSizeMeters;

  // 取最近的整数格子
  int rq = q.round();
  int rr = r.round();
  int rs = (-q-r).round();

  // 修正误差
  final dq = (rq - q).abs();
  final dr = (rr - r).abs();
  final ds = (rs - (-q-r)).abs();

  if (dq > dr && dq > ds) {
    rq = -rr - rs;
  } else if (dr > ds) {
    rr = -rq - rs;
  }

  // 转回平面坐标
  final x = hexSizeMeters * (3/2 * rq);
  final y = hexSizeMeters * (sqrt(3)/2 * rq + sqrt(3) * rr);

  return inverseMercator(Point(x, y));
}
