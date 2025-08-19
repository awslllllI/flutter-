import 'package:amap_flutter_base/amap_flutter_base.dart';
import 'dart:math' as math;

LatLng randomPointNearby(LatLng center, double radiusMeters) {
  const R = 6371000.0; // 地球半径（米）
  final rand = math.Random();

  // 随机距离（0..radius)
  final double distance = rand.nextDouble() * radiusMeters;

  // 随机方位角 0..2π
  final double bearing = rand.nextDouble() * 2 * math.pi;

  // 将经纬度从度转为弧度
  final double lat1 = center.latitude * math.pi / 180;
  final double lon1 = center.longitude * math.pi / 180;

  final double angularDistance = distance / R;

  // 公式：球面正弦/余弦推进（常用的“根据起点、方位角和距离计算终点”公式）
  final double lat2 = math.asin(
    math.sin(lat1) * math.cos(angularDistance) + math.cos(lat1) * math.sin(angularDistance) * math.cos(bearing),
  );

  final double lon2 = lon1 +
      math.atan2(
        math.sin(bearing) * math.sin(angularDistance) * math.cos(lat1),
        math.cos(angularDistance) - math.sin(lat1) * math.sin(lat2),
      );

  // 转回度
  return LatLng(lat2 * 180 / math.pi, lon2 * 180 / math.pi);
}
