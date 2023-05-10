import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:latlong2/latlong.dart';

class DragMarker {
  LatLng point;
  final Key? key;
  final WidgetBuilder? builder;
  final WidgetBuilder? feedbackBuilder;
  final double width;
  final double height;
  final Offset offset;
  final Offset feedbackOffset;
  final bool useLongPress;
  final void Function(DragStartDetails, LatLng)? onDragStart;
  final void Function(DragUpdateDetails, LatLng)? onDragUpdate;
  final void Function(DragEndDetails, LatLng)? onDragEnd;
  final void Function(LongPressStartDetails, LatLng)? onLongDragStart;
  final void Function(LongPressMoveUpdateDetails, LatLng)? onLongDragUpdate;
  final void Function(LongPressEndDetails, LatLng)? onLongDragEnd;
  final void Function(LatLng)? onTap;
  final void Function(LatLng)? onLongPress;
  final bool updateMapNearEdge;
  final double nearEdgeRatio;
  final double nearEdgeSpeed;
  final bool rotateMarker;
  late Anchor anchor;

  DragMarker({
    required this.point,
    this.key,
    this.builder,
    this.feedbackBuilder,
    this.width = 30.0,
    this.height = 30.0,
    this.offset = const Offset(0, 0),
    this.feedbackOffset = const Offset(0, 0),
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
  }) {
    anchor = Anchor.forPos(anchorPos, width, height);
  }
}
