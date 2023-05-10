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
          .where((marker) => _boundsContainsMarker(mapState, marker))
          .map((marker) => DragMarkerWidget(
        key: marker.key,
        mapState: mapState,
        marker: marker,
      ))
          .toList(growable: false),
    );
  }

  static bool _boundsContainsMarker(FlutterMapState map, DragMarker marker) {
    var pxPoint = map.project(marker.point);

    final rightPortion = marker.width - marker.anchor.left;
    final leftPortion = marker.anchor.left;
    final bottomPortion = marker.height - marker.anchor.top;
    final topPortion = marker.anchor.top;

    final sw = CustomPoint<double>(
        pxPoint.x + leftPortion - 100, pxPoint.y - bottomPortion + 100);
    final ne = CustomPoint<double>(
        pxPoint.x - rightPortion + 100, pxPoint.y + topPortion - 100);

    return map.pixelBounds.containsPartialBounds(Bounds<double>(sw, ne));
  }
}
