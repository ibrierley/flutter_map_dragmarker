import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import 'drag_marker.dart';
import 'drag_marker_widget.dart';

class DragMarkers extends StatelessWidget {
  final List<DragMarker> markers;

  const DragMarkers({super.key, this.markers = const []});

  @override
  Widget build(BuildContext context) {
    final mapController = MapController.maybeOf(context) ??
        (throw StateError(
            '`DragMarkers` is a map layer and should not be build outside '
            'a `FlutterMap` context.'));
    final mapCamera = MapCamera.maybeOf(context) ??
        (throw StateError(
            '`DragMarkers` is a map layer and should not be build outside '
            'a `FlutterMap` context.'));
    return Stack(
      children: markers
          .where((marker) => marker.inMapBounds(mapController.camera))
          .map((marker) => DragMarkerWidget(
                key: marker.key,
                marker: marker,
                mapCamera: mapCamera,
                mapController: mapController,
              ))
          .toList(growable: false),
    );
  }
}
