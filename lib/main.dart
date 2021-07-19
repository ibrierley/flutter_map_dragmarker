import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/plugin_api.dart';
import 'dragmarker.dart';

void main() {
  runApp(TestApp());
}

class TestApp extends StatefulWidget {
  @override
  _TestAppState createState() => _TestAppState();
}

class _TestAppState extends State<TestApp> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Container(
            child: FlutterMap(
              options: MapOptions(
                plugins: [
                  DragMarkerPlugin(),
                ],
                center: LatLng(45.5231, -122.6765),
                zoom: 6.4,
              ),
              layers: [
                TileLayerOptions(
                    urlTemplate:
                        'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                    subdomains: ['a', 'b', 'c']),
                DragMarkerPluginOptions(
                  markers: [
                    DragMarker(
                      point: LatLng(45.2131, -122.6765),
                      width: 80.0,
                      height: 80.0,
                      offset: Offset(0.0, -8.0),
                      builder: (ctx) =>
                          Container(child: Icon(Icons.location_on, size: 50)),
                      onDragStart: (details, point) =>
                          print("Start point $point"),
                      onDragEnd: (details, point) => print("End point $point"),
                      onDragUpdate: (details, point) {},
                      onTap: (point) {
                        print("on tap");
                      },
                      onLongPress: (point) {
                        print("on long press");
                      },
                      feedbackBuilder: (ctx) =>
                          Container(child: Icon(Icons.edit_location, size: 75)),
                      feedbackOffset: Offset(0.0, -18.0),
                      updateMapNearEdge: true,
                      nearEdgeRatio: 2.0,
                      nearEdgeSpeed: 1.0,
                    ),
                    DragMarker(
                      point: LatLng(45.535, -122.675),
                      width: 80.0,
                      height: 80.0,
                      builder: (ctx) =>
                          Container(child: Icon(Icons.location_on, size: 50)),
                      onDragEnd: (details, point) {
                        print('Finished Drag $details $point');
                      },
                      updateMapNearEdge: false,
                    )
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
