import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import 'drag_marker.dart';
import 'drag_marker_widget.dart';

class DragMarkers extends StatelessWidget {
  const DragMarkers({
    super.key,
    this.markers = const [],
    this.alignment = Alignment.center,
  });

  /// The markers that are to be displayed on the map.
  final List<DragMarker> markers;

  /// Alignment of each marker relative to its normal center at [DragMarker.point].
  ///
  /// For example, [Alignment.topCenter] will mean the entire marker widget is
  /// located above the [DragMarker.point].
  ///
  /// The center of rotation (anchor) will be opposite this.
  ///
  /// Defaults to [Alignment.center]. Overriden by [DragMarker.alignment] if set.
  final Alignment alignment;

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
          .where(
            (marker) => marker.inMapBounds(
              mapCamera: mapController.camera,
              markerWidgetAlignment: alignment,
            ),
          )
          .map((marker) => DragMarkerWidget(
                key: marker.key,
                marker: marker,
                mapCamera: mapCamera,
                mapController: mapController,
                alignment: alignment,
              ))
          .toList(growable: false),
    );
  }
}
