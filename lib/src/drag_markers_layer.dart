import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';

import 'drag_marker.dart';
import 'drag_marker_widget.dart';

class DragMarkers extends StatelessWidget {
  final List<DragMarker> markers;

  const DragMarkers({super.key, this.markers = const []});

  @override
  Widget build(BuildContext context) {
    final mapState = FlutterMapState.maybeOf(context) ??
        (throw StateError(
            '`DragMarkers` is a map layer and should not be build outside '
            'a `FlutterMap` context.'));
    return Stack(
      children: markers
          .where((marker) => marker.inMapBounds(mapState))
          .map((marker) => DragMarkerWidget(
                key: marker.key,
                mapState: mapState,
                marker: marker,
              ))
          .toList(growable: false),
    );
  }
}
