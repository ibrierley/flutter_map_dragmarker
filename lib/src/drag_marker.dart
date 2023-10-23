import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:latlong2/latlong.dart';

/// The data class has all information that is required for the DragMarkerWidget
class DragMarker {
  /// The initial coordinates of the marker
  LatLng point;

  /// A unique key for the marker
  final Key? key;

  /// The widget of the marker
  final DragMarkerWidgetBuilder builder;

  /// The height and width of the marker widget
  final Size size;

  /// The position offset of the marker
  final Offset offset;

  /// the offset while the marker gets dragged around
  final Offset? dragOffset;

  /// This flag requires a long press on the marker before it can get moved
  final bool useLongPress;

  /// This callback gets called when the DragMarker starts to get dragged
  final void Function(DragStartDetails details, LatLng latLng)? onDragStart;

  /// This callback gets called when the DragMarker gets dragged around
  final void Function(DragUpdateDetails details, LatLng latLng)? onDragUpdate;

  /// This callback gets called when the DragMarker stopps to get dragged
  final void Function(DragEndDetails details, LatLng latLng)? onDragEnd;

  /// This callback gets called when the DragMarker starts to get dragged with
  /// the [useLongPress] option enabled
  final void Function(LongPressStartDetails details, LatLng latLng)?
      onLongDragStart;

  /// This callback gets called when the DragMarker gets dragged with
  /// the [useLongPress] option enabled
  final void Function(LongPressMoveUpdateDetails details, LatLng latLng)?
      onLongDragUpdate;

  /// This callback gets called when the DragMarker stopps to get dragged with
  /// the [useLongPress] option enabled
  final void Function(LongPressEndDetails details, LatLng latLng)?
      onLongDragEnd;

  /// This callback gets called when the DragMarkerWidget gets tapped
  final void Function(LatLng latLng)? onTap;

  /// This callback gets called when the DragMarkerWiidget gets long pressed
  final void Function(LatLng latLng)? onLongPress;

  /// EXPERIMENTAL, When this flag is enabled the map scrolls around when
  /// dragging a marker near an edge
  final bool scrollMapNearEdge;

  /// This flag sets the sensitivity of when the map should starts to scroll.
  /// Requires [scrollMapNearEdge] to be set to true.
  final double scrollNearEdgeRatio;

  /// This flag sets the scroll speed of the map map when a marker get near to
  /// an edge. Requires [scrollMapNearEdge] to be set to true.
  final double scrollNearEdgeSpeed;

  /// This option keeps the marker upwards when rotating the map
  final bool rotateMarker;

  /// The anchor point of the marker, gets set by the anchorPos parameter
  // final Anchor anchor;
  /// Anchors are deprecated, use `Alignment` instead.
  final Alignment? alignment;

  DragMarker({
    required this.point,
    this.key,
    required this.builder,
    required this.size,
    this.offset = const Offset(0, 0),
    this.dragOffset,
    this.useLongPress = false,
    this.onDragStart,
    this.onDragUpdate,
    this.onDragEnd,
    this.onLongDragStart,
    this.onLongDragUpdate,
    this.onLongDragEnd,
    this.onTap,
    this.onLongPress,
    this.scrollMapNearEdge = false,
    this.scrollNearEdgeRatio = 1.5,
    this.scrollNearEdgeSpeed = 1.0,
    this.rotateMarker = true,
    this.alignment
  });

  bool inMapBounds(MapCamera mapCamera) {
    var pxPoint = mapCamera.project(point);

    // final rightPortion = size.width - anchor.left;
    // final leftPortion = anchor.left;
    // final bottomPortion = size.height - anchor.top;
    // final topPortion = anchor.top;
    final rightPortion = size.width - (alignment ?? Alignment.centerLeft).x;
    final leftPortion = (alignment ?? Alignment.centerLeft).x;
    final bottomPortion = size.height - (alignment ?? Alignment.topCenter).y;
    final topPortion = (alignment ?? Alignment.topCenter).y;

    final sw = Point<double>(
      pxPoint.x + leftPortion - 100,
      pxPoint.y - bottomPortion + 100,
    );
    final ne = Point<double>(
      pxPoint.x - rightPortion + 100,
      pxPoint.y + topPortion - 100,
    );

    return mapCamera.pixelBounds.containsPartialBounds(Bounds<double>(sw, ne));
  }
}

typedef DragMarkerWidgetBuilder = Widget Function(
  BuildContext context,
  LatLng pos,
  bool isDragging,
);
