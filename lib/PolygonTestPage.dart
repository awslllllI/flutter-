import 'package:flutter/material.dart';
import 'package:amap_flutter_base/amap_flutter_base.dart';
import 'package:amap_flutter_map/amap_flutter_map.dart';

class PolygonTestPage extends StatefulWidget {
  const PolygonTestPage({super.key});

  @override
  State<PolygonTestPage> createState() => _PolygonTestPageState();
}

class _PolygonTestPageState extends State<PolygonTestPage> {
  final LatLng center = const LatLng(39.909187, 116.397451); // 天安门坐标

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("高德地图多边形测试")),
      body: AMapWidget(
        apiKey: const AMapApiKey(
          androidKey: '16acad5f262a393e01a9856b1d6ca7f8',
        ),
        initialCameraPosition: CameraPosition(
          target: center,
          zoom: 14,
        ),
        polygons: <Polygon>{
          Polygon(
            points: [
              const LatLng(39.915, 116.404),
              const LatLng(39.920, 116.414),
              const LatLng(39.910, 116.424),
              const LatLng(39.905, 116.414),
            ],
            strokeColor: Colors.red,
            strokeWidth: 3,
            fillColor: Colors.red.withOpacity(0.3),
          ),
        },
      ),
    );
  }
}
