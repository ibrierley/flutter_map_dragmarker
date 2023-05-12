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
  final WidgetBuilder builder;

  /// The widget of the marker while it gets dragged
  final WidgetBuilder? feedbackBuilder;

  /// The width of the marker widget
  final double width;

  /// The height of the marker widget
  final double height;

  /// The position offset of the marker
  final Offset offset;

  /// the offset while the marker gets dragged around
  final Offset? feedbackOffset;

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
  final bool updateMapNearEdge;

  /// This flag sets the sensitivity of when the map should starts to scroll.
  /// Requires [updateMapNearEdge] to be set to true.
  final double nearEdgeRatio;

  /// This flag sets the scroll speed of the map map when a marker get near to
  /// an edge. Requires [updateMapNearEdge] to be set to true.
  final double nearEdgeSpeed;

  /// This option keeps the marker upwards when rotating the map
  final bool rotateMarker;

  /// The anchor point of the marker, gets set by the anchorPos parameter
  final Anchor anchor;

  DragMarker({
    required this.point,
    this.key,
    required this.builder,
    this.feedbackBuilder,
    this.width = 30.0,
    this.height = 30.0,
    this.offset = const Offset(0, 0),
    this.feedbackOffset,
    this.useLongPress = false,
    this.onDragStart,
    this.onDragUpdate,
    this.onDragEnd,
    this.onLongDragStart,
    this.onLongDragUpdate,
    this.onLongDragEnd,
    this.onTap,
    this.onLongPress,
    this.updateMapNearEdge = false, // experimental
    this.nearEdgeRatio = 1.5,
    this.nearEdgeSpeed = 1.0,
    this.rotateMarker = true,
    AnchorPos? anchorPos,
  })  : anchor = Anchor.forPos(anchorPos, width, height);
}
