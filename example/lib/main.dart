import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_dragmarker/flutter_map_dragmarker.dart';
import 'package:latlong2/latlong.dart';

void main() => runApp(const TestApp());

class TestApp extends StatefulWidget {
  const TestApp({super.key});

  @override
  TestAppState createState() => TestAppState();
}

class TestAppState extends State<TestApp> {
  late final List<DragMarker> _dragMarkers;

  @override
  void initState() {
    _dragMarkers = [
      // minimal marker example
      DragMarker(
        key: GlobalKey<DragMarkerWidgetState>(),
        point: const LatLng(45.535, -122.675),
        size: const Size.square(50),
        offset: const Offset(0, -20),
        builder: (_, __, ___) => const Icon(
          Icons.location_on,
          size: 50,
          color: Colors.blueGrey,
        ),
      ),
      // minimal not draggable marker example
      DragMarker(
        key: GlobalKey<DragMarkerWidgetState>(),
        point: const LatLng(45.735, -122.975),
        size: const Size.square(50),
        offset: const Offset(0, -20),
        disableDrag: true,
        builder: (_, __, ___) => const Icon(
          Icons.location_on_outlined,
          size: 50,
          color: Colors.blueGrey,
        ),
      ),

      // marker with drag feedback, map scrolls when near edge
      DragMarker(
        key: GlobalKey<DragMarkerWidgetState>(),
        point: const LatLng(45.2131, -122.6765),
        size: const Size.square(75),
        offset: const Offset(0, -20),
        dragOffset: const Offset(0, -35),
        builder: (_, __, isDragging) {
          if (isDragging) {
            return const Icon(
              Icons.edit_location,
              size: 75,
              color: Colors.blueGrey,
            );
          }
          return const Icon(
            Icons.location_on,
            size: 50,
            color: Colors.blueGrey,
          );
        },
        onDragStart: (details, point) => debugPrint("Start point $point"),
        onDragEnd: (details, point) => debugPrint("End point $point"),
        onTap: (point) => debugPrint("on tap"),
        onLongPress: (point) => debugPrint("on long press"),
        scrollMapNearEdge: true,
        scrollNearEdgeRatio: 2.0,
        scrollNearEdgeSpeed: 2.0,
      ),
      // marker with position information
      DragMarker(
        key: GlobalKey<DragMarkerWidgetState>(),
        point: const LatLng(45.4131, -122.9765),
        size: const Size(75, 50),
        builder: (_, pos, ___) {
          return Card(
            color: Colors.blueGrey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  pos.latitude.toStringAsFixed(3),
                  style: const TextStyle(color: Colors.white),
                ),
                Text(
                  pos.longitude.toStringAsFixed(3),
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          );
        },
      ),
    ];
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: FlutterMap(
            options: const MapOptions(
              initialCenter: LatLng(45.5231, -122.6765),
              initialZoom: 9,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              ),
              DragMarkers(
                markers: _dragMarkers,
                alignment: Alignment.topCenter,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
