import 'dart:ui';
import 'dart:math' as math;
import 'package:amap_flutter_base/amap_flutter_base.dart';

LatLng screenToLatLng(Offset screenOffset, LatLng centerLatLng, double zoom, Size screenSize) {
  double scale = (256 << zoom.toInt()).toDouble();

  double centerWorldX = (centerLatLng.longitude + 180) / 360 * scale;
  double sinCenterLat = math.sin(centerLatLng.latitude * math.pi / 180);
  double centerWorldY = (0.5 - math.log((1 + sinCenterLat) / (1 - sinCenterLat)) / (4 * math.pi)) * scale;

  double worldX = (screenOffset.dx - screenSize.width / 2) + centerWorldX;
  double worldY = (screenOffset.dy - screenSize.height / 2) + centerWorldY;

  double lon = (worldX / scale) * 360 - 180;
  double n = math.pi - 2 * math.pi * worldY / scale;
  double lat = 180 / math.pi * math.atan(0.5 * (math.exp(n) - math.exp(-n)));

  return LatLng(lat, lon);
}
