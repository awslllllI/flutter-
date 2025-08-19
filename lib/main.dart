import 'dart:async';

import 'package:amap_flutter_base/amap_flutter_base.dart';
import 'package:amap_flutter_map/amap_flutter_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_application_2/FogOfWarPainter.dart';
import 'package:flutter_application_2/utils/randomPointNearby.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  AMapController? _mapController;
  Set<Marker> _markers = {};
  List<LatLng> _tracePoints = []; // 轨迹点
  Set<Polyline> _polylines = {}; // 轨迹线
  double _nearbyRadiusMeters = 10.0;
  bool _isSimulating = false;
  Timer? _simulationTimer;
  LatLng _currentCenter = const LatLng(39.909187, 116.397451);
  double _currentZoom = 14;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _mapController?.disponse();
    _simulationTimer?.cancel();
    super.dispose();
  }

  void _updateMarkerAt(LatLng position) {
    _markers = {
      Marker(
        position: position,
        draggable: false,
        infoWindow: const InfoWindow(title: "当前位置"),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ),
    };
  }

  Container _createButtonContainer() {
    return Container(
      padding: const EdgeInsets.all(8),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              ElevatedButton(
                onPressed: () {
                  _stopSimulation();
                  setState(() {
                    _tracePoints = [];
                    _polylines = {};
                    _markers = {};
                  });
                },
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(Colors.red),
                  foregroundColor: MaterialStateProperty.all(Colors.white),
                ),
                child: const Text('清除轨迹'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text("随机偏移半径：${_nearbyRadiusMeters.toStringAsFixed(1)} 米"),
          Slider(
            value: _nearbyRadiusMeters,
            min: 1,
            max: 1000,
            divisions: 99,
            label: "${_nearbyRadiusMeters.toStringAsFixed(1)} m",
            onChanged: (value) {
              setState(() {
                _nearbyRadiusMeters = value;
              });
            },
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _isSimulating ? _stopSimulation : _startSimulation,
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(Colors.green),
                  foregroundColor: MaterialStateProperty.all(Colors.white),
                ),
                child: Text(_isSimulating ? '停止模拟' : '开始模拟轨迹'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _startSimulation() {
    _stopSimulation();
    if (_tracePoints.isEmpty) {
      LatLng startPoint = const LatLng(39.909187, 116.397451);
      _tracePoints.add(startPoint);
      _updateMarkerAt(startPoint);
      _mapController?.moveCamera(CameraUpdate.newLatLng(startPoint));
    }

    _isSimulating = true;
    _simulationTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      LatLng lastPoint = _tracePoints.last;
      LatLng nextPoint = randomPointNearby(lastPoint, _nearbyRadiusMeters);
      _tracePoints.add(nextPoint);

      setState(() {
        _polylines = {
          Polyline(
            points: _tracePoints,
            color: Colors.red,
            width: 5,
          ),
        };
        _updateMarkerAt(nextPoint);
      });

      _mapController?.moveCamera(CameraUpdate.newLatLng(nextPoint));
    });
  }

  void _stopSimulation() {
    if (_isSimulating) {
      _simulationTimer?.cancel();
      _simulationTimer = null;
      _isSimulating = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> widgets = <Widget>[];
    widgets.add(_createButtonContainer());

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('高德地图轨迹模拟'),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Stack(
                    children: [
                      AMapWidget(
                        apiKey: const AMapApiKey(
                          androidKey: '16acad5f262a393e01a9856b1d6ca7f8',
                        ),
                        privacyStatement: const AMapPrivacyStatement(
                          hasContains: true,
                          hasShow: true,
                          hasAgree: true,
                        ),
                        onMapCreated: (controller) {
                          _mapController = controller;
                        },
                        markers: _markers,
                        polylines: _polylines,
                        gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                          Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
                        },
                        initialCameraPosition: const CameraPosition(
                          target: LatLng(39.909187, 116.397451),
                          zoom: 14,
                        ),
                        onCameraMove: (position) {
                          setState(() {
                            _currentCenter = position.target;
                            _currentZoom = position.zoom;
                          });
                        },
                      ),
                      IgnorePointer(
                        child: CustomPaint(
                          size: Size(constraints.maxWidth, constraints.maxHeight),
                          painter: FogOfWarPainter(
                            tracePoints: _tracePoints,
                            centerLatLng: _currentCenter,
                            zoom: _currentZoom,
                            screenSize: Size(constraints.maxWidth, constraints.maxHeight),
                          ),
                        ),
                      )
                    ],
                  );
                },
              ),
            ),
            ...widgets,
          ],
        ),
      ),
    );
  }
}
