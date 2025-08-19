import 'dart:math';
import 'package:amap_flutter_base/amap_flutter_base.dart';
import 'package:amap_flutter_map/amap_flutter_map.dart';
import 'package:flutter/material.dart';

class HexGridOverlay {
  /// 根据屏幕范围生成六边形网格
  static Set<Polygon> generateHexGrid(LatLngBounds bounds, double radiusMeters) {
    final Set<Polygon> polygons = {};

    // 经纬度换算：1度纬度 ≈ 111000米
    double latStep = (radiusMeters * sqrt(3)) / 111000.0;
    double lngStep = (radiusMeters * 3 / 2) /
        (111000.0 * cos(bounds.southwest.latitude * pi / 180));

    for (double lat = bounds.southwest.latitude - latStep;
        lat < bounds.northeast.latitude + latStep;
        lat += latStep) {
      for (double lng = bounds.southwest.longitude - lngStep;
          lng < bounds.northeast.longitude + lngStep;
          lng += lngStep) {
        LatLng center = LatLng(lat, lng);

        // 六边形顶点
        List<LatLng> hex = _createHexagon(center, radiusMeters);

        polygons.add(Polygon(
          points: hex,
          strokeColor: Colors.grey,
          fillColor: Colors.transparent,
          strokeWidth: 1,
        ));
      }
    }
    return polygons;
  }

  /// 创建一个六边形
  static List<LatLng> _createHexagon(LatLng center, double radiusMeters) {
    List<LatLng> points = [];
    double latPerMeter = 1 / 111000.0;
    double lngPerMeter =
        1 / (111000.0 * cos(center.latitude * pi / 180));

    for (int i = 0; i < 6; i++) {
      double angle = pi / 3 * i;
      double dx = radiusMeters * cos(angle);
      double dy = radiusMeters * sin(angle);

      points.add(LatLng(
        center.latitude + dy * latPerMeter,
        center.longitude + dx * lngPerMeter,
      ));
    }
    return points;
  }
}
